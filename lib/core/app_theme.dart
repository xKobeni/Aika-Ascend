import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData dark({bool highContrast = false}) {
    final base = ThemeData.dark();
    final background = highContrast ? const Color(0xFF000000) : AppColors.background;
    final surface = highContrast ? const Color(0xFF0B0B0B) : AppColors.surface;
    final primary = highContrast ? const Color(0xFF8EA2FF) : AppColors.violet;
    final secondary = highContrast ? const Color(0xFF79F6FF) : AppColors.cyan;
    final border = highContrast ? Colors.white70 : AppColors.cardBorder;

    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
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
        backgroundColor: background,
        elevation: 0,
        titleTextStyle: GoogleFonts.rajdhani(
          color: AppColors.textPrimary, fontSize: 18,
          fontWeight: FontWeight.bold, letterSpacing: 3,
        ),
        iconTheme: const IconThemeData(color: AppColors.cyan),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          textStyle: GoogleFonts.rajdhani(
            fontWeight: FontWeight.bold, letterSpacing: 1.6, fontSize: 15,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: border),
        ),
      ),
      dividerColor: border,
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.rajdhani(fontSize: 11, letterSpacing: 1.3),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primary, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
      ),
    );
  }
}
