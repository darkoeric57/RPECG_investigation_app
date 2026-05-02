// ignore: avoid_web_libraries_in_flutter
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Parses an Excel file in a native browser Web Worker using SheetJS.
///
/// The worker runs on a completely separate OS thread — the Flutter UI
/// is 100% free while parsing. Falls back to null on non-web platforms.
///
/// Returns a [List<Map<String,String>>] on success, throws on failure.
Future<List<Map<String, String>>> parseExcelInWorker(
  Uint8List fileBytes, {
  void Function(String message)? onProgress,
}) async {
  if (!kIsWeb) {
    throw UnsupportedError('parseExcelInWorker is only supported on Flutter Web.');
  }

  onProgress?.call('Starting background worker...');

  final completer = Completer<List<Map<String, String>>>();

  // Create the native browser Web Worker pointing to our JS file.
  // The worker file is served alongside the Flutter app in the web/ folder.
  final worker = html.Worker('excel_parser_worker.js');

  // Listen for the result message from the worker.
  worker.onMessage.listen((html.MessageEvent event) {
    try {
      final Map<String, dynamic> response = jsonDecode(event.data as String);

      if (response['success'] == true) {
        final List<dynamic> rawList = response['data'] as List<dynamic>;
        final List<Map<String, String>> accounts = rawList
            .map((e) => Map<String, String>.from(e as Map))
            .toList();
        completer.complete(accounts);
      } else {
        completer.completeError(
          Exception('Worker error: ${response['error']}'),
        );
      }
    } catch (e) {
      completer.completeError(Exception('Failed to decode worker response: $e'));
    } finally {
      worker.terminate(); // Always clean up the worker thread.
    }
  });

  // Listen for any worker-level errors (script load failures, etc.).
  worker.onError.listen((html.Event event) {
    worker.terminate();
    completer.completeError(
      Exception('Web Worker encountered an error. Check that excel_parser_worker.js is accessible.'),
    );
  });

  // Transfer the file bytes to the worker as an ArrayBuffer.
  // Using transferable objects moves memory ownership to the worker
  // without copying — this is the most efficient way to send large files.
  onProgress?.call('Transferring file to worker...');
  final jsBuffer = fileBytes.buffer;
  worker.postMessage(jsBuffer, [jsBuffer]);

  onProgress?.call('Parsing Excel file in background...');
  return completer.future;
}
