import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../widgets/typing_text.dart';
import '../services/storage_service.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _floatAnim;
  late Animation<double> _glowAnim;

  int _lineIndex = 0;
  bool _showLines = false;

  static const _bootLines = [
    '> AIKA ASCEND PROTOCOL v2.0',
    '> Initializing hunter database...',
    '> Loading adaptive parameters...',
    '> Calibrating difficulty engine...',
    '> System ready.',
  ];

  @override
  void initState() {
    super.initState();
    _logoCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    );
    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.45, curve: Curves.easeOutCubic)),
    );
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.7, curve: Curves.easeOutBack)),
    );
    _floatAnim = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.easeInOut),
    );
    _glowAnim = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.2, 1.0, curve: Curves.easeInOut)),
    );

    _logoCtrl.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) setState(() => _showLines = true);
      });
    });
  }

  void _onLineComplete() {
    if (_lineIndex < _bootLines.length - 1) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (mounted) setState(() => _lineIndex++);
      });
    } else {
      // All lines done — navigate
      Future.delayed(const Duration(milliseconds: 500), _navigate);
    }
  }

  Future<void> _navigate() async {
    final user = StorageService().getUser();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            user.isOnboarded ? const MainShell() : const OnboardingScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _logoCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.1,
                  colors: [
                    AppColors.violet.withValues(alpha: 0.12 * _glowAnim.value),
                    AppColors.background,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),

          // Dot grid background
          CustomPaint(
            painter: _GridPainter(),
            size: MediaQuery.of(context).size,
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Center(
                      child: FadeTransition(
                        opacity: _logoFade,
                        child: AnimatedBuilder(
                          animation: _logoCtrl,
                          builder: (_, __) => Transform.translate(
                            offset: Offset(0, _floatAnim.value),
                            child: ScaleTransition(
                              scale: _logoScale,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Icon mark
                                  Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppColors.violet, width: 2),
                                      color: AppColors.violet.withValues(alpha: 0.1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.violet.withValues(alpha: 0.45 * _glowAnim.value),
                                          blurRadius: 36,
                                          spreadRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.bolt_rounded,
                                      color: AppColors.violet,
                                      size: 42,
                                    ),
                                  ),
                                  const SizedBox(height: 22),
                                  Text(
                                    'AIKA',
                                    style: GoogleFonts.rajdhani(
                                      color: AppColors.textPrimary,
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 8,
                                    ),
                                  ),
                                  Text(
                                    'ASCEND',
                                    style: GoogleFonts.rajdhani(
                                      color: AppColors.violet,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ── Boot lines ─────────────────────────────────────────────
                  if (_showLines)
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(_lineIndex + 1, (i) {
                          final isLast = i == _lineIndex;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: isLast
                                ? TypingText(
                                    key: ValueKey(i),
                                    text: _bootLines[i],
                                  charDuration: const Duration(milliseconds: 22),
                                    style: GoogleFonts.shareTechMono(
                                      color: i == _bootLines.length - 1
                                          ? AppColors.emerald
                                          : AppColors.cyan,
                                      fontSize: 12,
                                    ),
                                    onComplete: _onLineComplete,
                                  )
                                : Text(
                                    _bootLines[i],
                                    style: GoogleFonts.shareTechMono(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                          );
                        }),
                      ),
                    ),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.35)
      ..strokeWidth = 0.5;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
