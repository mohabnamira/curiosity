import 'package:flutter/material.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:curiosity/utils/download_web.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Export the given turn as a Markdown file (web only).
Future<void> exportMarkdown(BuildContext context, Turn turn) async {
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

  downloadTextFile(
    'curiosity_${turn.id}.md',
    buffer.toString(),
    'text/markdown;charset=utf-8',
  );
}

/// Export the given turn as a PDF file (web only).
Future<void> exportPdf(BuildContext context, Turn turn) async {
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
      build: (ctx) => [
        pw.Header(level: 0, child: pw.Text('Curiosity Research Report')),
        pw.Paragraph(
          text: 'Question: ${turn.question}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        pw.SizedBox(height: 10),
        if (turn.sources.isNotEmpty) ...[
          pw.Text('Sources:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          ...turn.sources.asMap().entries.map(
                (entry) => pw.Bullet(
                  text: '${entry.key + 1}. ${entry.value.title} (${entry.value.url})',
                ),
              ),
          pw.SizedBox(height: 10),
        ],
        pw.Text('Answer:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        pw.Paragraph(text: turn.answer),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => doc.save(),
    name: 'curiosity_${turn.id}.pdf',
  );
}
