import '../../meters/domain/meter.dart';
import 'revenue_analysis.dart';
import 'billing_account.dart';


enum ReportFrequency { weekly, monthly, custom }

enum ReportFormat { csv, pdf, excel }

enum ReportType { revenue, consumption, tariff }

class ReportConfig {
  final ReportType type;
  final ReportFrequency frequency;
  final DateTime startDate;
  final DateTime endDate;
  final List<TariffActivity> segments;
  final List<MeterStatus> statuses;
  final List<String> fraudTypes;
  final double? minKwh;
  final double? maxKwh;
  final ReportFormat format;
  final List<String> recipients;

  ReportConfig({
    required this.type,
    required this.frequency,
    required this.startDate,
    required this.endDate,
    required this.segments,
    required this.statuses,
    required this.fraudTypes,
    this.minKwh,
    this.maxKwh,
    required this.format,
    required this.recipients,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'frequency': frequency.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'segments': segments.map((s) => s.name).toList(),
      'statuses': statuses.map((s) => s.name).toList(),
      'fraudTypes': fraudTypes,
      'minKwh': minKwh,
      'maxKwh': maxKwh,
      'format': format.name,
      'recipients': recipients,
    };
  }

  factory ReportConfig.fromJson(Map<String, dynamic> json) {
    return ReportConfig(
      type: ReportType.values.firstWhere((e) => e.name == json['type']),
      frequency: ReportFrequency.values.firstWhere((e) => e.name == json['frequency']),
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      segments: (json['segments'] as List).map((s) => TariffActivity.values.firstWhere((e) => e.name == s)).toList(),
      statuses: (json['statuses'] as List).map((s) => MeterStatus.values.firstWhere((e) => e.name == s)).toList(),
      fraudTypes: json['fraudTypes'] != null ? List<String>.from(json['fraudTypes']) : const [],
      minKwh: json['minKwh'],
      maxKwh: json['maxKwh'],
      format: ReportFormat.values.firstWhere((e) => e.name == json['format']),
      recipients: List<String>.from(json['recipients']),
    );
  }
}

class ReportData {
  final ReportType type;
  final List<Meter> meters;
  final double totalConsumption;
  final Map<MeterStatus, int> statusCounts;
  final Map<TariffActivity, int> segmentCounts;
  final DateTime generatedAt;
  final List<BillingAccount>? revenueRows;
  final RevenueAnalysisSummary? revenueSummary;

  ReportData({
    required this.type,
    required this.meters,
    required this.totalConsumption,
    required this.statusCounts,
    required this.segmentCounts,
    required this.generatedAt,
    this.revenueRows,
    this.revenueSummary,
  });
}
