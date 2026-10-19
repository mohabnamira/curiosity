import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/theme/colors.dart';

/// Renders the user's question bubble in the conversation stream.
class QuestionCard extends StatelessWidget {
  final String question;

  const QuestionCard({
    super.key,
    required this.question,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 540),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Text(
          question,
          style: GoogleFonts.inter(
            color: AppColors.textPrimary,
            fontSize: 15,
            height: 1.4,
            fontWeight: FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
