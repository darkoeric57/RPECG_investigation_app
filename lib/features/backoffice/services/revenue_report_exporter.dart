import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel_plus/excel_plus.dart';
import '../domain/revenue_analysis.dart';

/// Exports a [RevenueAnalysisSummary] to CSV, PDF, or Excel.
class RevenueReportExporter {
  static final _currency = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
  static final _pct = NumberFormat('0.0#');

  // ── CSV ─────────────────────────────────────────────────────────────────────

  static Uint8List toCSV(RevenueAnalysisSummary summary) {
    final buf = StringBuffer();

    // Header
    buf.writeln(
      'Customer Name,Meter Number,Account Number,Total Amount,Amount Paid,'
      'Fraud Bill Status,Fraud Type,Outstanding Balance,Tariff,Settlement Status,Valid Account-Meter',
    );

    // Detail rows (one per AccountLedger)
    for (final ledger in summary.ledgers) {
      buf.writeln([
        _csv(ledger.customerName),
        _csv(ledger.meterNumber),
        _csv(ledger.accountNumber),
        ledger.totalBilled.toStringAsFixed(2),
        ledger.totalPaid.toStringAsFixed(2),
        _csv(ledger.fraudBillStatus),
        _csv(ledger.fraudType),
        ledger.netOutstanding.clamp(0.0, double.infinity).toStringAsFixed(2),
        _csv(ledger.tariff),
        _csv(ledger.settlementStatus),
        ledger.isAccountMeterValid ? 'Yes' : 'NO - MISMATCH',
      ].join(','));
    }

    // Summary block
    buf.writeln();
    buf.writeln('=== REVENUE ANALYSIS SUMMARY ===');
    buf.writeln('Generated At,${summary.generatedAt.toIso8601String()}');
    buf.writeln('Total Accounts,${summary.totalAccounts}');
    buf.writeln('Settled Accounts,${summary.settledAccounts}');
    buf.writeln('Outstanding Accounts,${summary.outstandingAccounts}');
    buf.writeln('Mismatch Accounts,${summary.mismatchAccounts}');
    buf.writeln('Grand Total Billed,${summary.grandTotalBilled.toStringAsFixed(2)}');
    buf.writeln('Grand Total Paid,${summary.grandTotalPaid.toStringAsFixed(2)}');
    buf.writeln('Grand Total Outstanding,${summary.grandTotalOutstanding.toStringAsFixed(2)}');
    buf.writeln('Collection Rate,${_pct.format(summary.collectionRate)}%');

    return Uint8List.fromList(utf8.encode(buf.toString()));
  }

  static String _csv(String value) => '"${value.replaceAll('"', '""')}"';

  // ── PDF ──────────────────────────────────────────────────────────────────────

