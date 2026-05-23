import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/web_utils.dart';
import '../../domain/revenue_analysis.dart';
import '../../providers/revenue_analysis_provider.dart';
import '../../services/revenue_report_exporter.dart';
import '../providers/backoffice_providers.dart';
import '../../domain/active_report.dart';
import '../../providers/active_report_provider.dart';

// ─── Colour constants ──────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF1E3A8A);
const _kSettled = Color(0xFF10B981);
const _kOutstanding = Color(0xFFEF4444);
const _kMismatch = Color(0xFFF59E0B);
const _kBg = Color(0xFFF8FAFC);
const _kBorder = Color(0xFFE2E8F0);

final _currency = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);

// ─────────────────────────────────────────────────────────────────────────────
class RevenueAnalysisReportPage extends ConsumerWidget {
  const RevenueAnalysisReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(revenueAnalysisSummaryProvider);
    final summary = summaryAsync.valueOrNull;
    final isAnalyzing = summaryAsync.isLoading;
    final filteredLedgers = ref.watch(filteredLedgersProvider);
    final isExporting = ref.watch(revenueExportLoadingProvider);
    final rawRowsCount = ref.watch(revenueRawRowsProvider).length;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(isExporting: isExporting, summary: summary),
                const SizedBox(height: 28),
                const _ActiveReportBanner(),
                const SizedBox(height: 32),
                if (summary != null) ...[
                  _KpiRow(summary: summary),
                  const SizedBox(height: 32),
                  _ValidationBanner(summary: summary),
                  const SizedBox(height: 32),
                ],
                _SearchAndFilter(summary: summary),
                const SizedBox(height: 24),
                _LedgerTable(ledgers: filteredLedgers, summary: summary),
              ],
            ),
          ),
          if (isAnalyzing || (summary == null && rawRowsCount > 0))
            const _AnalysisOverlay(),
        ],
      ),
    );
  }
}

// ─── Active Report Filter Banner ─────────────────────────────────────────────
class _ActiveReportBanner extends ConsumerWidget {
  const _ActiveReportBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeReport = ref.watch(activeRevenueReportProvider);
    final allReports = ref.watch(activeReportsProvider);
    
