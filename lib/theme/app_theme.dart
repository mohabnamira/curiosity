import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/models/settings_state.dart';
import 'colors.dart';

class AppTheme {
  static ThemeData buildTheme({
    AccentColorOption accent = AccentColorOption.monochrome,
  }) {
    final accentCol = accent.color;

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.dark(
        primary: accentCol,
        secondary: AppColors.textSecondary,
        surface: AppColors.surface,
      ),
      textTheme: TextTheme(
        headlineMedium: GoogleFonts.newsreader(
          color: AppColors.textPrimary,
          fontSize: 38,
          fontWeight: FontWeight.normal,
        ),
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
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      fontFamilyFallback: [GoogleFonts.cairo().fontFamily!],

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        elevation: 10,
        backgroundColor: const Color(0xFF1E2129),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFF2E323D), width: 1),
        ),
        contentTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static ThemeData get theme => buildTheme();
}
