import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/glow_border.dart';

/// Matches code (fenced or inline) OR a citation like [3].
/// Code is matched first so we can leave it untouched.
final _codeOrCitation = RegExp(r'(```[\s\S]*?(?:```|$)|`[^`\n]*`)|\[(\d+)\](?!\()');

/// Turns valid [n] citations into markdown links "[n](#citation-n)".
/// Citations inside code, or without a matching source, stay as plain text.
String linkifyCitations(String text, int sourceCount) {
  return text.replaceAllMapped(_codeOrCitation, (m) {
    if (m.group(1) != null) return m.group(0)!; // code: leave as is
    final n = int.tryParse(m.group(2)!);
    if (n == null || n < 1 || n > sourceCount) return m.group(0)!;
    return '[$n](#citation-$n)';
  });
}

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
    if (!mounted) return;
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = _copied ? Colors.greenAccent : Colors.grey.shade400;
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
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
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
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _copied ? 'Copied' : 'Copy',
                        style: TextStyle(fontSize: 12, color: color),
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
                style: GoogleFonts.firaCode(fontSize: 13, color: Colors.white),
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
    return CodeBlockWidget(code: element.textContent.trimRight());
  }
}

class AnswerSection extends ConsumerWidget {
  const AnswerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final turn = ref.watch(chatNotifierProvider.select((s) => s.activeTurn));
    final status = turn?.status;
    final answer = linkifyCitations(
      turn?.answer ?? '',
      turn?.sources.length ?? 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Curiosity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GlowBorder(
          active: status == TurnStatus.generating,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (answer.isNotEmpty)
                MarkdownBody(
                  data: answer,
                  builders: {'pre': CodeBlockBuilder()},
                  onTapLink: (text, href, title) {
                    if (href == null || !href.startsWith('#citation-')) return;
                    final n = int.tryParse(href.substring('#citation-'.length));
                    if (n != null) {
                      ref
                          .read(chatNotifierProvider.notifier)
                          .setHighlightedSource(n - 1);
                    }
                  },
                  styleSheet: MarkdownStyleSheet(
                    code: GoogleFonts.firaCode(
                      fontSize: 13,
                      color: Colors.white70,
                      backgroundColor: Colors.grey.shade900,
                    ),
                    // Our CodeBlockWidget draws the card, so the package
                    // must not draw a second one around it.
                    codeblockDecoration: const BoxDecoration(),
                    codeblockPadding: EdgeInsets.zero,
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