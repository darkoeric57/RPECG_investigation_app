import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/backendless_data_service.dart';
import '../../../../features/meters/domain/meter.dart';
import '../../../../features/dashboard/domain/investigator.dart';

// ─── Pages ───────────────────────────────────────────────────────────────────

enum BackofficePage {
  dashboard,
  dataManagement,
  investigatorAssignments,
  fieldReports,
  notificationsChat,
  mapView,
  settings,
  billingDashboard,
  meterDetails,
}

final backofficePageProvider =
    StateProvider<BackofficePage>((ref) => BackofficePage.dashboard);

final isSidebarCollapsedProvider = StateProvider<bool>((ref) => false);

final selectedMeterProvider = StateProvider<Meter?>((ref) => null);

// ─── Meters ───────────────────────────────────────────────────────────────────

final backofficeMetersProvider = FutureProvider<List<Meter>>((ref) async {
  final dataService = BackendlessDataService();
  return await dataService.getRemoteMeters();
});

final meterSearchQueryProvider = StateProvider<String>((ref) => '');

/// Active filter: null = All, otherwise MeterStatus value
final meterStatusFilterProvider = StateProvider<MeterStatus?>((ref) => null);

final filteredMetersProvider = Provider<List<Meter>>((ref) {
  final metersAsync = ref.watch(backofficeMetersProvider);
  final query = ref.watch(meterSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(meterStatusFilterProvider);

  return metersAsync.when(
    data: (meters) {
      var filtered = meters;
      if (query.isNotEmpty) {
        filtered = filtered
            .where((m) =>
                m.customerName.toLowerCase().contains(query) ||
                m.id.toLowerCase().contains(query) ||
                m.address.toLowerCase().contains(query))
            .toList();
      }
      if (statusFilter != null) {
        filtered = filtered.where((m) => m.status == statusFilter).toList();
      }
      return filtered;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ─── Findings ─────────────────────────────────────────────────────────────────

const findingCategories = [
  'All Faulty',
  'Tampered Meter',
  'Meter By-pass',
  'Already Disconnected',
  'Relay Not Tripping',
  'Communication Error',
  'Direct Connection',
  'Unauthorized Service conn.',
  'Unit Recovery',
  'Damage Meter',
  'Burnt Meter',
  'Others',
];

final faultyMetersCountProvider = Provider.family<int, String>((ref, category) {
  final metersAsync = ref.watch(backofficeMetersProvider);
  return metersAsync.maybeWhen(
    data: (meters) {
      final faultyMeters = meters.where((m) => m.status == MeterStatus.billed).toList();
      
      int countFor(String cat) {
        return faultyMeters.where((m) {
          final findings = m.findings.toLowerCase();
          final c = cat.toLowerCase();
          if (c.contains('tamper') && findings.contains('tamper')) return true;
          if (c.contains('by-pass') && findings.contains('bypass')) return true;
          if (c.contains('disconnect') && findings.contains('disconnect')) return true;
          if (c.contains('relay') && findings.contains('relay')) return true;
          if (c.contains('communication') && findings.contains('communication')) return true;
          if (c.contains('direct') && findings.contains('direct')) return true;
          if (c.contains('unauthorized') && findings.contains('unauthorized')) return true;
          if (c.contains('recovery') && findings.contains('recovery')) return true;
          if (c.contains('damage') && (findings.contains('damage') || findings.contains('damaged'))) return true;
          if (c.contains('burnt') && (findings.contains('burnt') || findings.contains('burn'))) return true;
          return findings.contains(c);
        }).length;
      }

      if (category == 'All Faulty') {
        // The default "All Faulty" count should only comprise:
        // Relay Not Tripping, Communication Error, and Burnt Meter
        return countFor('Relay Not Tripping') + 
               countFor('Communication Error') + 
               countFor('Burnt Meter');
      }
      
      return countFor(category);
    },
    orElse: () => 0,
  );
});

// ─── Investigators ────────────────────────────────────────────────────────────

final backofficeInvestigatorsProvider =
    FutureProvider<List<Investigator>>((ref) async {
  final dataService = BackendlessDataService();
  return dataService.getInvestigators();
});

// ─── Dashboard Specific Providers ─────────────────────────────────────────────

final totalMetersCountProvider = Provider<String>((ref) {
  final metersAsync = ref.watch(backofficeMetersProvider);
  return metersAsync.maybeWhen(
    data: (meters) => meters.length.toString(),
    orElse: () => '0',
  );
});

final pendingReportsCountProvider = Provider<String>((ref) {
  final metersAsync = ref.watch(backofficeMetersProvider);
  return metersAsync.maybeWhen(
    data: (meters) => meters.where((m) => m.status == MeterStatus.pending).length.toString(),
    orElse: () => '0',
  );
});

final activeInvestigatorsCountProvider = Provider<String>((ref) {
  final investigatorsAsync = ref.watch(backofficeInvestigatorsProvider);
  return investigatorsAsync.maybeWhen(
    data: (investigators) => investigators.length.toString(),
    orElse: () => '0',
  );
});

final meterActivityByDayProvider = Provider<List<double>>((ref) {
  final metersAsync = ref.watch(backofficeMetersProvider);
  return metersAsync.maybeWhen(
    data: (meters) {
      final counts = List.filled(7, 0.0);
      for (var m in meters) {
        // weekday: 1 (Mon) to 7 (Sun)
        final day = m.installationDate.weekday - 1;
        if (day >= 0 && day < 7) counts[day] += 1;
      }
      return counts;
    },
    orElse: () => List.filled(7, 0.0),
  );
});

final recentMetersProvider = Provider<List<Meter>>((ref) {
  final metersAsync = ref.watch(backofficeMetersProvider);
  return metersAsync.maybeWhen(
    data: (meters) {
      final sorted = List<Meter>.from(meters)
        ..sort((a, b) => b.installationDate.compareTo(a.installationDate));
      return sorted.take(5).toList();
    },
    orElse: () => [],
  );
});

final totalPaymentReportProvider = Provider<String>((ref) {
  final metersAsync = ref.watch(backofficeMetersProvider);
  return metersAsync.maybeWhen(
    data: (meters) {
      // Logic: GHS 200 per meter + base 12.4k for existing reporting
      final totalValue = 12400 + (meters.length * 200.0);
      if (totalValue >= 1000) {
        return 'GHS ${(totalValue / 1000).toStringAsFixed(1)}k';
      }
      return 'GHS ${totalValue.toStringAsFixed(0)}';
    },
    orElse: () => 'GHS 0k',
  );
});

final selectedInvestigatorIdProvider = StateProvider<String?>((ref) => null);

/// Whether to show only available (online) investigators
final showOnlyAvailableProvider = StateProvider<bool>((ref) => false);

// ─── Field Reports ────────────────────────────────────────────────────────────

final selectedReportIndexProvider = StateProvider<int>((ref) => 0);

/// Map of reportId -> status overrides (local state for approve/reject)
final reportStatusOverridesProvider =
    StateProvider<Map<String, String>>((ref) => {});

// ─── Chat ─────────────────────────────────────────────────────────────────────

final selectedChatIndexProvider = StateProvider<int>((ref) => 0);

/// Map of conversationIndex -> list of chat message maps
final chatMessagesProvider = StateProvider<Map<int, List<Map<String, dynamic>>>>(
    (ref) => {});

/// Mark conversations as read when selected
final unreadConversationsProvider =
    StateProvider<Set<int>>((ref) => {0}); // 0 is unread by default
