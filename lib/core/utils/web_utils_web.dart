import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

void removeLoadingSpinner() {
  final loader = web.document.querySelector('.loading');
  if (loader != null) {
    loader.remove();
  }
}

class WebUtils {
  /// Trigger a browser file download with [bytes] saved as [filename].
  static void downloadBytes(String filename, Uint8List bytes, String mimeType) {
    // Convert bytes to a JS object that the Blob constructor expects.
    final jsBytes = bytes.toJS;
    final parts = [jsBytes].toJS;
    
    final blob = web.Blob(
      parts,
      web.BlobPropertyBag(type: mimeType),
    );
    
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = filename;
    anchor.style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    
    // Delay revocation to ensure the browser has started the download
    Future.delayed(const Duration(milliseconds: 100), () {
      web.URL.revokeObjectURL(url);
      anchor.remove();
    });
  }

  /// Trigger a browser file download with [content] saved as [filename].
  static void downloadFile(String filename, String content) {
    final bytes = utf8.encode(content);
    downloadBytes(filename, Uint8List.fromList(bytes), 'text/plain');
  }
}
