import 'package:curiosity/utils/toast.dart';
import 'package:flutter/material.dart';
import 'package:curiosity/models/chat_models.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

/// Export the given turn as Markdown (mobile/desktop fallback via Share).
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

  try {
    await SharePlus.instance.share(
      ShareParams(
        text: buffer.toString(),
        title: 'Curiosity - ${turn.question}',
      ),
    );
  } catch (e) {
    if (context.mounted) {
      showToast(context, 'Failed to share: $e', icon: Icons.error_outline);
    }
  }
}

/// Export the given turn as a PDF file using the printing plugin.
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
