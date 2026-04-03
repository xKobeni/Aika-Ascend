import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/app_colors.dart';

class SystemPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final Color borderColor;
  final IconData? icon;
  final Widget? trailing;

  const SystemPanel({
    super.key,
    required this.title,
    required this.child,
    this.borderColor = AppColors.cardBorder,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.12),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              color: borderColor.withValues(alpha: 0.07),
              border: Border(
                bottom: BorderSide(color: borderColor.withValues(alpha: 0.4)),
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: borderColor, size: 12),
                  const SizedBox(width: 6),
                ],
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.shareTechMono(
                    color: borderColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.9,
                  ),
                ),
                const Spacer(),
                if (trailing != null)
                  trailing!
                else
                  Row(
                    children: List.generate(
                      3,
                      (i) => Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: borderColor.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}
