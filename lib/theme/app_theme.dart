import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  static final ThemeData theme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    // Primary color scheme using our monochrome palette (seed only for completeness)
    colorScheme: const ColorScheme.dark(
      primary: AppColors.focus,
      secondary: AppColors.textSecondary,
      surface: AppColors.surface,
    ),
    // Typography
    textTheme: TextTheme(
      // Home headline and answer body (serif)
      headlineMedium: GoogleFonts.newsreader(
        color: AppColors.textPrimary,
        fontSize: 38,
        fontWeight: FontWeight.normal,
      ),
      // UI chrome – Inter
      bodyLarge: GoogleFonts.inter(
        color: AppColors.textPrimary,
      ),
      bodyMedium: GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
      bodySmall: GoogleFonts.inter(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
      // Code – Fira Code (will be applied where needed)
      // Citation chips – small monospace (use default font with size)
    ),
    // Default font family for widgets that don't specify
    fontFamily: GoogleFonts.inter().fontFamily,
    // Input decoration theme uses our surface/background colors with zero outline
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    ),
    // AppBar styling
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(color: AppColors.textPrimary, fontSize: 18),
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),
    canvasColor: AppColors.background,
    cardColor: AppColors.surface,
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
        TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}
