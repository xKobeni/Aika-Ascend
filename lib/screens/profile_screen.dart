import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../services/storage_service.dart';
import '../services/content_service.dart';
import '../widgets/progress_ring.dart';
import '../widgets/title_badge.dart';
import '../widgets/animated_background.dart';
import 'onboarding_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final StorageService _storage = StorageService();
  final ContentService _content = ContentService.instance;

  Future<void> _changePath(int newPath) async {
    final user = _storage.getUser();
    final settings = _storage.getAppSettings();
    final shouldConfirm = (settings['confirmPathSwitch'] as bool?) ?? true;
    if (user.skillPath == newPath) return;

    final cost = AppConstants.skillPathChangePenalty;
    if (user.exp < cost) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: AppColors.crimson.withValues(alpha: 0.9),
        content: Text(
          'Insufficient EXP. Requires $cost EXP to change path.',
          style: GoogleFonts.shareTechMono(fontSize: 11),
        ),
      ));
      return;
    }

    final confirm = shouldConfirm
        ? await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: const BorderSide(color: AppColors.violet),
              ),
              title: Text('CHANGE PATH', style: GoogleFonts.rajdhani(
                color: AppColors.violet, fontSize: 18,
                fontWeight: FontWeight.bold, letterSpacing: 2,
              )),
              content: Text(
                'Switching paths costs $cost EXP.\n\nContinue?',
                style: GoogleFonts.shareTechMono(color: AppColors.textMuted, fontSize: 11),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('CANCEL', style: GoogleFonts.rajdhani(
                    color: AppColors.textMuted, letterSpacing: 1.5,
                  )),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text('CONFIRM', style: GoogleFonts.rajdhani(
                    color: AppColors.violet, letterSpacing: 1.5,
                  )),
                ),
              ],
            ),
          )
        : true;

    if (confirm != true) return;

    user.exp -= cost;
    user.skillPath = newPath;
    await _storage.saveUser(user);
    setState(() {});
  }

  Future<void> _resetProgress() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.crimson),
        ),
        title: Text('SYSTEM RESET', style: GoogleFonts.rajdhani(
          color: AppColors.crimson, fontSize: 18,
          fontWeight: FontWeight.bold, letterSpacing: 2,
        )),
        content: Text(
          'This will erase ALL progress permanently.\n\nLevel, EXP, quests, achievements — everything.\n\nThis cannot be undone.',
          style: GoogleFonts.shareTechMono(
            color: AppColors.textMuted, fontSize: 11, height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: GoogleFonts.rajdhani(
              color: AppColors.textMuted, letterSpacing: 1.5,
            )),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('RESET', style: GoogleFonts.rajdhani(
              color: AppColors.crimson, letterSpacing: 1.5,
            )),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await Hive.close();
    // Re-init everything
    await StorageService().init();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _storage.getUser();
    final needed = AppConstants.expToLevelUp(user.level);
    final fill = needed == 0 ? 1.0 : (user.exp / needed).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('PROFILE', style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary, fontSize: 28,
                fontWeight: FontWeight.bold, letterSpacing: 3,
              )),
              Text('Hunter identification', style: GoogleFonts.shareTechMono(
                color: AppColors.textMuted, fontSize: 10, letterSpacing: 1,
              )),
              const SizedBox(height: 20),

              // ── Identity card ────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.violet.withValues(alpha: 0.15),
                      AppColors.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.violet.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    ProgressRing(
                      progress: fill,
                      size: 80,
                      color: AppColors.violet,
                      centerLabel: 'LV\n${user.level}',
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.hunterName.isEmpty ? 'HUNTER' : user.hunterName.toUpperCase(),
                            style: GoogleFonts.rajdhani(
                              color: AppColors.textPrimary, fontSize: 22,
                              fontWeight: FontWeight.bold, letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppConstants.rankLabel(user.level),
                            style: GoogleFonts.shareTechMono(
                              color: AppColors.textMuted, fontSize: 10, letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TitleBadge(titleId: user.titleId, level: user.level),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Skill Path ──────────────────────────────────────────────
              _sectionLabel('SKILL PATH'),
              const SizedBox(height: 10),
              ...List.generate(_content.skillPaths.length, (i) {
                final path = _content.skillPaths[i];
                final isActive = user.skillPath == i;
                final color = i == 0
                    ? AppColors.strengthColor
                    : i == 1 ? AppColors.enduranceColor : AppColors.disciplineColor;

                return GestureDetector(
                  onTap: () => _changePath(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color.withValues(alpha: 0.12)
                          : AppColors.surface,
                      border: Border.all(
                        color: isActive ? color : AppColors.cardBorder,
                        width: isActive ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            border: Border.all(color: color.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            path['badge'] as String,
                            style: GoogleFonts.rajdhani(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (path['name'] as String).toUpperCase(),
                                style: GoogleFonts.rajdhani(
                                  color: isActive ? color : AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              Text(
                                path['bonus'] as String,
                                style: GoogleFonts.shareTechMono(
                                  color: AppColors.textMuted, fontSize: 9,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isActive)
                          Icon(Icons.check_circle, color: color, size: 18)
                        else
                          Text(
                            '${AppConstants.skillPathChangePenalty} EXP',
                            style: GoogleFonts.shareTechMono(
                              color: AppColors.textMuted, fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 20),

              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.violet.withValues(alpha: 0.08),
                    border: Border.all(color: AppColors.violet.withValues(alpha: 0.45)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '[ OPEN SETTINGS ]',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      color: AppColors.violet,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Danger Zone ──────────────────────────────────────────────
              _sectionLabel('DANGER ZONE'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _resetProgress,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.crimson.withValues(alpha: 0.08),
                    border: Border.all(color: AppColors.crimson.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '[ RESET ALL PROGRESS ]',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.rajdhani(
                      color: AppColors.crimson, fontSize: 13,
                      fontWeight: FontWeight.bold, letterSpacing: 2.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.shareTechMono(
          color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.7,
        ),
      );
}
