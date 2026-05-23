import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:worker_manager/worker_manager.dart';
import '../domain/revenue_analysis.dart';
import '../services/revenue_analysis_engine.dart';
import '../presentation/providers/backoffice_providers.dart';
import '../../meters/domain/meter.dart';
import '../domain/active_report.dart';
import '../domain/billing_account.dart';

// ─── Engine singleton ─────────────────────────────────────────────────────────

const _engine = RevenueAnalysisEngine();

// ─── State holders ────────────────────────────────────────────────────────────

/// Holds the currently selected ActiveReport to filter/run sequential cycle analysis.
final activeRevenueReportProvider = StateProvider<ActiveReport?>((ref) => null);

/// Holds raw rows filtered from the billing accounts, driven by the active
/// report schedule config. Declared as a plain [Provider] (NOT StateProvider)
/// so that [ref.watch] works reactively inside it.
final revenueRawRowsProvider = Provider<List<Map<String, String>>>((ref) {
  // Use valueOrNull: returns [] while Firestore is loading, real data once resolved.
  final accounts = ref.watch(billingAccountsProvider).valueOrNull ?? [];
  final activeReport = ref.watch(activeRevenueReportProvider);

  List<BillingAccount> filteredAccounts = accounts;

  if (activeReport != null) {
    final config = activeReport.config;
    filteredAccounts = accounts.where((account) {
      // 1. Date Filtering — Check if either the parsed createdAt or importedAt falls within the range.
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

      // 2. Segment Filtering — normalize tariff spaces and hyphens for robust matching
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

      // 3. Status Filtering — check both fraud_bill_status and status fields
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
  }

  // Map to the standard column-keyed format expected by the analysis engine.
  return filteredAccounts.map<Map<String, String>>((account) {
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
    };
  }).toList();
});

/// Parses a date string trying multiple common formats. Returns null if none
/// of the formats match, so callers can decide whether to include the record.
DateTime? _parseDate(String dateStr) {
  final trimmed = dateStr.trim();
  if (trimmed.isEmpty) return null;

  // Try explicit formats with and without time components
  final formats = [
    DateFormat('dd/MM/yyyy HH:mm'),
    DateFormat('dd/MM/yyyy HH:mm:ss'),
    DateFormat('MM/dd/yyyy HH:mm'),
    DateFormat('MM/dd/yyyy HH:mm:ss'),
    DateFormat('yyyy-MM-dd HH:mm:ss'),
    DateFormat('yyyy-MM-dd HH:mm'),
    DateFormat('dd MMM yyyy HH:mm'),
    DateFormat('d MMM yyyy HH:mm'),
    DateFormat('dd MMM yyyy'),  // "17 May 2026"
    DateFormat('d MMM yyyy'),   // "7 May 2026"
    DateFormat('dd/MM/yyyy'),   // "17/05/2026"
    DateFormat('MM/dd/yyyy'),   // "05/17/2026"
    DateFormat('yyyy-MM-dd'),   // "2026-05-17"
  ];
  for (final fmt in formats) {
    try {
      return fmt.parse(trimmed);
    } catch (_) {}
  }

  // Fallback: Split by space to isolate the date part and try parsing it
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

  // Final fallback: Dart's built-in (handles full ISO 8601 with time/zone).
  try {
    return DateTime.parse(trimmed);
  } catch (_) {
    return null;
  }
}

// ─── Analysis result ──────────────────────────────────────────────────────────

/// Runs the analysis engine over the current raw rows in a background thread.
/// This re-computes automatically whenever [revenueRawRowsProvider] changes.
final revenueAnalysisSummaryProvider =
    FutureProvider<RevenueAnalysisSummary?>((ref) async {
  final rows = ref.watch(revenueRawRowsProvider);
  if (rows.isEmpty) return null;

  // Offload heavy analysis to background thread.
  return await workerManager.execute(() => _engine.run(rows));
});

// ─── UI filter / search ───────────────────────────────────────────────────────

/// Free-text search string applied to meter/account number and status.
final revenueSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filter by settlement status; empty set = show all.
final revenueStatusFilterProvider = StateProvider<Set<String>>((ref) => {});

/// Derived filtered ledger list for the UI table.
final filteredLedgersProvider = Provider<List<AccountLedger>>((ref) {
  final summaryAsync = ref.watch(revenueAnalysisSummaryProvider);
  final summary = summaryAsync.asData?.value;
  if (summary == null) return [];

  final query = ref.watch(revenueSearchQueryProvider).trim().toLowerCase();
  final statusFilter = ref.watch(revenueStatusFilterProvider);

  var ledgers = summary.ledgers;

  if (query.isNotEmpty) {
    ledgers = ledgers
        .where((l) =>
            l.meterNumber.toLowerCase().contains(query) ||
            l.accountNumber.toLowerCase().contains(query) ||
            l.customerName.toLowerCase().contains(query) ||
            l.tariff.toLowerCase().contains(query) ||
            l.fraudBillStatus.toLowerCase().contains(query) ||
            l.fraudType.toLowerCase().contains(query) ||
            l.settlementStatus.toLowerCase().contains(query))
        .toList();
  }

  if (statusFilter.isNotEmpty) {
    ledgers = ledgers
        .where((l) => statusFilter.contains(l.settlementStatus))
        .toList();
  }

  return ledgers;
});

// ─── Export state ─────────────────────────────────────────────────────────────

/// True while an export operation is in progress.
final revenueExportLoadingProvider = StateProvider<bool>((ref) => false);
