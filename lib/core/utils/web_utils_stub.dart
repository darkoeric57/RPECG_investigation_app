import 'dart:typed_data';

void removeLoadingSpinner() {}

// No-op for non-web — stub so the app compiles everywhere
class WebUtils {
  static void downloadFile(String filename, String content) {}
  static void downloadBytes(String filename, Uint8List bytes, String mimeType) {}
}
