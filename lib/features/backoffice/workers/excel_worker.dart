// ignore_for_file: depend_on_referenced_packages
import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as ex;
import 'package:isolate_manager/isolate_manager.dart';

// =============================================================================
// Excel Parse Worker
// =============================================================================
// Returns a JSON-encoded String instead of List<Map<String,String>> because
// Dart Maps compiled by dart2js are NOT plain JS objects and CANNOT be
// serialized through Web Worker postMessage (structured clone).
// A String is always safe across the worker boundary.
// =============================================================================

/// Parses an Excel file from raw bytes and returns a JSON-encoded string
/// containing a list of account maps.
///
/// Input : List<int> — raw file bytes
/// Output: String   — JSON-encoded List<Map<String,String>>
@pragma('vm:entry-point')
@isolateManagerWorker
String excelParseWorker(dynamic fileBytes) {
  // Safe cast: web worker structured-clone may deliver List<dynamic>
  // or a Uint8List natively depending on the browser/dart2js.
  final bytes = fileBytes is Uint8List 
      ? fileBytes 
      : Uint8List.fromList((fileBytes as List).map((e) => (e as num).toInt()).toList());

  // ── Step 1: Patch numFmtIds in xl/styles.xml ─────────────────────────
  Uint8List patchedBytes;
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final stylesFile = archive.findFile('xl/styles.xml');
    if (stylesFile != null) {
      final stylesXml = utf8.decode(stylesFile.content as List<int>);
      final Map<String, String> remapIds = {};
      int nextSafeId = 200;
      final numFmtPattern = RegExp(r'<numFmt[^>]+numFmtId="(\d+)"');
      for (final m in numFmtPattern.allMatches(stylesXml)) {
        final idStr = m.group(1)!;
        final id = int.parse(idStr);
        if (id < 164 && !remapIds.containsKey(idStr)) {
          remapIds[idStr] = '${nextSafeId++}';
        }
      }
      if (remapIds.isNotEmpty) {
        String patched = stylesXml;
        for (final e in remapIds.entries) {
          patched = patched.replaceAll('numFmtId="${e.key}"', 'numFmtId="${e.value}"');
        }
        final newArchive = Archive();
        for (final file in archive) {
          if (file.name == 'xl/styles.xml') {
            final b = utf8.encode(patched);
            newArchive.addFile(ArchiveFile('xl/styles.xml', b.length, b));
          } else {
            newArchive.addFile(file);
          }
        }
        final encoded = ZipEncoder().encode(newArchive);
        patchedBytes = encoded != null ? Uint8List.fromList(encoded) : bytes;
      } else {
        patchedBytes = bytes;
      }
    } else {
      patchedBytes = bytes;
    }
  } catch (_) {
    patchedBytes = bytes;
  }

  // ── Step 2: Decode Excel ──────────────────────────────────────────────
  final excel = ex.Excel.decodeBytes(patchedBytes);
  final List<Map<String, String>> results = [];

  for (final tableName in excel.tables.keys) {
    final sheet = excel.tables[tableName]!;
    if (sheet.maxRows < 2) continue;

    // ── Step 3: Map headers ───────────────────────────────────────────
    final Map<String, int> headerMap = {};
    for (int j = 0; j < sheet.rows[0].length; j++) {
      final cell = sheet.rows[0][j];
      if (cell?.value != null) {
        headerMap[cell!.value.toString().toLowerCase().trim()] = j;
      }
    }

    int idx(List<String> aliases) {
      for (final a in aliases) {
        if (headerMap.containsKey(a.toLowerCase())) return headerMap[a.toLowerCase()]!;
      }
      return -1;
    }

    final int iName    = idx(['name', 'customer name', 'customer', 'full name']);
    final int iMeter   = idx(['meter', 'meter number', 'meter no']);
    final int iAccount = idx(['account', 'account number', 'acc no', 'account no']);
    final int iSpn     = idx(['spn', 'spn number', 'spn no', 'consumption', 'kwh']);
    final int iFraud   = idx(['fraud', 'fraud status', 'fraud risk', 'fraud type']);
    final int iBills   = idx(['bills', 'total bills', 'no of bills', 'total amount', 'amount']);
    final int iPaid    = idx(['amount paid', 'paid amount', 'paid']);
    final int iFbs     = idx(['fraud bill status', 'fraud bill', 'bill status']);
    final int iBalance = idx(['balance', 'total balance', 'outstanding', 'outstanding balance']);
    final int iTariff  = idx(['tariff', 'tariff type', 'category']);
    final int iDate    = idx(['date', 'billing date', 'last billing date']);
    final int iSched   = idx(['scheduled date', 'scheduled', 'date scheduled']);
    final int iCreated = idx(['created date', 'created', 'date created', 'timestamp', 'created at']);
    final int iStatus  = idx(['status', 'billing status', 'payment status']);

    // ── Step 4: Convert rows ──────────────────────────────────────────
    for (int r = 1; r < sheet.maxRows; r++) {
      final row = sheet.rows[r];
      if (row.isEmpty) continue;

      String v(int col) {
        if (col < 0 || row.length <= col) return '—';
        final raw = row[col]?.value?.toString().trim() ?? '';
        return raw.isEmpty ? '—' : raw;
      }

      String n(String s) {
        if (s == '—') return '—';
        try {
          final only = s.replaceAll(RegExp(r'[^\d.-]'), '');
          if (only.isEmpty) return s;
          final d = double.parse(only);
          return d == d.toInt() ? d.toInt().toString() : d.toStringAsFixed(2);
        } catch (_) {
          return s;
        }
      }

      final String name = v(iName);
      final String initials = (name.isNotEmpty && name != '—')
          ? name.trim().split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).take(2).join().toUpperCase()
          : '??';

      results.add({
        'initials':          initials,
        'name':              name,
        'meter':             v(iMeter),
        'account':           v(iAccount),
        'consumption':       n(v(iSpn)),
        'fraud_status':      v(iFraud),
        'total_amount':      n(v(iBills)),
        'amount_paid':       n(v(iPaid)),
        'fraud_bill_status': v(iFbs),
        'balance':           n(v(iBalance)),
        'tariff':            v(iTariff),
        'date':              v(iDate),
        'scheduled':         v(iSched),
        'created_at':        v(iCreated),
        'status':            v(iStatus),
      });
    }
    break; // first non-empty sheet only
  }

  // Return as JSON string — the only type that survives structured-clone
  // serialization across a Web Worker postMessage boundary.
  return jsonEncode(results);
}
