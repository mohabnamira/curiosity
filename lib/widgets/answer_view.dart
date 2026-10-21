import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/providers/settings_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/answer_actions.dart';
import 'package:curiosity/widgets/question_card.dart';
import 'package:curiosity/widgets/related_question_tile.dart';
import 'package:curiosity/widgets/skeleton_shimmer.dart';
import 'package:curiosity/widgets/sources_panel.dart';
import 'package:curiosity/widgets/sources_pill.dart';
import 'package:curiosity/widgets/typewriter_markdown.dart';

class AnswerView extends ConsumerStatefulWidget {
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
  ConsumerState<AnswerView> createState() => _AnswerViewState();
}

class _AnswerViewState extends ConsumerState<AnswerView> {
  bool _mobileSourcesExpanded = false;

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
    final settings = ref.watch(settingsNotifierProvider);
    final isSearching = turn.status == TurnStatus.searching;
    final isGenerating = turn.status == TurnStatus.generating;
    final isDone = turn.status == TurnStatus.done;
    final isError = turn.status == TurnStatus.error;

    return Padding(
      padding: EdgeInsets.only(bottom: settings.compactMode ? 24.0 : 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. User question bubble
          QuestionCard(question: turn.question),

          // 2. Sources pill above answer
          if (settings.showSourceCards)
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
          if (settings.showSourceCards &&
              widget.showInlineSources &&
              turn.sources.isNotEmpty &&
              _mobileSourcesExpanded) ...[
            _buildMobileSourcesAccordion(),
            const SizedBox(height: 14),
          ],

          // 3. Answer body
          if (turn.answer.isNotEmpty)
            TypewriterMarkdown(
              turn: turn,
              animate: widget.animateTypewriter,
              onHighlightSource: widget.onHighlightSource,
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
            opacity: (isDone && turn.answer.isNotEmpty) ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (turn.answer.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AnswerActions(turn: turn),
                ],
                if (settings.showRelatedQuestions && turn.relatedQuestions.isNotEmpty) ...[
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
                  for (final q in turn.relatedQuestions)
                    RelatedQuestionTile(
                      question: q,
                      onTap: widget.onAskQuery,
                    ),
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
}
