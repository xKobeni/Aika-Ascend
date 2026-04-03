import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

/// Live countdown widget showing time remaining until midnight.
class CountdownWidget extends StatefulWidget {
  const CountdownWidget({super.key});

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    setState(() => _remaining = midnight.difference(now));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color get _color {
    final hours = _remaining.inHours;
    if (hours < 2) return AppColors.crimson;
    if (hours < 6) return AppColors.gold;
    return AppColors.cyan;
  }

  @override
  Widget build(BuildContext context) {
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.07),
        border: Border.all(color: _color.withValues(alpha: 0.4), width: 1),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: _color.withValues(alpha: 0.15),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.schedule_rounded, color: _color, size: 14),
          const SizedBox(width: 8),
          Text(
            'SESSION EXPIRES IN  ',
            style: GoogleFonts.shareTechMono(
              color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2,
            ),
          ),
          Text(
            '$h:$m:$s',
            style: GoogleFonts.shareTechMono(
              color: _color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.7,
            ),
          ),
        ],
      ),
    );
  }
}
