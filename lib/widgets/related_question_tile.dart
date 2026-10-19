import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/theme/colors.dart';

/// Renders a clickable related question chip row.
class RelatedQuestionTile extends StatefulWidget {
  final String question;
  final ValueChanged<String> onTap;

  const RelatedQuestionTile({
    super.key,
    required this.question,
    required this.onTap,
  });

  @override
  State<RelatedQuestionTile> createState() => _RelatedQuestionTileState();
}

class _RelatedQuestionTileState extends State<RelatedQuestionTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: InkWell(
          onTap: () => widget.onTap(widget.question),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _isHovered ? AppColors.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isHovered ? AppColors.border : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: AppColors.iconMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
