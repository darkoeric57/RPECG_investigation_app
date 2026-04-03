import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

void removeLoadingSpinner() {
  final loader = web.document.querySelector('.loading');
  if (loader != null) {
    loader.remove();
  }
}

class WebUtils {
  /// Trigger a browser file download with [content] saved as [filename].
  static void downloadFile(String filename, String content) {
    final bytes = utf8.encode(content);
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'text/plain'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}
