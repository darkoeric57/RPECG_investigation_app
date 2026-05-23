/// Domain models for the Revenue Analysis engine.
library;

import 'package:intl/intl.dart';
///
/// Business rules:
///  - Each [RevenueRecord] represents one invoice row in the imported data.
///  - Multiple rows sharing the same [accountNumber] & [meterNumber] are
///    treated as successive billing cycles for that account.
///  - The engine processes rows in document order and accumulates an
///    outstanding balance across cycles:
///      cycleOutstanding = previousOutstanding + currentTotalAmount - amountPaid
///  - A cycle is "Settled" when cycleOutstanding <= 0; otherwise it keeps
///    a status derived from the fraud bill status column.
///  - The [AccountLedger] represents the fully-resolved, per-account view
///    that is surfaced in the UI table and exported.

class RevenueRecord {
  /// Raw meter number exactly as it appears in the imported data.
  final String meterNumber;

  /// Raw account number exactly as it appears in the imported data.
  final String accountNumber;

  /// Invoice total for this billing cycle (GHS).
  final double totalAmount;

  /// Amount collected for this billing cycle (GHS).
  final double amountPaid;

  /// Raw fraud / bill status string from the source (e.g. "Invoiced", "Settled").
  final String fraudBillStatus;

  /// Tariff class (e.g. "Residential", "Non-Residential").
  final String tariff;

  /// Customer name from billing account.
  final String customerName;

  /// Fraud type category (e.g. "Meter Bypass", "Direct Connection").
  final String fraudType;

  /// Timestamp/Date of this record (for chronological ordering).
  final DateTime? date;

  /// Running outstanding balance AFTER this record is processed.
  /// Populated by the engine; not present in raw source data.
  double outstandingBalance;

  /// Whether the account/meter pairing was validated as consistent.
  final bool isAccountMeterValid;

  /// Settlement status for this cycle, resolved by the engine.
  String settlementStatus;

  RevenueRecord({
    required this.meterNumber,
    required this.accountNumber,
    required this.totalAmount,
    required this.amountPaid,
    required this.fraudBillStatus,
    required this.tariff,
    required this.customerName,
    required this.fraudType,
    this.date,
    this.outstandingBalance = 0.0,
    this.isAccountMeterValid = true,
    this.settlementStatus = 'Pending',
  });

  /// Constructs a [RevenueRecord] from an imported row map.
  /// Keys are case-insensitive; supports several common column-name variants.
  factory RevenueRecord.fromRowMap(Map<String, String> row) {
    String get(List<String> keys) {
      for (final k in keys) {
        final v = row.entries
            .firstWhere(
              (e) => e.key.trim().toLowerCase() == k.toLowerCase(),
              orElse: () => const MapEntry('', ''),
            )
            .value
            .trim();
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    double parseAmount(String raw) {
      if (raw.isEmpty) return 0.0;
      // Strip currency symbols, spaces, commas
      final cleaned = raw
          .replaceAll(RegExp(r'[GHSghs₵\s]'), '')
          .replaceAll(',', '');
      return double.tryParse(cleaned) ?? 0.0;
    }

    final meterNumber = get(['METER NUMBER', 'Meter Number', 'meter', 'meter_number', 'METER']);
    final accountNumber = get(['ACCOUNT NUMBER', 'Account Number', 'account', 'account_number', 'ACCOUNT']);
    final totalRaw = get(['TOTAL AMOUNT', 'Total Amount', 'total', 'total_amount', 'AMOUNT']);
    final paidRaw = get(['AMOUNT PAID', 'Amount Paid', 'paid', 'amount_paid', 'PAID']);
    final fraudBillStatus = get(['FRAUD BILL STATUS', 'Fraud Bill Status', 'fraud_bill_status', 'bill_status', 'BILL STATUS']);
    final fraudType = get(['FRAUD STATUS', 'Fraud Status', 'fraud_status', 'fraud', 'fraud type', 'FRAUD TYPE']);
    final tariff = get(['TARIFF', 'tariff', 'tariff_class', 'TARIFF CLASS', 'Tariff']);
    final customerName = get(['CUSTOMER NAME', 'Customer Name', 'name', 'customer_name', 'CUSTOMER', 'NAME']);
    final dateRaw = get(['DATE', 'Date', 'created_at', 'CREATED AT', 'imported_at', 'IMPORTED AT', 'importedAt']);

    return RevenueRecord(
      meterNumber: meterNumber,
      accountNumber: accountNumber,
      totalAmount: parseAmount(totalRaw),
      amountPaid: parseAmount(paidRaw),
      fraudBillStatus: fraudBillStatus.isEmpty ? '—' : fraudBillStatus,
      tariff: tariff.isEmpty ? 'Unknown' : tariff,
      customerName: customerName.isEmpty ? 'Unknown' : customerName,
      fraudType: fraudType.isEmpty ? 'Normal' : fraudType,
      date: _parseDate(dateRaw),
    );
  }
}

/// The fully-resolved account view after the engine has processed all cycles.
class AccountLedger {
  final String meterNumber;
  final String accountNumber;
  final String customerName;
  final String tariff;
  final String fraudBillStatus;
  final String fraudType;

  /// Total invoiced across ALL billing cycles.
  final double totalBilled;

  /// Total collected across ALL billing cycles.
  final double totalPaid;

  /// Net outstanding balance after rolling all cycles together.
  final double netOutstanding;

  /// True when netOutstanding <= 0 (debt fully settled).
  final bool isSettled;

  /// Whether the account-meter pairing was valid in ALL cycles.
  final bool isAccountMeterValid;

  /// All individual cycle records (in order) for drill-down.
  final List<RevenueRecord> cycles;

  AccountLedger({
    required this.meterNumber,
    required this.accountNumber,
    required this.customerName,
    required this.tariff,
    required this.fraudBillStatus,
    required this.fraudType,
    required this.totalBilled,
    required this.totalPaid,
    required this.netOutstanding,
    required this.isSettled,
    required this.isAccountMeterValid,
    required this.cycles,
  });

  String get settlementStatus {
    if (isSettled) return 'Settled';
    if (!isAccountMeterValid) return 'Mismatch';
    return cycles.isNotEmpty ? cycles.last.settlementStatus : 'Pending';
  }
}

/// Top-level summary of a complete revenue analysis run.
class RevenueAnalysisSummary {
  final List<AccountLedger> ledgers;
  final DateTime generatedAt;

  const RevenueAnalysisSummary({
    required this.ledgers,
    required this.generatedAt,
  });

  int get totalAccounts => ledgers.length;
  int get settledAccounts => ledgers.where((l) => l.isSettled).length;
  int get outstandingAccounts => ledgers.where((l) => !l.isSettled).length;
  int get mismatchAccounts => ledgers.where((l) => !l.isAccountMeterValid).length;

  double get grandTotalBilled =>
      ledgers.fold(0.0, (sum, l) => sum + l.totalBilled);
  double get grandTotalPaid =>
      ledgers.fold(0.0, (sum, l) => sum + l.totalPaid);
  double get grandTotalOutstanding =>
      ledgers.fold(0.0, (sum, l) => sum + l.netOutstanding.clamp(0.0, double.infinity));

  double get collectionRate =>
      grandTotalBilled > 0 ? (grandTotalPaid / grandTotalBilled) * 100 : 0.0;
}

/// Parses a date string trying multiple common formats. Returns null if none
/// of the formats match.
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
