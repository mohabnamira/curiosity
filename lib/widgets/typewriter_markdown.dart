import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/models/settings_state.dart';
import 'package:curiosity/providers/settings_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/citation_syntax.dart';
import 'package:curiosity/widgets/shared/code_block.dart';

/// Renders streaming and completed markdown answers with citation chips, code blocks,
/// and font settings, with smooth throttled typewriter animation and safe syntax sanitization.
class TypewriterMarkdown extends ConsumerStatefulWidget {
  final Turn turn;
  final bool animate;
  final ValueChanged<int>? onHighlightSource;
  final VoidCallback? onTypingFinished;

  const TypewriterMarkdown({
    super.key,
    required this.turn,
    required this.animate,
    this.onHighlightSource,
    this.onTypingFinished,
  });

  @override
  ConsumerState<TypewriterMarkdown> createState() => _TypewriterMarkdownState();
}

class _TypewriterMarkdownState extends ConsumerState<TypewriterMarkdown> {
  Timer? _tickerTimer;
  int _revealedChars = 0;
  bool _finishedNotified = false;

  MarkdownStyleSheet? _cachedStyleSheet;
  AnswerFontFamily? _cachedFontFam;
  double? _cachedBaseSize;

  MarkdownStyleSheet _getStyleSheet(AnswerFontFamily fontFam, double baseSize) {
    if (_cachedStyleSheet != null &&
        _cachedFontFam == fontFam &&
        _cachedBaseSize == baseSize) {
      return _cachedStyleSheet!;
    }
    _cachedFontFam = fontFam;
    _cachedBaseSize = baseSize;
    _cachedStyleSheet = MarkdownStyleSheet(
      p: _fontForFamily(
        fontFam,
        fontSize: baseSize,
        height: 1.65,
        color: AppColors.textPrimary,
      ),
      h1: _fontForFamily(
        fontFam,
        fontSize: baseSize * 1.4,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      h2: _fontForFamily(
        fontFam,
        fontSize: baseSize * 1.2,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      h3: _fontForFamily(
        fontFam,
        fontSize: baseSize * 1.1,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      listBullet: _fontForFamily(
        fontFam,
        fontSize: baseSize,
        color: AppColors.textPrimary,
      ),
      code: GoogleFonts.firaCode(
        fontSize: (baseSize - 2).clamp(11.0, 16.0),
        color: AppColors.textPrimary,
        backgroundColor: const Color(0xFF1B1D24),
      ),
      codeblockDecoration: const BoxDecoration(),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      blockquoteDecoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.border, width: 3)),
      ),
    );
    return _cachedStyleSheet!;
  }

  @override
  void initState() {
    super.initState();
    if (widget.animate && widget.turn.status != TurnStatus.done) {
      _revealedChars = (widget.turn.answer.length * 0.2).toInt();
      _startTicker();
    } else {
      _revealedChars = widget.turn.answer.length;
      _checkFinished();
    }
  }

  @override
  void didUpdateWidget(TypewriterMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    final targetLength = widget.turn.answer.length;

    if (!widget.animate) {
      _stopTicker();
      _revealedChars = targetLength;
      _checkFinished();
      return;
    }

    if (_revealedChars < targetLength) {
      if (_tickerTimer == null || !_tickerTimer!.isActive) {
        _startTicker();
      }
    } else if (widget.turn.status == TurnStatus.done) {
      _stopTicker();
      _revealedChars = targetLength;
      _checkFinished();
    }
  }

  @override
  void dispose() {
    _stopTicker();
    super.dispose();
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    // 30-33ms timer (~30fps) - optimal balance between silky smooth typing and minimal mobile Markdown re-parsing
    _tickerTimer = Timer.periodic(const Duration(milliseconds: 32), (_) {
      final total = widget.turn.answer.length;
      if (_revealedChars >= total) {
        if (widget.turn.status == TurnStatus.done) {
          _stopTicker();
          _checkFinished();
        }
        return;
      }

      final diff = total - _revealedChars;
      // Adaptive typing speed:
      // - small backlog: reveal 2-3 characters per frame (~70-90 cps)
      // - larger backlog: smoothly speed up so animation never falls far behind
      final int step;
      if (diff > 120) {
        step = (diff / 6).clamp(8, 25).toInt();
      } else if (diff > 50) {
        step = (diff / 10).clamp(4, 8).toInt();
      } else {
        step = 2;
      }

      setState(() {
        _revealedChars = (_revealedChars + step).clamp(0, total);
      });

      if (_revealedChars >= total && widget.turn.status == TurnStatus.done) {
        _stopTicker();
        _checkFinished();
      }
    });
  }

  void _stopTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
  }

  void _checkFinished() {
    if (widget.turn.status == TurnStatus.done && !_finishedNotified) {
      _finishedNotified = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onTypingFinished?.call();
      });
    }
  }

  static String _sanitizeMarkdown(String text) {
    if (text.isEmpty) return '';

    // 1. Hide trailing unclosed '[' fragment so citation chips don't flash broken
    final lastOpen = text.lastIndexOf('[');
    if (lastOpen != -1) {
      final lastClose = text.lastIndexOf(']');
      if (lastClose < lastOpen) {
        final fragment = text.substring(lastOpen);
        if (RegExp(r'^\[\d*$').hasMatch(fragment)) {
          text = text.substring(0, lastOpen);
        }
      }
    }

    // 2. Virtual close of triple-backtick code fences so code blocks render cleanly
    final fenceMatches = RegExp(r'```').allMatches(text);
    if (fenceMatches.length.isOdd) {
      text = '$text\n```';
    }

    return text;
  }

  TextStyle _fontForFamily(
    AnswerFontFamily family, {
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    double height = 1.65,
    required Color color,
  }) {
    final cairoFallback = [GoogleFonts.cairo().fontFamily!];
    switch (family) {
      case AnswerFontFamily.cairo:
        return GoogleFonts.cairo(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
        );
      case AnswerFontFamily.serif:
        return GoogleFonts.newsreader(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
        ).copyWith(fontFamilyFallback: cairoFallback);
      case AnswerFontFamily.sans:
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
        ).copyWith(fontFamilyFallback: cairoFallback);
      case AnswerFontFamily.mono:
        return GoogleFonts.firaCode(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
        ).copyWith(fontFamilyFallback: cairoFallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final sourceUrls = widget.turn.sources.map((s) => s.url).toList();
    final baseSize = settings.answerFontSize;
    final fontFam = settings.answerFont;
    final isGenerating = widget.turn.status == TurnStatus.generating;

    // Use revealed characters if animating, or full text if finished / not animating
    final fullText = widget.turn.answer;
    final textToShow = widget.animate && _revealedChars < fullText.length
        ? fullText.substring(0, _revealedChars)
        : fullText;

    final sanitizedText = _sanitizeMarkdown(textToShow);
    final styleSheet = _getStyleSheet(fontFam, baseSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MarkdownBody(
          data: sanitizedText,
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
          styleSheet: styleSheet,
          extensionSet: md.ExtensionSet.gitHubFlavored,
        ),
        if (isGenerating || (widget.animate && _revealedChars < fullText.length))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: settings.accentColor.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
