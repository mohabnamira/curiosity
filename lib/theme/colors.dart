import 'package:flutter/material.dart';

/// Central monochrome color tokens for dark and light modes.
class AppColors {
  // Dark Palette (default)
  static const background = Color(0xFF0D0E11);
  static const surface = Color(0xFF16181D);
  static const surfaceHover = Color(0xFF1E2129);
  static const border = Color(0xFF23262F);
  static const textPrimary = Color(0xFFF4F5F6);
  static const textSecondary = Color(0xFF8A8F9B);
  static const iconMuted = Color(0xFF727682);
  static const focus = Color(0xFFFFFFFF);

  // Light Palette (monochrome clean)
  static const lightBackground = Color(0xFFF8F9FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE5E7EB);
  static const lightTextPrimary = Color(0xFF111827);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightIconMuted = Color(0xFF9CA3AF);
  static const lightFocus = Color(0xFF111827);

  // Compatibility aliases
  static const sideNav = surface;
  static const searchBar = surface;
  static const searchBarBorder = border;
  static const iconGrey = iconMuted;
  static const textGrey = textPrimary;
  static const footerGrey = textSecondary;
  static const proButton = focus;
  static const cardColor = surface;
  static const submitButton = focus;
  static const whiteColor = Colors.white;
}