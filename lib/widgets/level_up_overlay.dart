import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

/// Full-screen level-up overlay effect.
class LevelUpOverlay {
  static Future<void> show(BuildContext context, UserModel user) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'LevelUp',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (ctx, anim, _) => _LevelUpPage(user: user),
      transitionBuilder: (ctx, anim, _, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeIn),
        child: child,
      ),
    );
  }
}

class _LevelUpPage extends StatefulWidget {
  final UserModel user;
  const _LevelUpPage({required this.user});

  @override
  State<_LevelUpPage> createState() => _LevelUpPageState();
}

class _LevelUpPageState extends State<_LevelUpPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.elasticOut)),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.3, curve: Curves.easeIn)),
    );
    _glowAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _ctrl.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.92),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                AppColors.gold.withValues(alpha: 0.15 * _glowAnim.value),
                Colors.transparent,
              ],
            ),
          ),
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Glow ring
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.5 * _glowAnim.value),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${widget.user.level}',
                          style: GoogleFonts.rajdhani(
                            color: AppColors.gold,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      '[ LEVEL UP ]',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.gold,
                        fontSize: 14,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'You have ascended.',
                      style: GoogleFonts.rajdhani(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.rankLabel(widget.user.level),
                      style: GoogleFonts.shareTechMono(
                        color: AppColors.textMuted,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        '[ TAP TO CONTINUE ]',
                        style: GoogleFonts.shareTechMono(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
