import 'package:flutter/material.dart';
import 'package:curiosity/models/chat_models.dart';

/// Stub implementations for platforms that do not support web export.
Future<void> exportMarkdown(BuildContext context, Turn turn) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Export to Markdown is not supported on this platform.')),
  );
}

Future<void> exportPdf(BuildContext context, Turn turn) async {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Export to PDF is not supported on this platform.')),
  );
}
