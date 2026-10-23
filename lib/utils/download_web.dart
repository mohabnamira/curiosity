import 'dart:js_interop';
import 'package:web/web.dart' as web;

void downloadTextFile(String filename, String content, String mimeType) {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: mimeType),
  );
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  link.click();
  web.URL.revokeObjectURL(url);
}