  static Future<Uint8List> toPDF(RevenueAnalysisSummary summary) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(summary.generatedAt);

    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 7,
      color: PdfColors.white,
    );
    final cellStyle = pw.TextStyle(fontSize: 7);

    // Colour palette
    final headerBg = PdfColor.fromInt(0xFF1E3A8A);
    final settledColor = PdfColor.fromInt(0xFF10B981);
    final outstandingColor = PdfColor.fromInt(0xFFEF4444);
    final mismatchColor = PdfColor.fromInt(0xFFF59E0B);
    final oddRow = PdfColor.fromInt(0xFFF8FAFC);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: const pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.symmetric(horizontal: 30, vertical: 36),
        ),
        header: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'RPECG — Revenue Analysis Report',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 16,
                    color: headerBg,
                  ),
                ),
                pw.Text(dateStr, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
              ],
            ),
            pw.Divider(color: PdfColor.fromInt(0xFFE2E8F0)),
          ],
        ),
        build: (_) => [
          // KPI cards
          pw.Row(
            children: [
              _pdfKpi('Total Billed', _currency.format(summary.grandTotalBilled), headerBg),
              pw.SizedBox(width: 8),
              _pdfKpi('Total Collected', _currency.format(summary.grandTotalPaid), settledColor),
              pw.SizedBox(width: 8),
              _pdfKpi('Outstanding', _currency.format(summary.grandTotalOutstanding), outstandingColor),
              pw.SizedBox(width: 8),
              _pdfKpi('Collection Rate', '${_pct.format(summary.collectionRate)}%', settledColor),
            ],
          ),
          pw.SizedBox(height: 16),

          // Stats row
          pw.Row(
            children: [
              _pdfSmallKpi('Total Accounts', '${summary.totalAccounts}'),
              pw.SizedBox(width: 8),
              _pdfSmallKpi('Settled', '${summary.settledAccounts}'),
              pw.SizedBox(width: 8),
              _pdfSmallKpi('Outstanding', '${summary.outstandingAccounts}'),
              pw.SizedBox(width: 8),
              _pdfSmallKpi('Mismatches', '${summary.mismatchAccounts}'),
            ],
          ),
          pw.SizedBox(height: 20),

          // Data table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5), // Customer Name
              1: const pw.FlexColumnWidth(1.6), // Meter
              2: const pw.FlexColumnWidth(1.6), // Account
              3: const pw.FlexColumnWidth(1.5), // Total Amount
              4: const pw.FlexColumnWidth(1.5), // Amount Paid
              5: const pw.FlexColumnWidth(1.8), // Fraud Status
              6: const pw.FlexColumnWidth(1.8), // Fraud Type
              7: const pw.FlexColumnWidth(1.5), // Outstanding
              8: const pw.FlexColumnWidth(1.2), // Tariff
              9: const pw.FlexColumnWidth(1.2), // Status
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: headerBg),
                children: [
                  'Customer Name', 'Meter Number', 'Account Number', 'Total Amount',
                  'Amount Paid', 'Fraud Bill Status', 'Fraud Type', 'Outstanding',
                  'Tariff', 'Status',
                ].map((h) => _pdfHeaderCell(h, headerStyle)).toList(),
              ),
              // Data rows
              ...summary.ledgers.asMap().entries.map((e) {
                final i = e.key;
                final l = e.value;
                final isOdd = i.isOdd;
                PdfColor? rowBg;
                if (!l.isAccountMeterValid) {
                  rowBg = mismatchColor.shade(0.15);
                } else if (isOdd) {
                  rowBg = oddRow;
                }

                return pw.TableRow(
                  decoration: pw.BoxDecoration(color: rowBg),
                  children: [
                    l.customerName,
                    l.meterNumber,
                    l.accountNumber,
                    _currency.format(l.totalBilled),
                    _currency.format(l.totalPaid),
                    l.fraudBillStatus,
                    l.fraudType,
                    _currency.format(l.netOutstanding.clamp(0.0, double.infinity)),
                    l.tariff,
                    l.settlementStatus,
                  ].map((text) => _pdfCell(text, cellStyle)).toList(),
                );
              }),
            ],
          ),

          // Disclaimer
          pw.SizedBox(height: 20),
          pw.Text(
            'This report was auto-generated by the RPECG Revenue Analysis Engine. '
            'All figures are derived from imported billing data. Outstanding balances are rolled '
            'forward cumulatively across billing cycles per account.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfHeaderCell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 5),
      child: pw.Text(text, style: style),
    );
  }

  static pw.Widget _pdfCell(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(text, style: style),
    );
  }

  static pw.Widget _pdfKpi(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          color: color.shade(0.1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: color.shade(0.3), width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
            pw.SizedBox(height: 4),
            pw.Text(value,
                style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: color)),
          ],
        ),
      ),
    );
  }

  static pw.Widget _pdfSmallKpi(String label, String value) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.5),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          children: [
            pw.Text(value,
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF0F172A))),
            pw.SizedBox(height: 2),
            pw.Text(label,
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
      ),
    );
  }

  // ── Excel ────────────────────────────────────────────────────────────────────

  static Uint8List toExcel(RevenueAnalysisSummary summary) {
    final excel = Excel.createExcel();
    final sheet = excel['Revenue Analysis'];

    // Remove default sheet
    excel.delete('Sheet1');

    final headers = [
      'Customer Name', 'Meter Number', 'Account Number', 'Total Amount (GHS)',
      'Amount Paid (GHS)', 'Fraud Bill Status', 'Fraud Type', 'Outstanding Balance (GHS)',
      'Tariff', 'Settlement Status', 'Valid Account-Meter',
    ];

    // Header row styling
    for (var col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#1E3A8A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );
    }

    // Data rows
    for (var i = 0; i < summary.ledgers.length; i++) {
      final l = summary.ledgers[i];
      final row = i + 1;

      final bgHex = l.isSettled
          ? '#F0FDF4'
          : (!l.isAccountMeterValid ? '#FFFBEB' : (i.isOdd ? '#F8FAFC' : '#FFFFFF'));

      void writeCell(int col, CellValue val) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
        cell.value = val;
        cell.cellStyle = CellStyle(backgroundColorHex: ExcelColor.fromHexString(bgHex));
      }

      writeCell(0, TextCellValue(l.customerName));
      writeCell(1, TextCellValue(l.meterNumber));
      writeCell(2, TextCellValue(l.accountNumber));
      writeCell(3, DoubleCellValue(l.totalBilled));
      writeCell(4, DoubleCellValue(l.totalPaid));
      writeCell(5, TextCellValue(l.fraudBillStatus));
      writeCell(6, TextCellValue(l.fraudType));
      writeCell(7, DoubleCellValue(l.netOutstanding.clamp(0.0, double.infinity)));
      writeCell(8, TextCellValue(l.tariff));
      writeCell(9, TextCellValue(l.settlementStatus));
      writeCell(10, TextCellValue(l.isAccountMeterValid ? 'Yes' : 'MISMATCH'));
    }

    // Summary sheet
    final sumSheet = excel['Summary'];
    void sumRow(int row, String label, String value) {
      sumSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value =
          TextCellValue(label);
      sumSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value =
          TextCellValue(value);
    }

    sumRow(0, 'Generated At', summary.generatedAt.toIso8601String());
    sumRow(1, 'Total Accounts', '${summary.totalAccounts}');
    sumRow(2, 'Settled Accounts', '${summary.settledAccounts}');
    sumRow(3, 'Outstanding Accounts', '${summary.outstandingAccounts}');
    sumRow(4, 'Mismatch Accounts', '${summary.mismatchAccounts}');
    sumRow(5, 'Grand Total Billed (GHS)', summary.grandTotalBilled.toStringAsFixed(2));
    sumRow(6, 'Grand Total Paid (GHS)', summary.grandTotalPaid.toStringAsFixed(2));
    sumRow(7, 'Grand Total Outstanding (GHS)', summary.grandTotalOutstanding.toStringAsFixed(2));
    sumRow(8, 'Collection Rate', '${_pct.format(summary.collectionRate)}%');

    final bytes = excel.encode();
    return Uint8List.fromList(bytes ?? []);
  }
}
