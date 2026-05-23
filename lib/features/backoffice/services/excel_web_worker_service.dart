import 'dart:convert';
import 'dart:typed_data';
import 'package:isolate_manager/isolate_manager.dart';
import '../workers/excel_worker.dart';

/// Manages the background isolate/worker for Excel parsing.
/// Using IsolateManager ensures that heavy parsing tasks are offloaded 
/// to a separate thread (Isolate on mobile/desktop, Web Worker on Web).
final _excelManager = IsolateManager.create(
  excelParseWorker,
  workerName: 'excelParseWorker',
);

/// Parses an Excel file in a background thread using the isolate_manager package.
/// This prevents UI freezing while decoding large workbooks.
/// 
/// It uses the [excelParseWorker] defined in excel_worker.dart, which 
/// handles patching and decoding before returning a JSON string.
Future<List<Map<String, String>>> parseExcelInBackground(Uint8List fileBytes) async {
  try {
    print('Service: Calling background worker with ${fileBytes.length} bytes...');
    final String jsonResult = await _excelManager.compute(fileBytes);
    print('Service: Worker returned ${jsonResult.length} characters of JSON.');
    
    final List<dynamic> decoded = jsonDecode(jsonResult);
    return decoded.map((e) => Map<String, String>.from(e)).toList();
  } catch (e) {
    print('Service: Error in background parsing: $e');
    rethrow;
  }
}

