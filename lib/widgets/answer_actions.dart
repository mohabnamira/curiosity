import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/services/export_service.dart' as export_service;
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/citation_chip.dart';
import 'package:curiosity/widgets/listen_button.dart';

class AnswerActions extends StatefulWidget {
  final Turn turn;
  final VoidCallback? onOpenSources;

  const AnswerActions({
    super.key,
    required this.turn,
    this.onOpenSources,
  });

  @override
  State<AnswerActions> createState() => _AnswerActionsState();
}

class _AnswerActionsState extends State<AnswerActions> {
  bool? _liked; // true = up, false = down, null = none

  Future<void> _copyAnswer(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.turn.answer));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Answer copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _onShareSelected(BuildContext context, String action) {
    if (action == 'markdown') {
      export_service.exportMarkdown(context, widget.turn);
    } else if (action == 'pdf') {
      export_service.exportPdf(context, widget.turn);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sources = widget.turn.sources;
    final sourceCount = sources.length;

    return Row(
      children: [
        // Listen button
        ListenButton(text: widget.turn.answer),
        // Copy icon button
        _ActionIconBtn(
          icon: Icons.copy_rounded,
          tooltip: 'Copy',
          onTap: () => _copyAnswer(context),
        ),
        // Share popup menu (Export Markdown & PDF)
        PopupMenuButton<String>(
          tooltip: 'Share',
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: AppColors.border, width: 1),
          ),
          onSelected: (val) => _onShareSelected(context, val),
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'markdown',
              height: 36,
              child: Row(
                children: [
                  const Icon(Icons.code_rounded, size: 16, color: AppColors.textPrimary),
                  const SizedBox(width: 8),
                  Text('Export Markdown', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'pdf',
              height: 36,
              child: Row(
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, size: 16, color: AppColors.textPrimary),
                  const SizedBox(width: 8),
                  Text('Export PDF', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13)),
                ],
              ),
            ),
          ],
          child: const _HoverIconBox(
            icon: Icons.share_outlined,
            tooltip: 'Share',
          ),
        ),
        // Thumbs up / down (UI-only)
        _ActionIconBtn(
          icon: _liked == true ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
          color: _liked == true ? AppColors.textPrimary : null,
          tooltip: 'Good response',
          onTap: () => setState(() => _liked = _liked == true ? null : true),
        ),
        _ActionIconBtn(
          icon: _liked == false ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
          color: _liked == false ? AppColors.textPrimary : null,
          tooltip: 'Bad response',
          onTap: () => setState(() => _liked = _liked == false ? null : false),
        ),
        const Spacer(),
        // "N sources" button with up to 3 overlapping favicons
        if (sourceCount > 0)
          InkWell(
            onTap: widget.onOpenSources,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOverlappingFavicons(sources),
                  const SizedBox(width: 8),
                  Text(
                    '$sourceCount source${sourceCount > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverlappingFavicons(List<Source> sources) {
    final preview = sources.take(3).toList();
    const double size = 16;
    const double overlap = 10;
    final totalWidth = size + (preview.length - 1) * overlap;

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < preview.length; i++)
            Positioned(
              left: i * overlap,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                  color: AppColors.border,
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://www.google.com/s2/favicons?domain=${cleanDomain(preview[i].url)}&sz=32',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.language,
                      size: 10,
                      color: AppColors.iconMuted,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionIconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _ActionIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _HoverIconBox(
      icon: icon,
      tooltip: tooltip,
      onTap: onTap,
      activeColor: color,
    );
  }
}

class _HoverIconBox extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? activeColor;

  const _HoverIconBox({
    required this.icon,
    required this.tooltip,
    this.onTap,
    this.activeColor,
  });

  @override
  State<_HoverIconBox> createState() => _HoverIconBoxState();
}

class _HoverIconBoxState extends State<_HoverIconBox> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Icon(
              widget.icon,
              size: 16,
              color: widget.activeColor ??
                  (_isHovered ? AppColors.textPrimary : AppColors.iconMuted),
            ),
          ),
        ),
      ),
    );
  }
}
