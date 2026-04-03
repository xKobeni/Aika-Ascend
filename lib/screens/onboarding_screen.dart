import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/storage_service.dart';
import '../services/achievement_service.dart';
import '../services/content_service.dart';
import '../widgets/animated_background.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _page = PageController();
  final TextEditingController _nameCtrl = TextEditingController();
  final ContentService _content = ContentService.instance;
  int _selectedPath = -1;
  bool _saving = false;

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    final storage = StorageService();
    final user = storage.getUser();
    user.hunterName = _nameCtrl.text.trim().isEmpty
        ? 'Hunter'
        : _nameCtrl.text.trim();
    user.skillPath = _selectedPath < 0 ? 0 : _selectedPath;
    user.isOnboarded = true;
    await storage.saveUser(user);

    // Unlock path_chosen achievement
    await AchievementService().checkAll(user);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _page.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBackground(
        child: SafeArea(
          child: PageView(
            controller: _page,
            physics: const NeverScrollableScrollPhysics(),
            children: [_namePage(), _pathPage()],
          ),
        ),
      ),
    );
  }

  // ── Page 1: Name ──────────────────────────────────────────────────────────
  Widget _namePage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text('SYSTEM ONLINE', style: GoogleFonts.shareTechMono(
            color: AppColors.cyan, fontSize: 12, letterSpacing: 2.5,
          )),
          const SizedBox(height: 16),
          Text('Enter your\ndesignation.', style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary, fontSize: 36,
            fontWeight: FontWeight.bold, height: 1.1,
          )),
          const SizedBox(height: 8),
          Text(
            'This is the name the System will use to address you.',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textMuted, fontSize: 12, height: 1.6,
            ),
          ),
          const SizedBox(height: 48),

          // Name input
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.violet.withValues(alpha: 0.6)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              controller: _nameCtrl,
              style: GoogleFonts.rajdhani(
                color: AppColors.textPrimary, fontSize: 22,
                fontWeight: FontWeight.bold, letterSpacing: 2,
              ),
              maxLength: 16,
              decoration: InputDecoration(
                hintText: 'HUNTER',
                hintStyle: GoogleFonts.rajdhani(
                  color: AppColors.textMuted, fontSize: 22, letterSpacing: 2,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12,
                ),
                counterText: '',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ),

          const Spacer(),
          _nextButton(
            label: '[ CONFIRM DESIGNATION ]',
            onTap: () {
              _page.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Page 2: Skill Path ────────────────────────────────────────────────────
  Widget _pathPage() {
    final skillPaths = _content.skillPaths;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text('SPECIALIZATION', style: GoogleFonts.shareTechMono(
            color: AppColors.cyan, fontSize: 12, letterSpacing: 2.5,
          )),
          const SizedBox(height: 16),
          Text('Choose your\nSkill Path.', style: GoogleFonts.rajdhani(
            color: AppColors.textPrimary, fontSize: 36,
            fontWeight: FontWeight.bold, height: 1.1,
          )),
          const SizedBox(height: 8),
          Text(
            'Your path shapes how quests are generated. Choose wisely — changes cost EXP.',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textMuted, fontSize: 12, height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.builder(
              itemCount: skillPaths.length,
              itemBuilder: (_, i) {
                final path = skillPaths[i];
                final isSelected = _selectedPath == i;
                final color = i == 0
                    ? AppColors.strengthColor
                    : i == 1
                        ? AppColors.enduranceColor
                        : AppColors.disciplineColor;

                return GestureDetector(
                  onTap: () => setState(() => _selectedPath = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.12)
                          : AppColors.surface,
                      border: Border.all(
                        color: isSelected
                            ? color
                            : AppColors.cardBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 16)]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            border: Border.all(color: color.withValues(alpha: 0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            path['badge'] as String,
                            style: GoogleFonts.rajdhani(
                              color: color,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (path['name'] as String).toUpperCase(),
                                style: GoogleFonts.rajdhani(
                                  color: isSelected ? color : AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                path['desc'] as String,
                                style: GoogleFonts.shareTechMono(
                                  color: AppColors.textMuted, fontSize: 10, height: 1.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                path['bonus'] as String,
                                style: GoogleFonts.shareTechMono(
                                  color: isSelected ? color : AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: color, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          _nextButton(
            label: '[ BEGIN ASCENT ]',
            enabled: _selectedPath >= 0,
            onTap: _finish,
          ),
        ],
      ),
    );
  }

  Widget _nextButton({
    required String label,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    final color = enabled ? AppColors.violet : AppColors.textMuted;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: enabled ? 0.15 : 0.05),
          border: Border.all(color: color.withValues(alpha: enabled ? 0.8 : 0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.rajdhani(
            color: color, fontSize: 14,
            fontWeight: FontWeight.bold, letterSpacing: 2.5,
          ),
        ),
      ),
    );
  }
}
