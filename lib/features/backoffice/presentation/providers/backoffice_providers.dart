import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/legacy/backendless_data_service.dart';
import '../../../../core/services/firebase_data_service.dart';
import '../../../../features/meters/domain/meter.dart';
import '../../../../features/dashboard/domain/investigator.dart';
import '../../domain/billing_account.dart';
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
  editInvestigation,
  billingAccountDetails,
  billingEditAccount,
  billingStatusHistory,
  billingSchedule,
  analyticalReports,
  revenueAnalysisReport,
  consumptionReport,
  tariffActivityReport,
}

enum ReportDataSource { billing, infrastructure }

final reportDataSourceProvider = StateProvider<ReportDataSource>((ref) => ReportDataSource.billing);

final backofficePageProvider =
    StateProvider<BackofficePage>((ref) => BackofficePage.dashboard);

final isSidebarCollapsedProvider = StateProvider<bool>((ref) => false);

final selectedMeterProvider = StateProvider<Meter?>((ref) => null);

/// Holds the currently selected billing account for action pages
final selectedBillingAccountProvider = StateProvider<BillingAccount?>((ref) => null);

// ─── Meters ───────────────────────────────────────────────────────────────────

final backofficeMetersProvider = FutureProvider<List<Meter>>((ref) async {
  final dataService = BackendlessDataService();
  return await dataService.getRemoteMeters();
});

final meterSearchQueryProvider = StateProvider<String>((ref) => '');

/// Advanced Filters (Sets for dynamic multi-selection)
final meterStatusFilterSetProvider = StateProvider<Set<MeterStatus>>((ref) => {});
final meterBrandFilterSetProvider = StateProvider<Set<String>>((ref) => {});
final meterFindingsFilterSetProvider = StateProvider<Set<String>>((ref) => {});

/// Dynamically aggregate available filter values from current data
final availableFilterValuesProvider = Provider<({Set<MeterStatus> statuses, Set<String> brands, Set<String> findingsKeywords})>((ref) {
  final metersAsync = ref.watch(backofficeMetersProvider);
  return metersAsync.maybeWhen(
    data: (meters) {
      final statuses = meters.map((m) => m.status).toSet();
      final brands = meters.map((m) => m.spnNumber).where((b) => b.isNotEmpty).toSet();
      
      final findingsKeywords = <String>{};
      for (final meter in meters) {
        final findings = meter.findings;
        if (findings != null && findings.isNotEmpty) {
          findingsKeywords.add(findings);
        }
      }

      return (
        statuses: statuses,
        brands: brands,
        findingsKeywords: findingsKeywords,
      );
    },
    orElse: () => (statuses: <MeterStatus>{}, brands: <String>{}, findingsKeywords: <String>{}),
  );
});

