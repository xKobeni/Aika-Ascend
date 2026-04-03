import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../models/user_model.dart';
import '../models/quest_model.dart';
import '../services/quest_service.dart';
import '../services/storage_service.dart';
import '../services/behavior_service.dart';
import '../services/system_service.dart';
import '../services/content_service.dart';
import '../widgets/exp_bar.dart';
import '../widgets/quest_card.dart';
import '../widgets/system_panel.dart';
import '../widgets/progress_ring.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/title_badge.dart';
import '../widgets/level_up_overlay.dart';
import '../widgets/animated_background.dart';
import '../widgets/activity_tracker_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final QuestService _questService = QuestService();
  final StorageService _storage = StorageService();
  final BehaviorService _behavior = BehaviorService();
  final ContentService _content = ContentService.instance;

  late UserModel _user;
  List<QuestModel> _quests = [];
  bool _loading = true;
  String _activeEvent = '';

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    setState(() => _loading = true);
    _user = _storage.getUser();
    final result = await _questService.runDailyCheck();

    if (!mounted) return;
    setState(() {
      _user = _storage.getUser();
      _quests = result.quests;
      _activeEvent = result.randomEvent;
      _loading = false;
    });

    if (result.isNewDay) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await SystemService.newDay(context);
        if (!mounted) return;
        if (result.hadPunishment) await SystemService.punishmentAssigned(context);
        if (!mounted) return;
        if (result.hadBoss) await SystemService.bossAppeared(context);
        if (!mounted) return;
        if (result.randomEvent.isNotEmpty) {
          await SystemService.randomEvent(context, result.randomEvent);
        }
        if (!mounted) return;
        if (result.leveledUp) await LevelUpOverlay.show(context, _user);
        if (!mounted) return;
        for (final id in result.newlyUnlocked) {
          await SystemService.achievementUnlocked(context, id);
          if (!mounted) return;
        }
      });
    }
  }

  Future<void> _handleComplete(int index) async {
    final result = await _questService.completeQuest(index);

    setState(() {
      _user = _storage.getUser();
      _quests = _storage.getQuests();
    });

    if (!mounted) return;
    if (result.allCompleted) {
      await SystemService.allQuestsCompleted(context);
    } else {
      await SystemService.questCompleted(context, _quests[index].expReward);
    }

    if (!mounted) return;
    if (result.leveledUp) await LevelUpOverlay.show(context, _user);

    if (!mounted) return;
    for (final id in result.newlyUnlocked) {
      await SystemService.achievementUnlocked(context, id);
      if (!mounted) return;
    }

    setState(() => _user = _storage.getUser());
  }

  int get _done => _quests.where((q) => q.completed).length;
  double get _progress => _quests.isEmpty ? 0 : _done / _quests.length;
  bool get _allDone => _quests.isNotEmpty && _quests.every((q) => q.completed);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: AppColors.violet, strokeWidth: 1.5),
              const SizedBox(height: 16),
              Text('INITIALIZING...', style: GoogleFonts.shareTechMono(
                color: AppColors.cyan, fontSize: 11, letterSpacing: 3,
              )),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBackground(
        child: RefreshIndicator(
          color: AppColors.violet,
          backgroundColor: AppColors.surface,
          displacement: 60,
          onRefresh: _initApp,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const CountdownWidget(),
                    const SizedBox(height: 16),
                    _buildHeroSection(),
                    const SizedBox(height: 16),
                    const ActivityTrackerPanel(),
                    const SizedBox(height: 16),
                    _buildBehaviorPanel(),
                    if (_activeEvent.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildEventBanner(),
                    ],
                    const SizedBox(height: 16),
                    SystemPanel(
                      title: 'Hunter Status',
                      borderColor: AppColors.violet.withValues(alpha: 0.5),
                      icon: Icons.bar_chart_rounded,
                      child: ExpBar(user: _user),
                    ),
                    const SizedBox(height: 16),
                    _buildQuestPanel(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      floating: true,
      snap: true,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.violet, width: 1.5),
              borderRadius: BorderRadius.circular(4),
              color: AppColors.violet.withValues(alpha: 0.1),
              boxShadow: [BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.3), blurRadius: 10,
              )],
            ),
            child: const Icon(Icons.bolt_rounded, color: AppColors.violet, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('AIKA ASCEND', style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary, fontSize: 16,
                fontWeight: FontWeight.bold, letterSpacing: 3,
              )),
              Text('v2.0 PROTOCOL', style: GoogleFonts.shareTechMono(
                color: AppColors.textMuted, fontSize: 8, letterSpacing: 2,
              )),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.emerald, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppColors.emerald, blurRadius: 6)],
                ),
              ),
              const SizedBox(width: 5),
              Text('ONLINE', style: GoogleFonts.shareTechMono(
                color: AppColors.emerald, fontSize: 9, letterSpacing: 2,
              )),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.cardBorder),
      ),
    );
  }

  Widget _buildHeroSection() {
    final skillPaths = _content.skillPaths;
    final path = skillPaths[_user.skillPath.clamp(0, skillPaths.length - 1)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          // Progress ring
          ProgressRing(
            progress: _progress,
            size: 110,
            color: _allDone ? AppColors.emerald : AppColors.violet,
            centerLabel: '${(_progress * 100).toInt()}%',
            bottomLabel: '$_done/${_quests.length}',
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user.hunterName.isEmpty ? 'HUNTER' : _user.hunterName.toUpperCase(),
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textMuted, fontSize: 11, letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.rankLabel(_user.level),
                  style: GoogleFonts.rajdhani(
                    color: AppColors.textPrimary, fontSize: 20,
                    fontWeight: FontWeight.bold, height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                TitleBadge(titleId: _user.titleId, level: _user.level),
                const SizedBox(height: 10),
                // Skill path indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.violet.withValues(alpha: 0.12),
                        border: Border.all(color: AppColors.violet.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        path['badge'] as String,
                        style: GoogleFonts.rajdhani(
                          color: AppColors.violet,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${path['name']} Path',
                      style: GoogleFonts.shareTechMono(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBehaviorPanel() {
    final msg = _behavior.generateMessage(_user);
    return SystemPanel(
      title: 'System Intelligence',
      borderColor: AppColors.cardBorder,
      icon: Icons.terminal_rounded,
      child: Text(
        msg,
        style: GoogleFonts.shareTechMono(
          color: AppColors.cyan.withValues(alpha: 0.85),
          fontSize: 11,
          height: 1.7,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildEventBanner() {
    Color color;
    String label;
    String message;
    IconData icon;
    switch (_activeEvent) {
      case 'double_exp':
        color = AppColors.emerald;
        label = 'DOUBLE EXP EVENT';
        message = 'All EXP earned today is doubled. Push harder.';
        icon = Icons.electric_bolt;
        break;
      case 'malfunction':
        color = AppColors.crimson;
        label = 'SYSTEM MALFUNCTION';
        message = 'Anomaly detected. One quest difficulty increased.';
        icon = Icons.warning_amber_rounded;
        break;
      default:
        color = AppColors.gold;
        label = 'BONUS QUEST ACTIVE';
        message = 'Extra mission detected. Additional rewards await.';
        icon = Icons.star_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.rajdhani(
                  color: color, fontSize: 12,
                  fontWeight: FontWeight.bold, letterSpacing: 2,
                )),
                Text(message, style: GoogleFonts.shareTechMono(
                  color: AppColors.textMuted, fontSize: 10, height: 1.5,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestPanel() {
    final dailySystem = _content.dailyMissionSystem;
    final title = (dailySystem['title'] as String?) ?? 'Daily Missions';
    final subtitle = (dailySystem['subtitle'] as String?) ?? 'Complete all missions before midnight.';
    final failure = (dailySystem['failure'] as String?) ?? 'Failure will trigger a penalty quest.';

    return SystemPanel(
      title: title,
      borderColor: AppColors.cyan.withValues(alpha: 0.4),
      icon: Icons.assignment_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: GoogleFonts.shareTechMono(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            failure,
            style: GoogleFonts.shareTechMono(
              color: AppColors.crimson.withValues(alpha: 0.9),
              fontSize: 9,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          _quests.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('NO ACTIVE MISSIONS', style: GoogleFonts.shareTechMono(
                      color: AppColors.textMuted, fontSize: 12, letterSpacing: 2,
                    )),
                  ),
                )
              : Column(
                  children: List.generate(
                    _quests.length,
                    (i) => QuestCard(
                      quest: _quests[i],
                      index: i,
                      onComplete: () => _handleComplete(i),
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
