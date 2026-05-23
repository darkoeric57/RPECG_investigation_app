import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel_plus/excel_plus.dart';
import '../domain/report_config.dart';
import '../../meters/domain/meter.dart';
import '../../meters/data/meter_repository.dart';
import '../../../core/services/firebase_data_service.dart';
import '../domain/revenue_analysis.dart';
import 'revenue_analysis_engine.dart';
import 'revenue_report_exporter.dart';

class ReportService {
  final MeterRepository _repository;
  final FirestoreDataService _firestoreDataService;

  ReportService(this._repository, this._firestoreDataService);

  DateTime? _parseDate(String dateStr) {
    final trimmed = dateStr.trim();
    if (trimmed.isEmpty) return null;

    final formats = [
      DateFormat('dd/MM/yyyy HH:mm'),
      DateFormat('dd/MM/yyyy HH:mm:ss'),
      DateFormat('MM/dd/yyyy HH:mm'),
      DateFormat('MM/dd/yyyy HH:mm:ss'),
      DateFormat('yyyy-MM-dd HH:mm:ss'),
      DateFormat('yyyy-MM-dd HH:mm'),
      DateFormat('dd MMM yyyy HH:mm'),
      DateFormat('d MMM yyyy HH:mm'),
      DateFormat('dd MMM yyyy'),
      DateFormat('d MMM yyyy'),
      DateFormat('dd/MM/yyyy'),
      DateFormat('MM/dd/yyyy'),
      DateFormat('yyyy-MM-dd'),
    ];
    for (final fmt in formats) {
      try {
        return fmt.parse(trimmed);
      } catch (_) {}
    }

    try {
      final parts = trimmed.split(' ');
      if (parts.isNotEmpty) {
        final datePart = parts[0];
        for (final fmt in [DateFormat('dd/MM/yyyy'), DateFormat('MM/dd/yyyy'), DateFormat('yyyy-MM-dd')]) {
          try {
            return fmt.parse(datePart);
          } catch (_) {}
        }
      }
    } catch (_) {}

    try {
      return DateTime.parse(trimmed);
    } catch (_) {
      return null;
    }
  }