final filteredMetersProvider = Provider<List<Meter>>((ref) {
  final metersAsync = ref.watch(backofficeMetersProvider);
  final searchQuery = ref.watch(meterSearchQueryProvider).toLowerCase();
  
  // Advanced filters (Sets)
  final statusFilters = ref.watch(meterStatusFilterSetProvider);
  final brandFilters = ref.watch(meterBrandFilterSetProvider);
  final findingsFilters = ref.watch(meterFindingsFilterSetProvider);

  return metersAsync.when(
    data: (meters) {
      var filtered = meters;
      
      // 1. General search (Customer Name, ID, Address)
      if (searchQuery.isNotEmpty) {
        filtered = filtered.where((m) =>
            m.customerName.toLowerCase().contains(searchQuery) ||
            m.id.toLowerCase().contains(searchQuery) ||
            (m.findings ?? '').toLowerCase().contains(searchQuery) ||
            m.address.toLowerCase().contains(searchQuery)).toList();
      }
      
      // 2. Status Intersection (Match any selected status)
      if (statusFilters.isNotEmpty) {
        filtered = filtered.where((m) => statusFilters.contains(m.status)).toList();
      }
      
      // 3. Brand Intersection
      if (brandFilters.isNotEmpty) {
        filtered = filtered.where((m) => brandFilters.contains(m.spnNumber)).toList();
      }
      
      // 4. Findings Intersection
      if (findingsFilters.isNotEmpty) {
        filtered = filtered.where((m) => findingsFilters.contains(m.findings)).toList();
      }
      
      return filtered;
    },
    loading: () => [],
    error: (_, _) => [],
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
          final findings = (m.findings ?? '').toLowerCase();
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

// ─── Add Infrastructure ──────────────────────────────────────────────────────────

final addMeterActionProvider = Provider((ref) {
  return (Meter meter) async {
    final dataService = BackendlessDataService();
    await dataService.saveMeter(meter);
    // Refresh the list after saving
    ref.invalidate(backofficeMetersProvider);
  };
});

final deleteMeterActionProvider = Provider((ref) {
  return (String objectId) async {
    final dataService = BackendlessDataService();
    try {
      await dataService.deleteMeter(objectId);
      // Refresh the list after deleting
      ref.invalidate(backofficeMetersProvider);
    } catch (e) {
      print('DEBUG: Deletion action error: $e');
      rethrow;
    }
  };
});
// ─── Billing Dashboard ────────────────────────────────────────────────────────

/// Loads billing accounts from Firestore. Use [ref.invalidate] after
/// importing to force a fresh fetch.
final billingAccountsProvider = FutureProvider<List<BillingAccount>>((ref) async {
  final dataService = FirestoreDataService();
  return dataService.getBillingAccounts();
});

final billingSearchQueryProvider = StateProvider<String>((ref) => '');

/// Synchronous filtered list derived from the async billingAccountsProvider.
/// Returns [] while loading or on error.
final filteredBillingAccountsProvider = Provider<List<BillingAccount>>((ref) {
  final accountsAsync = ref.watch(billingAccountsProvider);
  final query = ref.watch(billingSearchQueryProvider).toLowerCase().trim();

  final accounts = accountsAsync.valueOrNull ?? [];
  if (query.isEmpty) return accounts;

  return accounts.where((account) {
    final name = account.name.toLowerCase();
    final meter = account.meter.toLowerCase();
    final accountNumber = account.account.toLowerCase();
    return name.contains(query) ||
        meter.contains(query) ||
        accountNumber.contains(query);
  }).toList();
});

final billingAccountHistoryProvider =
    FutureProvider.family<List<BillingAccount>, String>((ref, accountNumber) async {
  final dataService = FirestoreDataService();
  return dataService.getBillingHistory(accountNumber);
});

// --- Analytical Dashboard Providers ------------------------------------------

/// Revenue summary: total billed, paid, outstanding, and collection rate.
class _RevenueStats {
  final double billed;
  final double paid;
  final double outstanding;
  final double rate;
  const _RevenueStats({required this.billed, required this.paid, required this.outstanding, required this.rate});
}

final billingRevenueStatsProvider = Provider<_RevenueStats>((ref) {
  final accounts = ref.watch(billingAccountsProvider).valueOrNull ?? [];
  double totalBilled = 0;
  double totalPaid = 0;
  for (final a in accounts) {
    final billed = double.tryParse(a.totalAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final paid = double.tryParse(a.amountPaid.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    totalBilled += billed;
    totalPaid += paid;
  }
  final outstanding = totalBilled - totalPaid;
  final rate = totalBilled > 0 ? (totalPaid / totalBilled) * 100 : 0.0;
  return _RevenueStats(billed: totalBilled, paid: totalPaid, outstanding: outstanding < 0 ? 0 : outstanding, rate: rate);
});

final fraudDistributionProvider = Provider<Map<String, int>>((ref) {
  final accounts = ref.watch(billingAccountsProvider).valueOrNull ?? [];
  final counts = <String, int>{};
  for (final a in accounts) {
    final key = a.fraudBillStatus.isEmpty ? 'Unknown' : a.fraudBillStatus;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
});

final billingStatusDistributionProvider = Provider<Map<String, int>>((ref) {
  final accounts = ref.watch(billingAccountsProvider).valueOrNull ?? [];
  final counts = <String, int>{};
  for (final a in accounts) {
    final key = a.status.isEmpty ? 'Unknown' : a.status;
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
});

class _TariffPerf {
  final double billed;
  final double paid;
  const _TariffPerf({required this.billed, required this.paid});
}

final tariffPerformanceProvider = Provider<Map<String, _TariffPerf>>((ref) {
  final accounts = ref.watch(billingAccountsProvider).valueOrNull ?? [];
  final perf = <String, _TariffPerf>{};
  for (final a in accounts) {
    final tariff = a.tariff.isEmpty ? 'Unknown' : a.tariff;
    final billed = double.tryParse(a.totalAmount.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final paid = double.tryParse(a.amountPaid.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
    final existing = perf[tariff] ?? const _TariffPerf(billed: 0, paid: 0);
    perf[tariff] = _TariffPerf(billed: existing.billed + billed, paid: existing.paid + paid);
  }
  return perf;
});
