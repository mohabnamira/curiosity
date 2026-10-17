import 'dart:js_interop';
import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web/web.dart' as web;
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/providers/chat_provider.dart';
import 'package:curiosity/theme/colors.dart';
import 'package:curiosity/widgets/glow_border.dart';

final _codeOrCitation = RegExp(r'(```[\s\S]*?(?:```|$)|`[^`\n]*`)|\[(\d+)\](?!\()');

String linkifyCitations(String text, int sourceCount) {
  return text.replaceAllMapped(_codeOrCitation, (m) {
    if (m.group(1) != null) return m.group(0)!;
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

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();


  String? _highlightTurnId;
  int? _highlightIndex;

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _highlight(String turnId, int index) {
    setState(() {
      _highlightTurnId = turnId;
      _highlightIndex = index;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _submit() {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;
    _queryController.clear();
    ref.read(chatNotifierProvider.notifier).sendQuery(query);
  }

  Future<void> _openSourceUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _copyAnswer(String answer) async {
    await Clipboard.setData(ClipboardData(text: answer));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Answer copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  void _exportMarkdown(Turn turn) {
    final buffer = StringBuffer();
    buffer.writeln('# Question: ${turn.question}');
    buffer.writeln();
    if (turn.sources.isNotEmpty) {
      buffer.writeln('## Sources');
      for (int i = 0; i < turn.sources.length; i++) {
        buffer.writeln('${i + 1}. [${turn.sources[i].title}](${turn.sources[i].url})');
      }
      buffer.writeln();
    }
    buffer.writeln('## Answer');
    buffer.writeln(turn.answer);

    final blob = web.Blob(
      [buffer.toString().toJS].toJS,
      web.BlobPropertyBag(type: 'text/markdown;charset=utf-8'),
    );
    final url = web.URL.createObjectURL(blob);
    final link = web.HTMLAnchorElement()
      ..href = url
      ..download = 'curiosity_${turn.id}.md';
    link.click();
    web.URL.revokeObjectURL(url);
  }

  Future<void> _exportPdf(Turn turn) async {

    pw.ThemeData? theme;
    try {
      theme = pw.ThemeData.withFont(
        base: await PdfGoogleFonts.notoSansRegular(),
        bold: await PdfGoogleFonts.notoSansBold(),
      );
    } catch (_) {}

    final doc = pw.Document(theme: theme);
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Curiosity Research Report')),
          pw.Paragraph(
            text: 'Question: ${turn.question}',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          if (turn.sources.isNotEmpty) ...[
            pw.Text('Sources:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ...turn.sources.asMap().entries.map(
                  (e) => pw.Bullet(text: '${e.key + 1}. ${e.value.title} (${e.value.url})'),
                ),
            pw.SizedBox(height: 10),
          ],
          pw.Text('Answer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Paragraph(text: turn.answer),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'curiosity_${turn.id}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final turns = ref.watch(chatNotifierProvider.select((s) => s.turns));
    final hasInFlight = turns.any((t) => t.isInFlight);

    // Scroll when a turn is added, not on every streamed chunk.
    ref.listen(
      chatNotifierProvider.select((s) => s.turns.length),
      (_, _) => _scrollToBottom(),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Curiosity',
          style: GoogleFonts.ibmPlexMono(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: turns.length,
              itemBuilder: (context, index) {
                final turn = turns[index];
                final answerText = linkifyCitations(turn.answer, turn.sources.length);
                final highlightedIndex = _highlightTurnId == turn.id ? _highlightIndex : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade800),
                        ),
                        child: Text(
                          turn.question,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (turn.sources.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(Icons.source_outlined, color: Colors.white70, size: 16),
                            SizedBox(width: 8),
                            Text(
                              'Sources',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,

                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse},
                            ),
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: turn.sources.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, sIndex) {
                                final source = turn.sources[sIndex];
                                final highlighted = highlightedIndex == sIndex;
                                return InkWell(
                                  onTap: () {
                                    _highlight(turn.id, sIndex);
                                    _openSourceUrl(source.url);
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    width: 160,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.cardColor,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: highlighted ? Colors.blue.shade400 : Colors.grey.shade800,
                                        width: highlighted ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          '${sIndex + 1}. ${source.title}',
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          source.url,
                                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ] else if (turn.status == TurnStatus.searching) ...[
                        const Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.submitButton),
                            ),
                            SizedBox(width: 8),
                            Text('Searching web sources...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        children: [
                          const Text(
                            'Curiosity',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                          const Spacer(),
                          if (turn.status == TurnStatus.done && turn.answer.isNotEmpty) ...[
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                              tooltip: 'Copy Answer',
                              onPressed: () => _copyAnswer(turn.answer),
                            ),
                            IconButton(
                              icon: const Icon(Icons.code, size: 16, color: Colors.grey),
                              tooltip: 'Export Markdown',
                              onPressed: () => _exportMarkdown(turn),
                            ),
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Colors.grey),
                              tooltip: 'Export PDF',
                              onPressed: () => _exportPdf(turn),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (answerText.isNotEmpty)
                        MarkdownBody(
                          data: answerText,
                          builders: {'pre': CodeBlockBuilder()},
                          onTapLink: (text, href, title) {
                            if (href == null || !href.startsWith('#citation-')) return;
                            final n = int.tryParse(href.substring('#citation-'.length));
                            if (n != null) _highlight(turn.id, n - 1);
                          },
                          styleSheet: MarkdownStyleSheet(
                            code: GoogleFonts.firaCode(
                              fontSize: 13,
                              color: Colors.white70,
                              backgroundColor: Colors.grey.shade900,
                            ),
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
                      else if (turn.isInFlight)
                        const Row(
                          children: [
                            SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.submitButton),
                            ),
                            SizedBox(width: 8),
                            Text('Generating answer...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ],
                        )
                      else if (turn.status == TurnStatus.done)
                        const Text('No answer was generated.', style: TextStyle(color: Colors.grey, fontSize: 13))
                      else if (turn.status == TurnStatus.error)
                        Text('Error: ${turn.errorMessage ?? "Failed"}', style: const TextStyle(color: Colors.redAccent, fontSize: 13)),

                      if (turn.status == TurnStatus.done && turn.relatedQuestions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: turn.relatedQuestions.map((q) {
                            return ActionChip(
                              backgroundColor: AppColors.cardColor,
                              side: BorderSide(color: Colors.grey.shade800),
                              label: Text(q, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                              onPressed: () => ref.read(chatNotifierProvider.notifier).sendQuery(q),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.sideNav,
            child: GlowBorder(
              active: hasInFlight,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.searchBar,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.searchBarBorder, width: 1.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: TextField(
                          controller: _queryController,
                          onSubmitted: (_) => _submit(),
                          decoration: const InputDecoration(
                            hintText: 'Ask a follow-up...',
                            hintStyle: TextStyle(color: AppColors.textGrey, fontSize: 15),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _submit,
                      icon: const Icon(Icons.arrow_forward, color: AppColors.submitButton),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}