  Future<ReportData> processData(ReportConfig config) async {
    if (config.type == ReportType.revenue ||
        config.type == ReportType.consumption ||
        config.type == ReportType.tariff) {
      final allAccounts = await _firestoreDataService.getBillingAccounts();
      final filteredAccounts = allAccounts.where((account) {
        // 1. Date Filtering
        final parsedDate = _parseDate(account.createdAt);
        final importedDate = account.importedAt;

        final start = DateTime(
            config.startDate.year, config.startDate.month, config.startDate.day);
        final end = DateTime(config.endDate.year, config.endDate.month,
            config.endDate.day, 23, 59, 59);

        bool dateMatches = false;
        bool hasDate = false;

        if (parsedDate != null) {
          hasDate = true;
          if (!parsedDate.isBefore(start) && !parsedDate.isAfter(end)) {
            dateMatches = true;
          }
        }
        if (importedDate != null) {
          hasDate = true;
          if (!importedDate.isBefore(start) && !importedDate.isAfter(end)) {
            dateMatches = true;
          }
        }

        if (hasDate && !dateMatches) {
          return false;
        }

        // 2. Segment Filtering
        if (config.segments.isNotEmpty) {
          final tariffClean = account.tariff.toLowerCase().replaceAll(' ', '').replaceAll('-', '');
          bool matchesSegment = false;
          for (final segment in config.segments) {
            if (segment == TariffActivity.residential) {
              if (tariffClean.contains('residential') &&
                  !tariffClean.contains('nonresidential')) {
                matchesSegment = true;
                break;
              }
            } else if (segment == TariffActivity.commercial) {
              if (tariffClean.contains('commercial') ||
                  tariffClean.contains('nonresidential')) {
                matchesSegment = true;
                break;
              }
            } else if (segment == TariffActivity.industrial) {
              if (tariffClean.contains('industrial')) {
                matchesSegment = true;
                break;
              }
            }
          }
          if (!matchesSegment) return false;
        }

        // 3. Status Filtering
        if (config.statuses.isNotEmpty) {
          final fraudStatusLower = account.fraudBillStatus.toLowerCase();
          final statusLower = account.status.toLowerCase();
          bool matchesStatus = false;
          for (final status in config.statuses) {
            final target = status.name.toLowerCase();
            if (target == 'paid' && (fraudStatusLower == 'paid' || statusLower == 'paid')) {
              matchesStatus = true;
              break;
            } else if (target == 'pending' && (fraudStatusLower == 'pending' || statusLower == 'pending')) {
              matchesStatus = true;
              break;
            } else if (target == 'billed' &&
                (fraudStatusLower == 'billed' ||
                    fraudStatusLower == 'overdue' ||
                    fraudStatusLower == 'due' ||
                    statusLower == 'billed' ||
                    statusLower == 'overdue' ||
                    statusLower == 'due')) {
              matchesStatus = true;
              break;
            } else if (target == 'scheduled' && (fraudStatusLower == 'scheduled' || statusLower == 'scheduled')) {
              matchesStatus = true;
              break;
            }
          }
          if (!matchesStatus) return false;
        }

        // 4. Consumption Filtering
        if (config.minKwh != null || config.maxKwh != null) {
          final match = RegExp(r'\d+').firstMatch(account.consumption);
          if (match != null) {
            final kwh = double.tryParse(match.group(0)!);
            if (kwh != null) {
              if (config.minKwh != null && kwh < config.minKwh!) return false;
              if (config.maxKwh != null && kwh > config.maxKwh!) return false;
            }
          }
        }

        // 5. Fraud Type Filtering
        if (config.fraudTypes.isNotEmpty) {
          final accountFraudLower = account.fraudStatus.toLowerCase().trim();
          bool matchesFraud = false;
          for (final fType in config.fraudTypes) {
            if (accountFraudLower == fType.toLowerCase().trim()) {
              matchesFraud = true;
              break;
            }
          }
          if (!matchesFraud) return false;
        }

        return true;
      }).toList();

      final rawRows = filteredAccounts.map<Map<String, String>>((account) {
        return <String, String>{
          'METER NUMBER': account.meter,
          'ACCOUNT NUMBER': account.account,
          'TOTAL AMOUNT': account.totalAmount,
          'AMOUNT PAID': account.amountPaid,
          'FRAUD BILL STATUS': account.fraudBillStatus,
          'FRAUD STATUS': account.fraudStatus,
          'TARIFF': account.tariff,
          'CUSTOMER NAME': account.name,
          'DATE': account.createdAt,
          'CONSUMPTION': account.consumption,
        };
      }).toList();

      final summary = const RevenueAnalysisEngine().run(rawRows);

      return ReportData(
        type: config.type,
        meters: [],
        totalConsumption: 0.0,
        statusCounts: {},
        segmentCounts: {},
        generatedAt: DateTime.now(),
        revenueRows: filteredAccounts,
        revenueSummary: summary,
      );
    }

    final allMeters = await _repository.getMeters();
    
    // Filtering logic
    final filteredMeters = allMeters.where((m) {
      // Date Filter (using installationDate, inclusive bounds)
      final start = DateTime(
          config.startDate.year, config.startDate.month, config.startDate.day);
      final end = DateTime(config.endDate.year, config.endDate.month,
          config.endDate.day, 23, 59, 59);
      final withinDate = !m.installationDate.isBefore(start) && !m.installationDate.isAfter(end);
      
      // Segment Filter
      final matchesSegment = config.segments.isEmpty || config.segments.contains(m.tariffActivity);
      
      // Status Filter
      final matchesStatus = config.statuses.isEmpty || config.statuses.contains(m.status);
      
      // Consumption Filter
      double consumption = 0.0;
      if (m.initialReadings != null) {
        consumption = double.tryParse(m.initialReadings!) ?? 0.0;
      }
      final matchesConsumption = (config.minKwh == null || consumption >= config.minKwh!) &&
                                 (config.maxKwh == null || consumption <= config.maxKwh!);

      return withinDate && matchesSegment && matchesStatus && matchesConsumption;
    }).toList();

    // Aggregation
    double totalConsumption = 0.0;
    Map<MeterStatus, int> statusCounts = {};
    Map<TariffActivity, int> segmentCounts = {};

    for (var m in filteredMeters) {
      double consumption = double.tryParse(m.initialReadings ?? '0') ?? 0.0;
      totalConsumption += consumption;
      
      statusCounts[m.status] = (statusCounts[m.status] ?? 0) + 1;
      segmentCounts[m.tariffActivity] = (segmentCounts[m.tariffActivity] ?? 0) + 1;
    }

    return ReportData(
      type: config.type,
      meters: filteredMeters,
      totalConsumption: totalConsumption,
      statusCounts: statusCounts,
      segmentCounts: segmentCounts,
      generatedAt: DateTime.now(),
    );
  }

