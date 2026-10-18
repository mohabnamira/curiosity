import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/answer_actions.dart';
import 'package:curiosity/widgets/citation_syntax.dart';
import 'package:curiosity/widgets/shared/code_block.dart';
import 'package:curiosity/widgets/skeleton_shimmer.dart';
import 'package:curiosity/widgets/sources_panel.dart';

class AnswerView extends StatefulWidget {
  final Turn turn;
  final bool isLatest;
  final ValueChanged<String> onAskQuery;
  final ValueChanged<int> onHighlightSource;
  final int? highlightedSourceIndex;
  final VoidCallback onRetry;
  final bool showInlineSources;

  const AnswerView({
    super.key,
    required this.turn,
    required this.isLatest,
    required this.onAskQuery,
    required this.onHighlightSource,
    this.highlightedSourceIndex,
    required this.onRetry,
    required this.showInlineSources,
  });

  @override
  State<AnswerView> createState() => _AnswerViewState();
}

class _AnswerViewState extends State<AnswerView> {
  bool _mobileSourcesExpanded = false;

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

          // 2. Muted caption "Researched {n}s" / "Searching..."
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                if (isSearching) ...[
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Searching...',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ] else if (turn.researchedSeconds != null) ...[
                  const Icon(
                    Icons.bolt_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Researched ${turn.researchedSeconds}s',
                    style: GoogleFonts.inter(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Mobile sources collapsible strip
          if (widget.showInlineSources && turn.sources.isNotEmpty) ...[
            _buildMobileSourcesAccordion(),
            const SizedBox(height: 14),
          ],

          // 3. Answer body
          if (turn.answer.isNotEmpty)
            _buildAnswerBody()
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

          // 4. Answer actions row
          if (isDone && turn.answer.isNotEmpty) ...[
            const SizedBox(height: 16),
            AnswerActions(
              turn: turn,
              onOpenSources: () {
                if (widget.showInlineSources) {
                  setState(() => _mobileSourcesExpanded = !_mobileSourcesExpanded);
                } else if (turn.sources.isNotEmpty) {
                  widget.onHighlightSource(0);
                }
              },
            ),
          ],

          // 5. Related questions
          if (isDone && turn.relatedQuestions.isNotEmpty) ...[
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

  Widget _buildAnswerBody() {
    final sourceUrls = widget.turn.sources.map((s) => s.url).toList();

    return MarkdownBody(
      data: widget.turn.answer,
      inlineSyntaxes: [
        CitationSyntax(),
      ],
      builders: {
        'pre': CodeBlockBuilder(),
        'citation': CitationElementBuilder(
          sourceUrls: sourceUrls,
          onCitationTap: widget.onHighlightSource,
        ),
      },
      styleSheet: MarkdownStyleSheet(
        p: GoogleFonts.newsreader(
          fontSize: 17,
          height: 1.65,
          color: AppColors.textPrimary,
        ),
        h1: GoogleFonts.newsreader(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        h2: GoogleFonts.newsreader(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        h3: GoogleFonts.newsreader(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        listBullet: GoogleFonts.newsreader(
          fontSize: 17,
          color: AppColors.textPrimary,
        ),
        code: GoogleFonts.firaCode(
          fontSize: 13,
          color: AppColors.textPrimary,
          backgroundColor: const Color(0xFF1B1D24),
        ),
        codeblockDecoration: const BoxDecoration(),
      ),
      extensionSet: md.ExtensionSet.gitHubFlavored,
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
