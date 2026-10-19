import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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

class _TypewriterMarkdownState extends ConsumerState<TypewriterMarkdown>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> _revealedCharsCount = ValueNotifier<int>(0);

  double _fractionalChars = 0.0;
  Duration _lastTick = Duration.zero;
  bool _finishedNotified = false;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _revealedCharsCount.value = 0;
      _fractionalChars = 0.0;
      _ticker = createTicker(_onTick)..start();
    } else {
      _revealedCharsCount.value = widget.turn.answer.characters.length;
      _finishedNotified = true;
    }
  }

  @override
  void didUpdateWidget(TypewriterMarkdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.animate) {
      if (_ticker.isActive) _ticker.stop();
      _revealedCharsCount.value = widget.turn.answer.characters.length;
      if (!_finishedNotified) {
        _finishedNotified = true;
        widget.onTypingFinished?.call();
      }
      return;
    }

    if (widget.turn.status == TurnStatus.done && !_ticker.isActive && !_finishedNotified) {
      final total = widget.turn.answer.characters.length;
      if (_revealedCharsCount.value < total) {
        _lastTick = Duration.zero;
        _ticker.start();
      } else {
        _finishedNotified = true;
        widget.onTypingFinished?.call();
      }
    }
  }

  @override
  void dispose() {
    if (widget.animate) {
      _ticker.dispose();
    }
    _revealedCharsCount.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / 1000000.0;
    _lastTick = elapsed;

    if (dt <= 0 || dt > 0.5) return;

    final totalChars = widget.turn.answer.characters.length;
    final currentRevealed = _revealedCharsCount.value;

    if (currentRevealed >= totalChars) {
      if (widget.turn.status == TurnStatus.done) {
        _ticker.stop();
        if (!_finishedNotified) {
          _finishedNotified = true;
          widget.onTypingFinished?.call();
        }
      }
      return;
    }

    // Smooth letter-by-letter typing calculation
    final backlog = totalChars - currentRevealed;
    // Natural human/assistant typing pace: ~48 chars per second (approx. 1 char every 20ms)
    double speed = 48.0;
    if (widget.turn.status == TurnStatus.done) {
      // Once stream is done, smoothly catch up the remaining backlog within ~1.2s max
      final neededSpeed = backlog / 1.2;
      if (neededSpeed > speed) speed = neededSpeed;
    } else if (backlog > 40) {
      // If the backend streams large chunks, smoothly accelerate so it reveals steadily letter by letter
      speed = (48.0 + (backlog - 40) * 1.5).clamp(48.0, 180.0);
    }

    _fractionalChars += speed * dt;
    final int toAdd = _fractionalChars.floor();
    if (toAdd > 0) {
      _fractionalChars -= toAdd;
      final nextCount = (currentRevealed + toAdd).clamp(0, totalChars);
      _revealedCharsCount.value = nextCount;

      if (nextCount >= totalChars && widget.turn.status == TurnStatus.done) {
        _ticker.stop();
        if (!_finishedNotified) {
          _finishedNotified = true;
          widget.onTypingFinished?.call();
        }
      }
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
        // If fragment is like '[' or '[1' without ']'
        if (RegExp(r'^\[\d*$').hasMatch(fragment)) {
          text = text.substring(0, lastOpen);
        }
      }
    }

    // 2. Virtual close of triple-backtick code fences
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
    switch (family) {
      case AnswerFontFamily.serif:
        return GoogleFonts.newsreader(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
        );
      case AnswerFontFamily.sans:
        return GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
        );
      case AnswerFontFamily.mono:
        return GoogleFonts.firaCode(
          fontSize: fontSize,
          fontWeight: fontWeight,
          height: height,
          color: color,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsNotifierProvider);
    final sourceUrls = widget.turn.sources.map((s) => s.url).toList();
    final baseSize = settings.answerFontSize;
    final fontFam = settings.answerFont;

    return ValueListenableBuilder<int>(
      valueListenable: _revealedCharsCount,
      builder: (context, count, _) {
        final fullCharacters = widget.turn.answer.characters;
        final totalCount = fullCharacters.length;
        final shownSubstring = count >= totalCount
            ? widget.turn.answer
            : fullCharacters.take(count).toString();

        final sanitizedText = _sanitizeMarkdown(shownSubstring);

        return MarkdownBody(
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
          styleSheet: MarkdownStyleSheet(
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
              fontSize: (baseSize * 0.85).clamp(11.0, 16.0),
              color: AppColors.textPrimary,
              backgroundColor: const Color(0xFF1B1D24),
            ),
            codeblockDecoration: const BoxDecoration(),
          ),
          extensionSet: md.ExtensionSet.gitHubFlavored,
        );
      },
    );
  }
}