    final switchableReports = allReports.where((r) => 
      r.status == ActiveReportStatus.draftReady || 
      r.status == ActiveReportStatus.approved ||
      r.status == ActiveReportStatus.processing
    ).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: activeReport != null ? const Color(0xFFF3E8FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activeReport != null ? const Color(0xFFD8B4FE) : _kBorder,
          width: activeReport != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: activeReport != null 
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.05) 
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: activeReport != null 
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.15) 
                  : _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activeReport != null ? Icons.schedule_send_rounded : Icons.hub_outlined,
              color: activeReport != null ? const Color(0xFF8B5CF6) : _kPrimary,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      activeReport != null ? 'FILTERED BY SCHEDULE' : 'REVENUE SCOPE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: activeReport != null ? const Color(0xFF7C3AED) : const Color(0xFF64748B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (activeReport != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          activeReport.status.name.toUpperCase(),
                          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                if (activeReport != null) ...[
                  Text(
                    activeReport.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _buildChip(
                        Icons.calendar_today_rounded,
                        '${DateFormat('dd MMM yy').format(activeReport.config.startDate)} - ${DateFormat('dd MMM yy').format(activeReport.config.endDate)}',
                      ),
                      if (activeReport.config.segments.isNotEmpty)
                        _buildChip(
                          Icons.category_rounded,
                          activeReport.config.segments.map((s) => s.name).join(', '),
                        ),
                      if (activeReport.config.statuses.isNotEmpty)
                        _buildChip(
                          Icons.rule_folder_rounded,
                          activeReport.config.statuses.map((s) => s.name).join(', '),
                        ),
                      if (activeReport.config.minKwh != null || activeReport.config.maxKwh != null)
                        _buildChip(
                          Icons.bolt_rounded,
                          '${activeReport.config.minKwh ?? 0} - ${activeReport.config.maxKwh ?? "∞"} kWh',
                        ),
                    ],
                  ),
                ] else ...[
                  const Text(
                    'Full System Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Showing all billing accounts from database. Select a configured report schedule pipeline below to filter.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Dropdown / Selector Interface
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ActiveReport?>(
                value: activeReport,
                hint: const Text('Select Report Schedule', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF64748B)),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(12),
                onChanged: (selected) {
                  ref.read(activeRevenueReportProvider.notifier).state = selected;
                },
                items: [
                  const DropdownMenuItem<ActiveReport?>(
                    value: null,
                    child: Row(
                      children: [
                        Icon(Icons.hub_outlined, size: 16, color: Color(0xFF64748B)),
                        SizedBox(width: 8),
                        Text('System Overview (All Data)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  ...switchableReports.map((r) {
                    return DropdownMenuItem<ActiveReport?>(
                      value: r,
                      child: Row(
                        children: [
                          Icon(
                            r.status == ActiveReportStatus.draftReady ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                            size: 16,
                            color: r.status == ActiveReportStatus.draftReady ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            r.title,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          if (activeReport != null) ...[
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () {
                ref.read(activeRevenueReportProvider.notifier).state = null;
              },
              icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFFEF4444)),
              label: const Text('Reset', style: TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                ),
                backgroundColor: const Color(0xFFFEF2F2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF4B5563)),
          ),
        ],
      ),
    );
  }
}

// ─── Analysis Overlay ────────────────────────────────────────────────────────
class _AnalysisOverlay extends StatelessWidget {
  const _AnalysisOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: _kPrimary, strokeWidth: 3),
            const SizedBox(height: 24),
            Text(
              'SCANNING REVENUE DATA...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _kPrimary.withValues(alpha: 0.8),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Validating account-meter correspondence and calculating cumulative balances.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Validation Banner ────────────────────────────────────────────────────────
class _ValidationBanner extends StatelessWidget {
  final RevenueAnalysisSummary summary;
  const _ValidationBanner({required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary.mismatchAccounts == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _kSettled.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kSettled.withValues(alpha: 0.2)),
        ),
        child: const Row(children: [
          Icon(Icons.check_circle_outline_rounded, color: _kSettled, size: 20),
          SizedBox(width: 12),
          Text(
            'All account numbers correspond correctly to their respective meter numbers.',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
          ),
        ]),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _kMismatch.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kMismatch.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: _kMismatch, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'WARNING: ${summary.mismatchAccounts} accounts show inconsistent meter numbers. '
            'The engine has isolated these discrepancies for audit.',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
          ),
        ),
      ]),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────
class _Header extends ConsumerWidget {
  final bool isExporting;
  final RevenueAnalysisSummary? summary;
  const _Header({required this.isExporting, required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              GestureDetector(
                onTap: () => ref.read(backofficePageProvider.notifier).state =
                    BackofficePage.analyticalReports,
                child: const Row(children: [
                  Icon(Icons.arrow_back_rounded, size: 18, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text('Analytical Reports',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
              const Text('Revenue Analysis',
                  style: TextStyle(fontSize: 13, color: _kPrimary, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            const Text('Revenue Analysis Report',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
            const SizedBox(height: 4),
            const Text('Sequential debt tracking and account-meter validation engine.',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
          ],
        ),
        if (summary != null)
          Row(children: [
            _ExportButton(
              label: 'Export CSV',
              icon: Icons.table_chart_outlined,
              color: _kPrimary,
              isLoading: isExporting,
              onTap: () => _export(context, ref, 'csv'),
            ),
            const SizedBox(width: 12),
            _ExportButton(
              label: 'Export Excel',
              icon: Icons.grid_on_rounded,
              color: const Color(0xFF10B981),
              isLoading: isExporting,
              onTap: () => _export(context, ref, 'excel'),
            ),
            const SizedBox(width: 12),
            _ExportButton(
              label: 'Export PDF',
              icon: Icons.picture_as_pdf_rounded,
              color: const Color(0xFFEF4444),
              isLoading: isExporting,
              onTap: () => _export(context, ref, 'pdf'),
            ),
          ]),
      ],
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, String format) async {
    final sumAsync = ref.read(revenueAnalysisSummaryProvider);
    final sum = sumAsync.valueOrNull;
    if (sum == null) return;
    ref.read(revenueExportLoadingProvider.notifier).state = true;
    try {
      final date = DateFormat('yyyyMMdd_HHmm').format(sum.generatedAt);
      if (format == 'csv') {
        final bytes = RevenueReportExporter.toCSV(sum);
        WebUtils.downloadBytes('revenue_analysis_$date.csv', bytes, 'text/csv');
      } else if (format == 'excel') {
        final bytes = RevenueReportExporter.toExcel(sum);
        WebUtils.downloadBytes('revenue_analysis_$date.xlsx',
            bytes, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      } else {
        final bytes = await RevenueReportExporter.toPDF(sum);
        WebUtils.downloadBytes('revenue_analysis_$date.pdf', bytes, 'application/pdf');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${format.toUpperCase()} report downloaded.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      ref.read(revenueExportLoadingProvider.notifier).state = false;
    }
  }
}

class _ExportButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;
  const _ExportButton({required this.label, required this.icon, required this.color, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onTap,
      icon: isLoading
          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: color))
          : Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
      ),
    );
  }
}

// ─── KPI Row ─────────────────────────────────────────────────────────────────
class _KpiRow extends StatelessWidget {
  final RevenueAnalysisSummary summary;
  const _KpiRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _KpiCard(label: 'TOTAL BILLED', value: _currency.format(summary.grandTotalBilled), icon: Icons.receipt_long_rounded, color: _kPrimary)),
      const SizedBox(width: 20),
      Expanded(child: _KpiCard(label: 'TOTAL COLLECTED', value: _currency.format(summary.grandTotalPaid), icon: Icons.payments_rounded, color: _kSettled, sub: '${summary.collectionRate.toStringAsFixed(1)}% recovery rate')),
      const SizedBox(width: 20),
      Expanded(child: _KpiCard(label: 'TOTAL OUTSTANDING', value: _currency.format(summary.grandTotalOutstanding), icon: Icons.pending_actions_rounded, color: _kOutstanding)),
      const SizedBox(width: 20),
      Expanded(child: _KpiCard(label: 'ACCOUNTS', value: '${summary.totalAccounts}', icon: Icons.people_alt_rounded, color: _kPrimary, sub: '${summary.settledAccounts} settled · ${summary.outstandingAccounts} outstanding')),
      const SizedBox(width: 20),
      Expanded(child: _KpiCard(label: 'VALIDATION', value: '${summary.mismatchAccounts}', icon: Icons.warning_amber_rounded, color: _kMismatch, sub: 'Meter discrepancies')),
    ]);
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  final String? sub;
  const _KpiCard({required this.label, required this.value, required this.icon, required this.color, this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 16),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color, letterSpacing: -0.5)),
        if (sub != null) ...[
          const SizedBox(height: 4),
          Text(sub!, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
        ]
      ]),
    );
  }
}