  Future<Uint8List> generateFile(ReportData data, ReportFormat format) async {
    if (data.type == ReportType.revenue) {
      final summary = data.revenueSummary ?? RevenueAnalysisSummary(ledgers: [], generatedAt: DateTime.now());
      switch (format) {
        case ReportFormat.csv:
          return RevenueReportExporter.toCSV(summary);
        case ReportFormat.pdf:
          return RevenueReportExporter.toPDF(summary);
        case ReportFormat.excel:
          return RevenueReportExporter.toExcel(summary);
      }
    } else if (data.type == ReportType.consumption) {
      final summary = data.revenueSummary ?? RevenueAnalysisSummary(ledgers: [], generatedAt: DateTime.now());
      switch (format) {
        case ReportFormat.csv:
          return RevenueReportExporter.toConsumptionCSV(summary);
        case ReportFormat.pdf:
          return RevenueReportExporter.toConsumptionPDF(summary);
        case ReportFormat.excel:
          return RevenueReportExporter.toConsumptionExcel(summary);
      }
    } else if (data.type == ReportType.tariff) {
      final summary = data.revenueSummary ?? RevenueAnalysisSummary(ledgers: [], generatedAt: DateTime.now());
      switch (format) {
        case ReportFormat.csv:
          return RevenueReportExporter.toTariffCSV(summary);
        case ReportFormat.pdf:
          return RevenueReportExporter.toTariffPDF(summary);
        case ReportFormat.excel:
          return RevenueReportExporter.toTariffExcel(summary);
      }
    }

    switch (format) {
      case ReportFormat.csv:
        return _generateCSV(data);
      case ReportFormat.pdf:
        return _generatePDF(data);
      case ReportFormat.excel:
        return _generateExcel(data);
    }
  }

  Uint8List _generateCSV(ReportData data) {
    final buffer = StringBuffer();
    buffer.writeln('Meter ID,Customer,Status,Activity,Consumption(kWh),Date');
    
    for (var m in data.meters) {
      final consumption = m.initialReadings ?? '0';
      final date = DateFormat('yyyy-MM-dd').format(m.installationDate);
      buffer.writeln('${m.id},"${m.customerName}",${m.status.name},${m.tariffActivity.name},$consumption,$date');
    }
    
    // Add summary
    buffer.writeln();
    buffer.writeln('SUMMARY');
    buffer.writeln('Total Meters,${data.meters.length}');
    buffer.writeln('Total Consumption,${data.totalConsumption.toStringAsFixed(2)}');
    
    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  Future<Uint8List> _generatePDF(ReportData data) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(data.generatedAt);

    pdf.addPage(
      pw.MultiPage(
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('RPECG - Analytical Report', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
            pw.Text(dateStr),
          ],
        ),
        build: (context) => [
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'Executive Summary'),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _pdfStatCard('Total Meters', data.meters.length.toString()),
              _pdfStatCard('Total Consumption', '${data.totalConsumption.toStringAsFixed(1)} kWh'),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'Breakdown by Status'),
          pw.TableHelper.fromTextArray(
            headers: ['Status', 'Count'],
            data: data.statusCounts.entries.map((e) => [e.key.name.toUpperCase(), e.value.toString()]).toList(),
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, text: 'Detailed List'),
          pw.TableHelper.fromTextArray(
            headers: ['Meter ID', 'Customer', 'Status', 'Consumption'],
            data: data.meters.map((m) => [
              m.id,
              m.customerName,
              m.status.name,
              m.initialReadings ?? '0'
            ]).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _pdfStatCard(String label, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text(value, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  Future<Uint8List> _generateExcel(ReportData data) async {
    final excel = Excel.createExcel();
    final sheet = excel['Report'];

    // Set Headers
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0)).value = TextCellValue('Meter ID');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 0)).value = TextCellValue('Customer Name');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: 0)).value = TextCellValue('Status');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: 0)).value = TextCellValue('Activity');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: 0)).value = TextCellValue('Consumption (kWh)');

    // Set Data
    for (var i = 0; i < data.meters.length; i++) {
      final m = data.meters[i];
      final rowIndex = i + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value = TextCellValue(m.id);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value = TextCellValue(m.customerName);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value = TextCellValue(m.status.name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex)).value = TextCellValue(m.tariffActivity.name);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex)).value = DoubleCellValue(double.tryParse(m.initialReadings ?? '0') ?? 0.0);
    }

    final bytes = excel.encode();
    return Uint8List.fromList(bytes!);
  }

  Future<void> simulateEmailDispatch(String title, List<String> recipients) async {
    // Simulating network latency for email sending
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('SIMULATION: Sending report "$title" to ${recipients.join(", ")}');
  }
}
