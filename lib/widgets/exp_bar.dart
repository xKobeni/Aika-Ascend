import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../core/constants.dart';
import '../models/user_model.dart';

class ExpBar extends StatefulWidget {
  final UserModel user;
  const ExpBar({super.key, required this.user});

  @override
  State<ExpBar> createState() => _ExpBarState();
}

class _ExpBarState extends State<ExpBar> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fill;
  late Animation<double> _glow;
  double _target = 0;

  @override
  void initState() {
    super.initState();
    _target = _computeFill();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _fill = Tween<double>(begin: 0, end: _target)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _glow = Tween<double>(begin: 0.3, end: 1.0).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(ExpBar old) {
    super.didUpdateWidget(old);
    final newFill = _computeFill();
    if ((newFill - _target).abs() > 0.001) {
      _fill = Tween<double>(begin: _fill.value, end: newFill)
          .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
      _target = newFill;
      _ctrl..reset()..forward();
    }
  }

  double _computeFill() {
    final needed = AppConstants.expToLevelUp(widget.user.level);
    return needed == 0 ? 1.0 : (widget.user.exp / needed).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needed = AppConstants.expToLevelUp(widget.user.level);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXPERIENCE POINTS',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.textMuted, fontSize: 9, letterSpacing: 2,
                ),
              ),
              Text(
                '${widget.user.exp} / $needed EXP',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.textMuted, fontSize: 10, letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              // Track
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Fill with glow
              FractionallySizedBox(
                widthFactor: _fill.value,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F46E5), AppColors.violet],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.violet.withValues(alpha: 0.6 * _glow.value),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.local_fire_department, color: AppColors.gold, size: 13),
              const SizedBox(width: 4),
              Text(
                'Streak: ${widget.user.streak} day${widget.user.streak != 1 ? 's' : ''}',
                style: GoogleFonts.shareTechMono(
                  color: AppColors.gold, fontSize: 11, letterSpacing: 1,
                ),
              ),
              const Spacer(),
              if (widget.user.doubleExpToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.emerald.withValues(alpha: 0.6)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Text(
                    '2× EXP',
                    style: GoogleFonts.shareTechMono(
                      color: AppColors.emerald, fontSize: 9, letterSpacing: 1.5,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
