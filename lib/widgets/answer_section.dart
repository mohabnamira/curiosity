import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';

class CodeBlockWidget extends StatefulWidget {
  final String code;

  const CodeBlockWidget({super.key, required this.code});

  @override
  State<CodeBlockWidget> createState() => _CodeBlockWidgetState();
}

class _CodeBlockWidgetState extends State<CodeBlockWidget> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    setState(() {
      _copied = true;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _copied = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: _copy,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _copied ? Icons.check : Icons.copy_rounded,
                        size: 14,
                        color: _copied ? Colors.greenAccent : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? 'Copied' : 'Copy',
                        style: TextStyle(
                          fontSize: 12,
                          color: _copied ? Colors.greenAccent : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                widget.code,
                style: GoogleFonts.firaCode(
                  fontSize: 13,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return CodeBlockWidget(code: element.textContent);
  }
}

class AnswerSection extends ConsumerStatefulWidget {
  const AnswerSection({super.key});

  @override
  ConsumerState<AnswerSection> createState() => _AnswerSectionState();
}

class _AnswerSectionState extends ConsumerState<AnswerSection> with SingleTickerProviderStateMixin {
  late final AnimationController _glowController;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final turn = ref.watch(chatNotifierProvider.select((s) => s.activeTurn));
    final rawAnswer = turn?.answer ?? '';
    final status = turn?.status;
    final isInFlight = turn?.isInFlight ?? false;

    final answer = rawAnswer.replaceAllMapped(
      RegExp(r'\[(\d+)\]'),
      (match) => '[${match.group(1)}](#citation-${match.group(1)})',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Curiosity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isInFlight
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.25 * _glowAnimation.value),
                          blurRadius: 12 + (8 * _glowAnimation.value),
                          spreadRadius: 2,
                        )
                      ]
                    : [],
                border: Border.all(
                  color: isInFlight
                      ? Colors.blue.withOpacity(0.4 + (0.4 * _glowAnimation.value))
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: child,
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (answer.isNotEmpty)
                MarkdownBody(
                  data: answer,
                  builders: {
                    'pre': CodeBlockBuilder(),
                  },
                  onTapLink: (text, href, title) {
                    if (href != null && href.startsWith('#citation-')) {
                      final indexStr = href.replaceFirst('#citation-', '');
                      final index = int.tryParse(indexStr);
                      if (index != null) {
                        ref.read(chatNotifierProvider.notifier).setHighlightedSource(index - 1);
                      }
                    }
                  },
                  styleSheet: MarkdownStyleSheet(
                    code: GoogleFonts.firaCode(
                      fontSize: 13,
                      color: Colors.white70,
                      backgroundColor: Colors.grey.shade900,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    a: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      backgroundColor: Colors.blue,
                      fontSize: 11,
                    ),
                  ),
                )
              else if (turn != null && turn.isInFlight)
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.submitButton,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Generating answer...',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                )
              else if (status == TurnStatus.done)
                const Text(
                  'No answer was generated.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              if (status == TurnStatus.error)
                Text(
                  'Error: ${turn?.errorMessage ?? "Failed to generate answer"}',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                ),
            ],
          ),
        ),
      ],
    );
  }
}