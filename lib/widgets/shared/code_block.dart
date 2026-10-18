import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:markdown/markdown.dart' as md;

/// Regular expression to detect code blocks or citations like [1]
final _codeOrCitation = RegExp(r'(```[\s\S]*?(?:```|$)|`[^`\n]*`)|\[(\d+)\](?!\()');

/// Replace citation placeholders with markdown links to the citation anchors.
String linkifyCitations(String text, int sourceCount) {
  return text.replaceAllMapped(_codeOrCitation, (m) {
    // If it's a code block or inline code, leave untouched.
    if (m.group(1) != null) return m.group(0)!;
    final n = int.tryParse(m.group(2)!);
    if (n == null || n < 1 || n > sourceCount) return m.group(0)!;
    return '[$n](#citation-$n)';
  });
}

/// Widget that displays a formatted code block with a copy button.
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
    final color = _copied ? Colors.white : AppColors.iconMuted;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1B1D24),
              borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: _copy,
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _copied ? Icons.check_rounded : Icons.copy_rounded,
                          size: 13,
                          color: color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _copied ? 'Copied' : 'Copy',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text(
                widget.code,
                style: GoogleFonts.firaCode(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Markdown builder that renders fenced code blocks using [CodeBlockWidget].
class CodeBlockBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return CodeBlockWidget(code: element.textContent.trimRight());
  }
}
