import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/source_card.dart';

class SourcesPanel extends StatefulWidget {
  final List<Source> sources;
  final int? highlightedIndex;
  final bool isCollapsible;
  final VoidCallback? onToggleCollapse;

  const SourcesPanel({
    super.key,
    required this.sources,
    this.highlightedIndex,
    this.isCollapsible = false,
    this.onToggleCollapse,
  });

  @override
  State<SourcesPanel> createState() => _SourcesPanelState();
}

class _SourcesPanelState extends State<SourcesPanel> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(SourcesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightedIndex != null &&
        widget.highlightedIndex != oldWidget.highlightedIndex) {
      _scrollToHighlighted();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToHighlighted() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients || widget.highlightedIndex == null) return;
      final target = (widget.highlightedIndex! * 110.0).clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.source_outlined,
                  size: 16,
                  color: AppColors.iconMuted,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sources',
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.sources.length}',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                if (widget.isCollapsible && widget.onToggleCollapse != null)
                  IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_up_rounded,
                      size: 20,
                      color: AppColors.iconMuted,
                    ),
                    onPressed: widget.onToggleCollapse,
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Scrollable list with bottom fade gradient
          Expanded(
            child: widget.sources.isEmpty
                ? Center(
                    child: Text(
                      'No sources available',
                      style: GoogleFonts.inter(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: widget.sources.length,
                        itemBuilder: (context, index) {
                          return SourceCard(
                            source: widget.sources[index],
                            index: index,
                            isHighlighted: widget.highlightedIndex == index,
                          );
                        },
                      ),
                      // Bottom gradient fade
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 24,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(12),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.surface.withValues(alpha: 0.0),
                                  AppColors.surface,
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
