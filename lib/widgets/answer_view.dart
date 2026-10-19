import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/answer_actions.dart';
import 'package:curiosity/widgets/skeleton_shimmer.dart';
import 'package:curiosity/widgets/sources_panel.dart';
import 'package:curiosity/widgets/sources_pill.dart';
import 'package:curiosity/widgets/typewriter_markdown.dart';

class AnswerView extends StatefulWidget {
  final Turn turn;
  final bool isLatest;
  final bool animateTypewriter;
  final ValueChanged<String> onAskQuery;
  final ValueChanged<int> onHighlightSource;
  final int? highlightedSourceIndex;
  final VoidCallback onRetry;
  final bool showInlineSources;
  final VoidCallback? onToggleDesktopSources;

  const AnswerView({
    super.key,
    required this.turn,
    required this.isLatest,
    this.animateTypewriter = false,
    required this.onAskQuery,
    required this.onHighlightSource,
    this.highlightedSourceIndex,
    required this.onRetry,
    required this.showInlineSources,
    this.onToggleDesktopSources,
  });

  @override
  State<AnswerView> createState() => _AnswerViewState();
}

class _AnswerViewState extends State<AnswerView> {
  bool _mobileSourcesExpanded = false;
  bool _typingFinished = false;

  @override
  void initState() {
    super.initState();
    _typingFinished = !widget.animateTypewriter || widget.turn.status == TurnStatus.done;
  }

  @override
  void didUpdateWidget(AnswerView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animateTypewriter) {
      _typingFinished = true;
    }
  }

  void _onSourcesPillTap() {
    if (widget.showInlineSources) {
      setState(() => _mobileSourcesExpanded = !_mobileSourcesExpanded);
    } else {
      widget.onToggleDesktopSources?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final turn = widget.turn;
    final isSearching = turn.status == TurnStatus.searching;
    final isGenerating = turn.status == TurnStatus.generating;
    final isDone = turn.status == TurnStatus.done;
    final isError = turn.status == TurnStatus.error;

    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. User query: right-aligned rounded bubble (surface, 1px border, max width ~70%), Inter
          Align(
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
                turn.question,
                style: GoogleFonts.inter(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),

          // 2. Sources pill above answer
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SourcesPill(
                sources: turn.sources,
                researchedSeconds: turn.researchedSeconds,
                isSearching: isSearching,
                onTap: _onSourcesPillTap,
              ),
            ),
          ),

          // Mobile sources collapsible strip
          if (widget.showInlineSources && turn.sources.isNotEmpty && _mobileSourcesExpanded) ...[
            _buildMobileSourcesAccordion(),
            const SizedBox(height: 14),
          ],

          // 3. Answer body
          if (turn.answer.isNotEmpty)
            TypewriterMarkdown(
              turn: turn,
              animate: widget.animateTypewriter,
              onHighlightSource: widget.onHighlightSource,
              onTypingFinished: () {
                if (mounted) setState(() => _typingFinished = true);
              },
            )
          else if (isGenerating || isSearching)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: SkeletonShimmer(),
            )
          else if (isDone && turn.answer.isEmpty)
            Text(
              'No answer was generated.',
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),

          // Error state with Retry
          if (isError) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.error_outline_rounded, size: 16, color: Colors.redAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    turn.errorMessage ?? 'Failed to generate answer',
                    style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: widget.onRetry,
                  child: Text(
                    'Retry',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // 4. Answer actions row & related questions with fade-in after typing finishes
          AnimatedOpacity(
            opacity: (isDone && _typingFinished && turn.answer.isNotEmpty) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (turn.answer.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AnswerActions(turn: turn),
                ],
                if (turn.relatedQuestions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Related',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final q in turn.relatedQuestions) _buildRelatedQuestionRow(q),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSourcesAccordion() {
    final count = widget.turn.sources.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _mobileSourcesExpanded = !_mobileSourcesExpanded),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.source_outlined, size: 16, color: AppColors.iconMuted),
                  const SizedBox(width: 8),
                  Text(
                    '$count source${count > 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _mobileSourcesExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.iconMuted,
                  ),
                ],
              ),
            ),
          ),
          if (_mobileSourcesExpanded)
            SizedBox(
              height: 260,
              child: SourcesPanel(
                sources: widget.turn.sources,
                highlightedIndex: widget.highlightedSourceIndex,
              ),
            ),
        ],
      ),
    );
  }



  Widget _buildRelatedQuestionRow(String q) {
    return _HoverRelatedRow(
      text: q,
      onTap: () => widget.onAskQuery(q),
    );
  }
}

class _HoverRelatedRow extends StatefulWidget {
  final String text;
  final VoidCallback onTap;

  const _HoverRelatedRow({required this.text, required this.onTap});

  @override
  State<_HoverRelatedRow> createState() => _HoverRelatedRowState();
}

class _HoverRelatedRowState extends State<_HoverRelatedRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _isHovered ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '↳',
                style: TextStyle(
                  color: AppColors.iconMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.text,
                  style: GoogleFonts.inter(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