// ─── Search + Filter ──────────────────────────────────────────────────────────
class _SearchAndFilter extends ConsumerWidget {
  final RevenueAnalysisSummary? summary;
  const _SearchAndFilter({required this.summary});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(revenueStatusFilterProvider);
    final statuses = ['Settled', 'Invoiced', 'Partial', 'Disputed', 'Unbilled', 'Overdue', 'Pending', 'Mismatch'];

    return Row(children: [
      // Search
      Container(
        width: 340,
        height: 44,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
        child: TextField(
          onChanged: (v) => ref.read(revenueSearchQueryProvider.notifier).state = v,
          decoration: const InputDecoration(
            hintText: 'Search account, meter, status…',
            hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
      const SizedBox(width: 12),
      // Status filter chips
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: statuses.map((s) {
              final isActive = statusFilter.contains(s);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    final next = Set<String>.from(statusFilter);
                    isActive ? next.remove(s) : next.add(s);
                    ref.read(revenueStatusFilterProvider.notifier).state = next;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? _statusColor(s).withValues(alpha: 0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? _statusColor(s) : _kBorder),
                    ),
                    child: Text(s,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700,
                            color: isActive ? _statusColor(s) : const Color(0xFF475569))),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
      if (summary != null)
        Text('${ref.watch(filteredLedgersProvider).length} of ${summary!.totalAccounts} accounts',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
    ]);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Settled': return _kSettled;
      case 'Mismatch': return _kMismatch;
      case 'Overdue':
      case 'Disputed': return _kOutstanding;
      case 'Invoiced': return _kPrimary;
      case 'Partial': return const Color(0xFF6366F1);
      case 'Unbilled': return const Color(0xFF94A3B8);
      default: return const Color(0xFF64748B);
    }
  }
}

// ─── Ledger Table ─────────────────────────────────────────────────────────────
class _LedgerTable extends StatelessWidget {
  final List<AccountLedger> ledgers;
  final RevenueAnalysisSummary? summary;
  const _LedgerTable({required this.ledgers, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return _EmptyState();
    }
    if (ledgers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Text('No accounts match the current filter.',
              style: TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
        ),
      );
    }

    const headers = [
      'Customer Name', 'Meter Number', 'Account Number', 'Total Amount',
      'Amount Paid', 'Fraud Bill Status', 'Fraud Type', 'Outstanding Balance',
      'Tariff', 'Status',
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 80),
            child: Table(
              columnWidths: const {
                0: FixedColumnWidth(180),
                1: FixedColumnWidth(160),
                2: FixedColumnWidth(160),
                3: FixedColumnWidth(150),
                4: FixedColumnWidth(150),
                5: FixedColumnWidth(180),
                6: FixedColumnWidth(160), // Fraud Type
                7: FixedColumnWidth(160), // Outstanding Balance
                8: FixedColumnWidth(140), // Tariff
                9: FixedColumnWidth(130), // Status
              },
              children: [
                // Header row
                TableRow(
                  decoration: const BoxDecoration(color: _kPrimary),
                  children: headers.map((h) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Text(h, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5)),
                  )).toList(),
                ),
                // Data rows
                ...ledgers.asMap().entries.map((e) {
                  final i = e.key;
                  final l = e.value;
                  final bg = l.isSettled
                      ? const Color(0xFFF0FDF4)
                      : (!l.isAccountMeterValid ? const Color(0xFFFFFBEB) : (i.isOdd ? const Color(0xFFF8FAFC) : Colors.white));

                  return TableRow(
                    decoration: BoxDecoration(
                      color: bg,
                      border: const Border(top: BorderSide(color: _kBorder, width: 0.5)),
                    ),
                    children: [
                      _cell(l.customerName),
                      _cell(l.meterNumber, mono: true, strike: !l.isAccountMeterValid),
                      _cell(l.accountNumber, mono: true),
                      _cell(_currency.format(l.totalBilled), bold: true),
                      _cell(_currency.format(l.totalPaid), color: _kSettled),
                      _fraudCell(l.fraudBillStatus),
                      _fraudCell(l.fraudType),
                      _outstandingCell(l.netOutstanding),
                      _cell(l.tariff),
                      _statusBadge(l.settlementStatus, l.isAccountMeterValid),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _cell(String text, {bool mono = false, bool bold = false, Color? color, bool strike = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? const Color(0xFF0F172A),
          fontFamily: mono ? 'monospace' : null,
          decoration: strike ? TextDecoration.lineThrough : null,
          decorationColor: _kMismatch,
        ),
      ),
    );
  }

  Widget _fraudCell(String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(status, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
    );
  }

  Widget _outstandingCell(double amount) {
    final clamped = amount.clamp(0.0, double.infinity);
    final isZero = clamped <= 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Text(
        _currency.format(clamped),
        style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w700,
          color: isZero ? _kSettled : _kOutstanding,
        ),
      ),
    );
  }

  Widget _statusBadge(String status, bool isValid) {
    Color bg, fg;
    if (!isValid) {
      bg = _kMismatch.withValues(alpha: 0.15); fg = _kMismatch;
    } else {
      switch (status) {
        case 'Settled':   bg = _kSettled.withValues(alpha: 0.12); fg = _kSettled; break;
        case 'Invoiced':  bg = _kPrimary.withValues(alpha: 0.10); fg = _kPrimary; break;
        case 'Partial':   bg = const Color(0x1A6366F1); fg = const Color(0xFF6366F1); break;
        case 'Disputed':
        case 'Overdue':   bg = _kOutstanding.withValues(alpha: 0.12); fg = _kOutstanding; break;
        case 'Unbilled':  bg = const Color(0xFFF1F5F9); fg = const Color(0xFF64748B); break;
        default:          bg = const Color(0xFFF1F5F9); fg = const Color(0xFF64748B);
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(!isValid ? 'Mismatch' : status,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: fg)),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kBorder),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: _kPrimary.withValues(alpha: 0.08), shape: BoxShape.circle),
          child: const Icon(Icons.analytics_outlined, size: 36, color: _kPrimary),
        ),
        const SizedBox(height: 20),
        const Text('No Billing Data Available',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A))),
        const SizedBox(height: 8),
        const Text(
          'Import an Excel file from the Billing Intelligence dashboard\nto generate a revenue analysis report.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
        ),
      ]),
    );
  }
}
