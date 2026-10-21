import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/theme/colors.dart';

/// Displays a sleek floating dark toast with rounded corners, drop shadow, and centered text.
void showToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
  IconData? icon,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 10,
      width: 320,
      backgroundColor: const Color(0xFF1E2129),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0xFF2E323D), width: 1),
      ),
      duration: duration,
      content: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: AppColors.textSecondary),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    ),
  );
}
