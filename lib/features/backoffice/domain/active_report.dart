import 'report_config.dart';

enum ActiveReportStatus {
  scheduled,
  processing,
  draftReady,
  approved,
  cancelled,
}

class ActiveReport {
  final String id;
  final String title;
  final String category;
  final double progress;
  final ActiveReportStatus status;
  final ReportConfig config;
  final DateTime createdAt;

  ActiveReport({
    required this.id,
    required this.title,
    required this.category,
    this.progress = 0.0,
    this.status = ActiveReportStatus.scheduled,
    required this.config,
    required this.createdAt,
  });

  ActiveReport copyWith({
    String? title,
    String? category,
    double? progress,
    ActiveReportStatus? status,
  }) {
    return ActiveReport(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      config: config,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'progress': progress,
      'status': status.name,
      'config': config.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ActiveReport.fromJson(Map<String, dynamic> json) {
    return ActiveReport(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      progress: json['progress'].toDouble(),
      status: ActiveReportStatus.values.firstWhere((e) => e.name == json['status']),
      config: ReportConfig.fromJson(json['config']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
