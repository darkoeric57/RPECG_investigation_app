import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/active_report.dart';

class ActiveReportNotifier extends StateNotifier<List<ActiveReport>> {
  ActiveReportNotifier() : super([]) {
    _loadReports();
  }

  static const _storageKey = 'active_analytical_reports';

  Future<void> _loadReports() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      try {
        final List<dynamic> decoded = jsonDecode(data);
        state = decoded.map((item) => ActiveReport.fromJson(item)).toList();
        
        // Resume simulation for processing reports
        for (final report in state) {
          if (report.status == ActiveReportStatus.processing || report.status == ActiveReportStatus.scheduled) {
            _simulateProgress(report.id);
          }
        }
      } catch (e) {
        // Silently fail if data is corrupted
      }
    }
  }

  Future<void> _saveReports() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(state.map((r) => r.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  void addReport(ActiveReport report) {
    state = [...state, report];
    _saveReports();
    _simulateProgress(report.id);
  }

  void _simulateProgress(String id) async {
    // 1. Scheduled -> Processing
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted || _isCancelled(id)) return;
    _updateStatus(id, ActiveReportStatus.processing, 0.05);

    // 2. Processing (simulating increments)
    for (int i = 1; i <= 20; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted || _isCancelled(id)) return;
      _updateProgress(id, i * 0.05);
    }

    // 3. Draft Ready
    if (!mounted || _isCancelled(id)) return;
    _updateStatus(id, ActiveReportStatus.draftReady, 1.0);
  }

  bool _isCancelled(String id) {
    try {
      final report = state.firstWhere((r) => r.id == id);
      return report.status == ActiveReportStatus.cancelled;
    } catch (_) {
      return true; // If not found, treat as stopped
    }
  }

  void _updateStatus(String id, ActiveReportStatus status, double progress) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: status, progress: progress) else r
    ];
    _saveReports();
  }

  void _updateProgress(String id, double progress) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(progress: progress) else r
    ];
    // Save periodically during progress
    if ((progress * 100).toInt() % 20 == 0) {
      _saveReports();
    }
  }

  void approveReport(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: ActiveReportStatus.approved) else r
    ];
    _saveReports();
  }

  void cancelReport(String id) {
    state = [
      for (final r in state)
        if (r.id == id) r.copyWith(status: ActiveReportStatus.cancelled) else r
    ];
    _saveReports();
  }

  void regenerateReport(String id) {
    final index = state.indexWhere((r) => r.id == id);
    if (index != -1) {
      final oldReport = state[index];
      final newReport = oldReport.copyWith(
        status: ActiveReportStatus.scheduled,
        progress: 0.0,
      );
      state = [
        for (final r in state)
          if (r.id == id) newReport else r
      ];
      _saveReports();
      _simulateProgress(id);
    }
  }

  void removeReport(String id) {
    state = state.where((r) => r.id != id).toList();
    _saveReports();
  }
}

final activeReportsProvider = StateNotifierProvider<ActiveReportNotifier, List<ActiveReport>>((ref) {
  return ActiveReportNotifier();
});
