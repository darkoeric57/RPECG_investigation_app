import '../domain/revenue_analysis.dart';

/// Pure business-logic engine for Revenue Analysis.
///
/// Algorithm (executed once per [run] call):
///
///  1. Parse every raw row into a [RevenueRecord].
///  2. Group records by the composite key (accountNumber + '|' + meterNumber).
///  3. Validate that each group uses a single, consistent meter number for an
///     account — any discrepancy is flagged as [isAccountMeterValid] = false.
///  4. Process each group in document order:
///       runningOutstanding = 0
///       for each cycle in group:
///         cycleOutstanding = runningOutstanding + cycle.totalAmount - cycle.amountPaid
///         runningOutstanding = cycleOutstanding
///         if cycleOutstanding <= 0: status = "Settled", runningOutstanding = 0
///         else: status derived from fraudBillStatus
///  5. Wrap every group into an [AccountLedger] and collect into a
///     [RevenueAnalysisSummary].
class RevenueAnalysisEngine {
  const RevenueAnalysisEngine();

  /// Run the full analysis against [rawRows] (typically imported from Excel).
  ///
  /// Returns a [RevenueAnalysisSummary] with one [AccountLedger] per unique
  /// account, containing fully-resolved cycle details.
  RevenueAnalysisSummary run(List<Map<String, String>> rawRows) {
    // ── Step 1: Parse raw rows ─────────────────────────────────────────────
    final records = rawRows
        .map((r) => RevenueRecord.fromRowMap(r))
        .where((r) => r.accountNumber.isNotEmpty || r.meterNumber.isNotEmpty)
        .toList();

    // Sort records chronologically (oldest first). Records with null dates are put first.
    records.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return -1;
      if (b.date == null) return 1;
      return a.date!.compareTo(b.date!);
    });

    // ── Step 2: Group by account number (primary key) ─────────────────────
    final Map<String, List<RevenueRecord>> byAccount = {};
    for (final rec in records) {
      final key = rec.accountNumber.trim().toUpperCase();
      if (key.isEmpty) continue;
      byAccount.putIfAbsent(key, () => []).add(rec);
    }

    // ── Step 3 & 4: Validate and process each account group ───────────────
    final List<AccountLedger> ledgers = [];

    for (final entry in byAccount.entries) {
      final accountNumber = entry.key;
      final group = entry.value;

      // 1. Check if the account number corresponds to exactly one meter number and one customer name
      final meterNumbers = group.map((r) => r.meterNumber.trim().toUpperCase()).toSet();
      final customerNames = group.map((r) => r.customerName.trim().toLowerCase()).toSet();
      final cleanNames = customerNames.where((n) => n.isNotEmpty && n != 'unknown' && n != '—').toSet();
      final isAccountMeterValid = meterNumbers.length == 1 && cleanNames.length <= 1;

      // 2. Process each unique (account, meter) sub-group independently.
      // This implements the "scan the whole data again for the same account + meter" logic.
      final Map<String, List<RevenueRecord>> byMeter = {};
      for (final rec in group) {
        final mKey = rec.meterNumber.trim().toUpperCase();
        byMeter.putIfAbsent(mKey, () => []).add(rec);
      }

      for (final meterEntry in byMeter.entries) {
        final cycles = meterEntry.value;
        
        // Cumulative balance tracking
        double runningOutstanding = 0.0;
        double totalBilled = 0.0;
        double totalPaid = 0.0;
        double totalConsumption = 0.0;
        String lastFraudBillStatus = '—';
        String lastTariff = 'Unknown';
        String lastCustomerName = 'Unknown';
        String lastFraudType = 'Normal';

        final List<RevenueRecord> processedCycles = [];

        for (final cycle in cycles) {
          // Check if we have processed a cycle with the same totalAmount
          final duplicateIndex = processedCycles.indexWhere((p) => p.totalAmount == cycle.totalAmount);

          if (duplicateIndex != -1) {
            final prevCycle = processedCycles[duplicateIndex];

            if (cycle.amountPaid == prevCycle.amountPaid) {
              // Same bill, same payment: duplicate row / same file uploaded
              cycle.outstandingBalance = runningOutstanding.clamp(0.0, double.infinity);
              cycle.settlementStatus = prevCycle.settlementStatus;
            } else if (cycle.amountPaid > prevCycle.amountPaid) {
              // Same bill, increased payment: calculate increment and deduct from outstanding balance
              final paymentIncrement = cycle.amountPaid - prevCycle.amountPaid;
              final newOutstanding = runningOutstanding - paymentIncrement;
              runningOutstanding = newOutstanding;

              totalPaid += paymentIncrement;

              cycle.outstandingBalance = runningOutstanding.clamp(0.0, double.infinity);
              cycle.settlementStatus = _resolveStatus(
                cycle.fraudBillStatus, 
                runningOutstanding, 
                cycle.totalAmount, 
                cycle.amountPaid
              );

              // Update the stored reference for subsequent duplicates
              processedCycles[duplicateIndex] = cycle;
            } else {
              // Payment decreased or same but not increased: ignore changes
              cycle.outstandingBalance = runningOutstanding.clamp(0.0, double.infinity);
              cycle.settlementStatus = prevCycle.settlementStatus;
            }
          } else {
            // New billing cycle (different totalAmount)
            final cycleOutstanding = runningOutstanding + cycle.totalAmount - cycle.amountPaid;

            totalBilled += cycle.totalAmount;
            totalPaid += cycle.amountPaid;
            totalConsumption += cycle.consumption;

            cycle.outstandingBalance = cycleOutstanding.clamp(0.0, double.infinity);
            cycle.settlementStatus = _resolveStatus(
              cycle.fraudBillStatus, 
              cycleOutstanding, 
              cycle.totalAmount, 
              cycle.amountPaid
            );

            runningOutstanding = cycleOutstanding;
            processedCycles.add(cycle);
          }

          if (cycle.fraudBillStatus != '—') lastFraudBillStatus = cycle.fraudBillStatus;
          if (cycle.tariff != 'Unknown') lastTariff = cycle.tariff;
          if (cycle.customerName != 'Unknown' && cycle.customerName.isNotEmpty) {
            lastCustomerName = cycle.customerName;
          }
          if (cycle.fraudType != 'Normal' && cycle.fraudType != '—' && cycle.fraudType != 'Unknown' && cycle.fraudType.isNotEmpty) {
            lastFraudType = cycle.fraudType;
          }
        }

        final netOutstanding = runningOutstanding;
        // BUSINESS LOGIC: Settled if balance is 0 AND amount paid equals total amount 
        // (or if cumulative balance is wiped out)
        final isSettled = netOutstanding <= 0.0;

        ledgers.add(AccountLedger(
          meterNumber: meterEntry.key,
          accountNumber: accountNumber,
          customerName: lastCustomerName,
          tariff: lastTariff,
          fraudBillStatus: lastFraudBillStatus,
          fraudType: lastFraudType,
          totalBilled: totalBilled,
          totalPaid: totalPaid,
          netOutstanding: netOutstanding.clamp(0.0, double.infinity),
          isSettled: isSettled,
          isAccountMeterValid: isAccountMeterValid,
          cycles: cycles,
          totalConsumption: totalConsumption,
        ));
      }
    }

    // Sort: mismatches first, then outstanding (largest first), then settled
    ledgers.sort((a, b) {
      if (!a.isAccountMeterValid && b.isAccountMeterValid) return -1;
      if (a.isAccountMeterValid && !b.isAccountMeterValid) return 1;
      if (!a.isSettled && b.isSettled) return -1;
      if (a.isSettled && !b.isSettled) return 1;
      return b.netOutstanding.compareTo(a.netOutstanding);
    });

    return RevenueAnalysisSummary(
      ledgers: ledgers,
      generatedAt: DateTime.now(),
    );
  }

  /// Maps a raw fraudBillStatus string + outstanding amount to a UI status label.
  String _resolveStatus(String fraudBillStatus, double outstanding, double billed, double paid) {
    if (outstanding <= 0.0) return 'Settled';
    
    final status = fraudBillStatus.trim().toLowerCase();
    if (status == 'settled') return 'Settled';
    if (status == 'invoiced') return 'Invoiced';
    if (status == 'partial' || (paid > 0 && paid < billed)) return 'Partial';
    if (status == 'disputed') return 'Disputed';
    if (status == 'unbilled') return 'Unbilled';
    if (status == 'overdue' || (outstanding > billed)) return 'Overdue';
    
    return 'Pending';
  }
}
