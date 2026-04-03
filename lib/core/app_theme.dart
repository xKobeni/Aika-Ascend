import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.violet,
        secondary: AppColors.cyan,
        surface: AppColors.surface,
        error: AppColors.crimson,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.rajdhani(
          color: AppColors.textPrimary, fontSize: 36,
          fontWeight: FontWeight.bold, letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.rajdhani(
          color: AppColors.textPrimary, fontSize: 28,
          fontWeight: FontWeight.bold, letterSpacing: 1.5,
        ),
        displaySmall: GoogleFonts.rajdhani(
          color: AppColors.textPrimary, fontSize: 22,
          fontWeight: FontWeight.w600, letterSpacing: 1,
        ),
        headlineMedium: GoogleFonts.rajdhani(
          color: AppColors.textPrimary, fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.rajdhani(
          color: AppColors.textPrimary, fontSize: 18,
          fontWeight: FontWeight.bold, letterSpacing: 1,
        ),
        bodyLarge: GoogleFonts.shareTechMono(
          color: AppColors.textPrimary, fontSize: 14,
        ),
        bodyMedium: GoogleFonts.shareTechMono(
          color: AppColors.textMuted, fontSize: 12,
        ),
        labelLarge: GoogleFonts.rajdhani(
          color: AppColors.cyan, fontSize: 13,
          fontWeight: FontWeight.bold, letterSpacing: 2,
        ),
        labelSmall: GoogleFonts.shareTechMono(
          color: AppColors.textMuted, fontSize: 11, letterSpacing: 1.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleTextStyle: GoogleFonts.rajdhani(
          color: AppColors.textPrimary, fontSize: 18,
          fontWeight: FontWeight.bold, letterSpacing: 3,
        ),
        iconTheme: const IconThemeData(color: AppColors.cyan),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold, letterSpacing: 1.6, fontSize: 15,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
      ),
      dividerColor: AppColors.cardBorder,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.violet.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.rajdhani(fontSize: 11, letterSpacing: 1.3),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.violet, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
      ),
    );
  }
}
