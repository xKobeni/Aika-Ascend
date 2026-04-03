import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Animated atmospheric background with subtle moving color orbs.
class AnimatedBackground extends StatefulWidget {
  final Widget child;

  const AnimatedBackground({super.key, required this.child});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (_, __) => CustomPaint(
              painter: _AnimatedBackgroundPainter(_controller.value),
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _AnimatedBackgroundPainter extends CustomPainter {
  final double t;

  _AnimatedBackgroundPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()..color = AppColors.background;
    canvas.drawRect(Offset.zero & size, base);

    final center1 = Offset(
      size.width * (0.18 + 0.08 * math.sin(t * math.pi * 2)),
      size.height * (0.20 + 0.07 * math.cos(t * math.pi * 2)),
    );
    final center2 = Offset(
      size.width * (0.82 + 0.06 * math.cos(t * math.pi * 2 + 1.4)),
      size.height * (0.26 + 0.05 * math.sin(t * math.pi * 2 + 1.4)),
    );
    final center3 = Offset(
      size.width * (0.52 + 0.06 * math.sin(t * math.pi * 2 + 2.1)),
      size.height * (0.82 + 0.05 * math.cos(t * math.pi * 2 + 2.1)),
    );

    _orb(canvas, size, center1, AppColors.violet.withValues(alpha: 0.20), 0.50);
    _orb(canvas, size, center2, AppColors.cyan.withValues(alpha: 0.16), 0.46);
    _orb(canvas, size, center3, AppColors.emerald.withValues(alpha: 0.12), 0.42);

    final gridPaint = Paint()
      ..color = AppColors.cardBorder.withValues(alpha: 0.14)
      ..strokeWidth = 0.5;
    const spacing = 34.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.7, gridPaint);
      }
    }
  }

  void _orb(Canvas canvas, Size size, Offset center, Color color, double radiusFactor) {
    final radius = size.shortestSide * radiusFactor;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color,
          color.withValues(alpha: color.a * 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedBackgroundPainter oldDelegate) {
    return oldDelegate.t != t;
  }
}