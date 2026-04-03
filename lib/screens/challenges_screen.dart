import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../core/app_colors.dart';
import '../models/user_model.dart';
import '../widgets/animated_background.dart';
import '../services/content_service.dart';
import '../services/achievement_service.dart';
import '../services/storage_service.dart';
import '../services/system_service.dart';
import '../services/title_service.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  final ContentService _content = ContentService.instance;
  final StorageService _storage = StorageService();
  final AchievementService _achievementService = AchievementService();
  final TitleService _titleService = TitleService();
  final ImagePicker _picker = ImagePicker();

  late final TabController _tabs;
  final Map<String, int> _exerciseSetProgress = {};

  Map<String, dynamic> _transformation = {};
  List<Map<String, dynamic>> _checkins = [];
  Map<String, dynamic> _bossRaid = {};

  int _selectedWorkoutIndex = 0;
  final TextEditingController _weightCtrl = TextEditingController();
  final TextEditingController _noteCtrl = TextEditingController();
  String _checkinImagePath = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadChallengeData();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _weightCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _loadChallengeData() {
    setState(() {
      _transformation = _storage.getTransformation();
      _checkins = _storage.getChallengeCheckins();
      _bossRaid = _storage.getBossRaidState();
    });
  }

  Future<void> _pickImageForCheckin() async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() => _checkinImagePath = image.path);
  }

  Future<void> _setBeforeData() async {
    final weight = double.tryParse(_weightCtrl.text.trim());
    if (weight == null || _checkinImagePath.isEmpty) {
      _toast('Enter weight and select a photo for BEFORE state.');
      return;
    }

    final next = Map<String, dynamic>.from(_transformation)
      ..['beforeWeight'] = weight
      ..['beforeImagePath'] = _checkinImagePath
      ..['startDate'] = DateTime.now().toIso8601String().substring(0, 10);

    await _storage.saveTransformation(next);
    _loadChallengeData();
    _toast('Before profile saved.');
  }

  Future<void> _setAfterData() async {
    final weight = double.tryParse(_weightCtrl.text.trim());
    if (weight == null || _checkinImagePath.isEmpty) {
      _toast('Enter weight and select a photo for AFTER state.');
      return;
    }

    final next = Map<String, dynamic>.from(_transformation)
      ..['afterWeight'] = weight
      ..['afterImagePath'] = _checkinImagePath
      ..['endDate'] = DateTime.now().toIso8601String().substring(0, 10);

    await _storage.saveTransformation(next);
    _loadChallengeData();
    _toast('After profile saved.');
  }

  Future<void> _submitCheckin() async {
    final weight = double.tryParse(_weightCtrl.text.trim());
    if (weight == null || _checkinImagePath.isEmpty) {
      _toast('Check-in requires both current weight and photo.');
      return;
    }

    await _storage.addChallengeCheckin({
      'date': DateTime.now().toIso8601String().substring(0, 10),
      'weight': weight,
      'note': _noteCtrl.text.trim(),
      'imagePath': _checkinImagePath,
    });

    _weightCtrl.clear();
    _noteCtrl.clear();
    setState(() => _checkinImagePath = '');
    _loadChallengeData();
    _toast('Daily check-in submitted.');
  }

  Future<void> _completeSet(String key, int maxSets) async {
    final current = _exerciseSetProgress[key] ?? 0;
    final next = (current + 1).clamp(0, maxSets);
    setState(() => _exerciseSetProgress[key] = next);

    if (_bossRaid['active'] == true && _bossRaid['completed'] != true) {
      final raid = Map<String, dynamic>.from(_bossRaid);
      final target = (raid['target'] as num?)?.toInt() ?? 0;
      final progress = ((raid['progress'] as num?)?.toInt() ?? 0) + 1;
      raid['progress'] = progress;

      if (target > 0 && progress >= target) {
        await _claimBossRaidVictory(raid);
      } else {
        await _storage.saveBossRaidState(raid);
        if (mounted) {
          setState(() => _bossRaid = raid);
        }
      }
    }
  }

  Future<void> _startBossRaid(Map<String, dynamic> boss, int index) async {
    if (_bossRaid['active'] == true && _bossRaid['completed'] != true) {
      _toast('Finish the active boss raid first.');
      return;
    }

    final raid = {
      'active': true,
      'bossIndex': index,
      'bossTitle': boss['title'] as String,
      'bossDesc': boss['desc'] as String,
      'target': (boss['target'] as num?)?.toInt() ?? 0,
      'progress': 0,
      'expReward': (boss['exp'] as num?)?.toInt() ?? 0,
      'completed': false,
      'startedDate': DateTime.now().toIso8601String(),
      'completedDate': '',
    };

    await _storage.saveBossRaidState(raid);
    if (!mounted) return;
    setState(() => _bossRaid = raid);
    _toast('Boss raid started. Damage the boss by completing workout sets.');
  }

  Future<void> _claimBossRaidVictory(Map<String, dynamic> raid) async {
    final user = _storage.getUser();
    final reward = (raid['expReward'] as num?)?.toInt() ?? 0;
    final now = DateTime.now();

    user.exp += reward;
    user.totalExpEarned += reward;
    user.totalQuestsCompleted++;
    user.bossDefeatsTotal++;
    user.bossDefeatedThisWeek = true;
    user.lastBossWeekYear = now.year;
    user.lastBossWeekNum = _isoWeek(now);

    var leveledUp = false;
    while (user.exp >= user.level * 100) {
      user.exp -= user.level * 100;
      user.level++;
      leveledUp = true;
    }

    user.titleId = _titleService.evaluateTitle(user);
    await _storage.saveUser(user);
    await _achievementService.checkAll(user);

    final completedRaid = Map<String, dynamic>.from(raid)
      ..['active'] = false
      ..['completed'] = true
      ..['progress'] = raid['target']
      ..['completedDate'] = now.toIso8601String();

    await _storage.saveBossRaidState(completedRaid);
    if (!mounted) return;

    setState(() {
      _bossRaid = completedRaid;
    });

    await SystemService.show(
      context,
      type: SystemMessageType.success,
      title: '[ BOSS RAID CLEARED ]',
      message: raid['bossTitle'] as String,
      subMessage: '+$reward EXP awarded.${leveledUp ? ' Level up detected.' : ''}',
    );

    _toast('Boss raid cleared. Rewards claimed.');
  }

  void _resetWorkoutProgress() {
    setState(_exerciseSetProgress.clear);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.surface,
        content: Text(msg, style: GoogleFonts.shareTechMono(color: AppColors.textPrimary)),
      ),
    );
  }

  int _isoWeek(DateTime date) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    return ((dayOfYear - date.weekday + 10) / 7).floor();
  }

  @override
  Widget build(BuildContext context) {
    final workouts = _content.interactiveWorkouts;
    final bosses = _content.bossChallenges;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'CHALLENGES',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TabBar(
                controller: _tabs,
                indicatorColor: AppColors.violet,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: GoogleFonts.rajdhani(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
                tabs: const [
                  Tab(text: 'WORKOUTS'),
                  Tab(text: '30-DAY'),
                  Tab(text: 'BOSS'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _buildWorkoutTab(workouts),
                    _buildTransformationTab(),
                    _buildBossTab(bosses),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutTab(List<Map<String, dynamic>> workouts) {
    if (workouts.isEmpty) {
      return Center(
        child: Text(
          'No workouts configured in JSON.',
          style: GoogleFonts.shareTechMono(color: AppColors.textMuted),
        ),
      );
    }

    final workout = workouts[_selectedWorkoutIndex.clamp(0, workouts.length - 1)];
    final exercises = List<Map<String, dynamic>>.from(workout['exercises'] as List);

    final totalSets = exercises.fold<int>(0, (sum, e) => sum + (e['sets'] as int));
    final doneSets = exercises.asMap().entries.fold<int>(0, (sum, entry) {
      final key = '${workout['id']}_${entry.key}';
      return sum + (_exerciseSetProgress[key] ?? 0);
    });
    final progress = totalSets == 0 ? 0.0 : doneSets / totalSets;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SizedBox(
          height: 126,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: workouts.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final item = workouts[i];
              final active = i == _selectedWorkoutIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedWorkoutIndex = i),
                child: Container(
                  width: 230,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: active ? AppColors.violet.withValues(alpha: 0.10) : AppColors.surface,
                    border: Border.all(
                      color: active ? AppColors.violet : AppColors.cardBorder,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${item['duration_minutes']} MIN • ${item['focus']}',
                        style: GoogleFonts.shareTechMono(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SESSION PROGRESS  ${(progress * 100).toInt()}%',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  letterSpacing: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.cardBorder,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emerald),
              ),
              const SizedBox(height: 8),
              Text(
                '$doneSets / $totalSets sets completed',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...exercises.asMap().entries.map((entry) {
          final i = entry.key;
          final ex = entry.value;
          final key = '${workout['id']}_$i';
          final done = _exerciseSetProgress[key] ?? 0;
          final maxSets = ex['sets'] as int;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex['name'] as String,
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Target: ${ex['target_muscles']}',
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sets: $maxSets   Reps: ${ex['reps']}   Rest: ${ex['rest_seconds']}s',
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: maxSets == 0 ? 0 : done / maxSets,
                        minHeight: 5,
                        backgroundColor: AppColors.cardBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$done/$maxSets',
                      style: GoogleFonts.shareTechMono(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: done >= maxSets ? null : () => _completeSet(key, maxSets),
                      child: const Text('SET DONE'),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _resetWorkoutProgress,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.cardBorder),
            foregroundColor: AppColors.textMuted,
          ),
          child: const Text('RESET SESSION PROGRESS'),
        ),
      ],
    );
  }

  Widget _buildTransformationTab() {
    final config = _content.transformationChallenge;
    final prompts = _content.dailyChallengePrompts;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          config['title'] as String,
          style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          config['desc'] as String,
          style: GoogleFonts.shareTechMono(
            color: AppColors.textMuted,
            fontSize: 11,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daily Focus',
                style: GoogleFonts.rajdhani(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              ...prompts.take(3).map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $p',
                    style: GoogleFonts.shareTechMono(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _weightCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.shareTechMono(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Current Weight',
            hintText: 'e.g. 72.5',
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _noteCtrl,
          style: GoogleFonts.shareTechMono(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            labelText: 'Daily Note',
            hintText: 'How did training feel today?',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _pickImageForCheckin,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('SELECT PHOTO'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _checkinImagePath.isEmpty ? 'No image selected' : 'Image ready',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        if (_checkinImagePath.isNotEmpty) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_checkinImagePath),
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton(onPressed: _setBeforeData, child: const Text('SAVE BEFORE')),
            ElevatedButton(onPressed: _submitCheckin, child: const Text('SUBMIT CHECK-IN')),
            ElevatedButton(onPressed: _setAfterData, child: const Text('SAVE AFTER')),
          ],
        ),
        const SizedBox(height: 16),
        _beforeAfterCard(),
        const SizedBox(height: 12),
        Text(
          'Check-ins (${_checkins.length})',
          style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ..._checkins.reversed.take(10).map((log) {
          final imagePath = (log['imagePath'] ?? '') as String;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                if (imagePath.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(
                      File(imagePath),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${log['date']}  •  ${log['weight']} kg',
                        style: GoogleFonts.shareTechMono(
                          color: AppColors.textPrimary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (log['note'] ?? '').toString().isEmpty
                            ? 'No note'
                            : log['note'] as String,
                        style: GoogleFonts.shareTechMono(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _beforeAfterCard() {
    final beforeWeight = _transformation['beforeWeight'];
    final afterWeight = _transformation['afterWeight'];
    final beforeImage = (_transformation['beforeImagePath'] ?? '') as String;
    final afterImage = (_transformation['afterImagePath'] ?? '') as String;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Before / After',
            style: GoogleFonts.rajdhani(
              color: AppColors.violet,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _progressTile(
                  'BEFORE',
                  beforeWeight,
                  beforeImage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _progressTile(
                  'AFTER',
                  afterWeight,
                  afterImage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _progressTile(String label, dynamic weight, String imagePath) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.shareTechMono(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          if (imagePath.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.file(
                File(imagePath),
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.photo_outlined, color: AppColors.textMuted),
            ),
          const SizedBox(height: 8),
          Text(
            weight == null ? 'Weight: --' : 'Weight: $weight kg',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textPrimary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBossTab(List<Map<String, dynamic>> bosses) {
    final activeRaid = _bossRaid['active'] == true ? Map<String, dynamic>.from(_bossRaid) : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeRaid != null) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_fire_department, color: AppColors.gold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        activeRaid['bossTitle'] as String,
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _infoPill('ACTIVE', AppColors.gold),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  activeRaid['bossDesc'] as String,
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: ((activeRaid['progress'] as num?)?.toDouble() ?? 0) /
                      ((activeRaid['target'] as num?)?.toDouble() ?? 1),
                  minHeight: 6,
                  backgroundColor: AppColors.cardBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${activeRaid['progress']}/${activeRaid['target']} raid hits landed',
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete workout sets in the WORKOUTS tab to damage the boss.',
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
        ...bosses.map((boss) {
          final map = Map<String, dynamic>.from(boss);
          final bossIndex = bosses.indexOf(boss);
          final isActive = activeRaid != null && (activeRaid['bossIndex'] as num?)?.toInt() == bossIndex;
          final isCompleted = activeRaid != null && activeRaid['completed'] == true && isActive;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? AppColors.gold.withValues(alpha: 0.08) : AppColors.cardBg,
              border: Border.all(
                color: isCompleted
                    ? AppColors.emerald.withValues(alpha: 0.75)
                    : isActive
                        ? AppColors.gold.withValues(alpha: 0.9)
                        : AppColors.gold.withValues(alpha: 0.55),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_rounded, color: AppColors.gold, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        map['title'] as String,
                        style: GoogleFonts.rajdhani(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      map['difficulty'] as String,
                      style: GoogleFonts.shareTechMono(
                        color: AppColors.gold,
                        fontSize: 9,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  map['desc'] as String,
                  style: GoogleFonts.shareTechMono(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: [
                    _infoPill('TARGET ${map['target']}', AppColors.cyan),
                    _infoPill('+${map['exp']} EXP', AppColors.emerald),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isCompleted
                            ? null
                            : () => _startBossRaid(map, bossIndex),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isActive ? AppColors.gold : AppColors.cardBorder,
                          ),
                          foregroundColor: isActive ? AppColors.gold : AppColors.textPrimary,
                        ),
                        child: Text(
                          isCompleted
                              ? 'DEFEATED'
                              : isActive
                                  ? 'RAID ACTIVE'
                                  : 'START RAID',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _infoPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: GoogleFonts.shareTechMono(
          color: color,
          fontSize: 10,
          letterSpacing: 1,
        ),
      ),
    );
  }
}