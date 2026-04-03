import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';
import '../services/content_service.dart';

/// Displays the hunter's current title with rank styling.
class TitleBadge extends StatelessWidget {
  final int titleId;
  final int level;

  const TitleBadge({super.key, required this.titleId, required this.level});

  Color get _color {
    if (titleId == 11) return AppColors.crimson; // Failure
    if (titleId >= 9) return AppColors.gold;      // Shadow Monarch, Warlord
    if (titleId >= 6) return AppColors.violet;    // Dragon Slayer, Survivor, Redeemed
    if (titleId >= 3) return AppColors.cyan;      // Unbreakable+
    return AppColors.textMuted;
  }

  String get _titleName {
    final titles = ContentService.instance.titles;
    return titles[titleId.clamp(0, titles.length - 1)]['name'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.violet.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.violet, width: 1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            'LV.$level',
            style: GoogleFonts.rajdhani(
              color: AppColors.violet,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          constraints: const BoxConstraints(maxWidth: 190),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.10),
            border: Border.all(color: _color.withValues(alpha: 0.7), width: 1),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Text(
            _titleName.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.rajdhani(
              color: _color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
