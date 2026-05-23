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
import '../../domain/report_config.dart';

// ─── Colour constants ──────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF4F46E5); // Indigo 600
const _kPrimaryLight = Color(0xFF6366F1); // Indigo 500
const _kSettled = Color(0xFF10B981);
const _kOutstanding = Color(0xFFEF4444);
const _kMismatch = Color(0xFFF59E0B);
const _kBg = Color(0xFFF8FAFC);
const _kBorder = Color(0xFFE2E8F0);

final _currency = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
final _pct = NumberFormat('0.0#');

// ─────────────────────────────────────────────────────────────────────────────
class TariffActivityReportPage extends ConsumerWidget {
  const TariffActivityReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(tariffAnalysisSummaryProvider);
    final summary = summaryAsync.valueOrNull;
    final isAnalyzing = summaryAsync.isLoading;
    final filteredLedgers = ref.watch(filteredTariffLedgersProvider);
    final isExporting = ref.watch(tariffExportLoadingProvider);
    final rawRowsCount = ref.watch(tariffRawRowsProvider).length;

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
    final activeReport = ref.watch(activeTariffReportProvider);
    final allReports = ref.watch(activeReportsProvider);
    
    final switchableReports = allReports.where((r) => 
      (r.config.type == ReportType.tariff) &&
      (r.status == ActiveReportStatus.draftReady || 
       r.status == ActiveReportStatus.approved ||
       r.status == ActiveReportStatus.processing)
    ).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: activeReport != null ? const Color(0xFFEEF2FF) : Colors.white, // Indigo 50
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: activeReport != null ? const Color(0xFFC7D2FE) : _kBorder, // Indigo 200
          width: activeReport != null ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: activeReport != null 
                ? const Color(0xFF4F46E5).withValues(alpha: 0.05) 
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
                  ? const Color(0xFF4F46E5).withValues(alpha: 0.15) 
                  : _kPrimary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              activeReport != null ? Icons.schedule_send_rounded : Icons.account_balance_wallet_rounded,
              color: activeReport != null ? const Color(0xFF4F46E5) : _kPrimary,
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
                      activeReport != null ? 'FILTERED BY SCHEDULE' : 'TARIFF SCOPE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: activeReport != null ? const Color(0xFF4338CA) : const Color(0xFF64748B),
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (activeReport != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5),
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
                  ref.read(activeTariffReportProvider.notifier).state = selected;
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
                            color: r.status == ActiveReportStatus.draftReady ? const Color(0xFF6366F1) : const Color(0xFF10B981),
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
                ref.read(activeTariffReportProvider.notifier).state = null;
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
          Icon(icon, size: 12, color: const Color(0xFF6366F1)),
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
              'SCANNING TARIFF DATA...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: _kPrimary.withValues(alpha: 0.8),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Analyzing billing and recovery statistics per Tariff Class.',
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
              const Text('Tariff Activity',
                  style: TextStyle(fontSize: 13, color: _kPrimary, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            const Text('Tariff Activity Analysis Report',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1)),
            const SizedBox(height: 4),
            const Text('Billing, payment, and collection efficiency comparison by customer classes.',
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
    final sumAsync = ref.read(tariffAnalysisSummaryProvider);
    final sum = sumAsync.valueOrNull;
    if (sum == null) return;
    ref.read(tariffExportLoadingProvider.notifier).state = true;
    try {
      final date = DateFormat('yyyyMMdd_HHmm').format(sum.generatedAt);
      if (format == 'csv') {
        final bytes = RevenueReportExporter.toTariffCSV(sum);
        WebUtils.downloadBytes('tariff_activity_analysis_$date.csv', bytes, 'text/csv');
      } else if (format == 'excel') {
        final bytes = RevenueReportExporter.toTariffExcel(sum);
        WebUtils.downloadBytes('tariff_activity_analysis_$date.xlsx',
            bytes, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      } else {
        final bytes = await RevenueReportExporter.toTariffPDF(sum);
        WebUtils.downloadBytes('tariff_activity_analysis_$date.pdf', bytes, 'application/pdf');
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
      ref.read(tariffExportLoadingProvider.notifier).state = false;
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
      Expanded(child: _KpiCard(label: 'ACTIVE ACCOUNTS', value: '${summary.totalAccounts}', icon: Icons.people_outline_rounded, color: _kPrimary)),
      const SizedBox(width: 20),
      Expanded(child: _KpiCard(label: 'TOTAL BILLED', value: _currency.format(summary.grandTotalBilled), icon: Icons.receipt_long_rounded, color: _kPrimaryLight)),
      const SizedBox(width: 20),
      Expanded(child: _KpiCard(label: 'TOTAL PAID', value: _currency.format(summary.grandTotalPaid), icon: Icons.payments_rounded, color: _kSettled, sub: 'Collected revenue')),
      const SizedBox(width: 20),
      Expanded(child: _KpiCard(label: 'RECOVERY RATE', value: '${_pct.format(summary.collectionRate)}%', icon: Icons.trending_up_rounded, color: _kPrimary, sub: 'Efficiency rate')),
      const SizedBox(width: 20),
      Expanded(child: _KpiCard(label: 'MISMATCH ACCOUNTS', value: '${summary.mismatchAccounts}', icon: Icons.warning_amber_rounded, color: _kMismatch, sub: 'Tariff class discrepancies')),
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
    final statusFilter = ref.watch(tariffStatusFilterProvider);
    final statuses = ['Settled', 'Invoiced', 'Partial', 'Disputed', 'Unbilled', 'Overdue', 'Pending', 'Mismatch'];

    return Row(children: [
      // Search
      Container(
        width: 340,
        height: 44,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: _kBorder)),
        child: TextField(
          onChanged: (v) => ref.read(tariffSearchQueryProvider.notifier).state = v,
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
                    ref.read(tariffStatusFilterProvider.notifier).state = next;
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
        Text('${ref.watch(filteredTariffLedgersProvider).length} of ${summary!.totalAccounts} accounts',
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
class _LedgerTable extends StatefulWidget {
  final List<AccountLedger> ledgers;
  final RevenueAnalysisSummary? summary;
  const _LedgerTable({required this.ledgers, required this.summary});

  @override
  State<_LedgerTable> createState() => _LedgerTableState();
}

class _LedgerTableState extends State<_LedgerTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.summary == null) {
      return const _EmptyState();
    }
    if (widget.ledgers.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 60),
          child: Text('No accounts match the current filter.',
              style: TextStyle(fontSize: 15, color: Color(0xFF94A3B8))),
        ),
      );
    }

    const headers = [
      'Customer Name', 'Account Number', 'Meter Number', 'Tariff Class',
      'Total Billed', 'Total Paid', 'Collection Eff.', 'Status',
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
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 80),
              child: Table(
                columnWidths: const {
                  0: FixedColumnWidth(160),
                  1: FixedColumnWidth(120),
                  2: FixedColumnWidth(120),
                  3: FixedColumnWidth(120),
                  4: FixedColumnWidth(120),
                  5: FixedColumnWidth(120),
                  6: FixedColumnWidth(130),
                  7: FixedColumnWidth(100),
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
                  ...widget.ledgers.asMap().entries.map((e) {
                    final i = e.key;
                    final l = e.value;
                    final bg = !l.isAccountMeterValid ? const Color(0xFFFFFBEB) : (i.isOdd ? const Color(0xFFF8FAFC) : Colors.white);

                    final double efficiency = l.totalBilled > 0 ? (l.totalPaid / l.totalBilled) * 100 : 100.0;

                    return TableRow(
                      decoration: BoxDecoration(
                        color: bg,
                        border: const Border(top: BorderSide(color: _kBorder, width: 0.5)),
                      ),
                      children: [
                        _cell(l.customerName),
                        _cell(l.accountNumber, mono: true),
                        _cell(l.meterNumber, mono: true, strike: !l.isAccountMeterValid),
                        _cell(l.tariff, bold: true),
                        _cell(_currency.format(l.totalBilled)),
                        _cell(_currency.format(l.totalPaid), color: _kSettled),
                        _cell('${_pct.format(efficiency)}%', bold: true, color: _kPrimary),
                        _statusBadge(l.settlementStatus, l.isAccountMeterValid),
                      ],
                    );
                  }),
                ],
              ),
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

  Widget _statusBadge(String status, bool isValid) {
    if (!isValid) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _kMismatch, size: 14),
            SizedBox(width: 4),
            Text('Mismatch', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _kMismatch)),
          ],
        ),
      );
    }

    final bg = status == 'Settled'
        ? const Color(0xFFD1FAE5)
        : (status == 'Pending' ? const Color(0xFFF3F4F6) : const Color(0xFFFEE2E2));
    final fg = status == 'Settled'
        ? const Color(0xFF065F46)
        : (status == 'Pending' ? const Color(0xFF374151) : const Color(0xFF991B1B));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 80),
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: Color(0xFFE0E7FF), shape: BoxShape.circle), // Indigo 100
              child: const Icon(Icons.account_balance_wallet_outlined, size: 36, color: _kPrimary),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Tariff Activity Analysis Executed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select an active report schedule configured for Tariff Activity from the schedule pipeline above to run sequential collection efficiency analysis.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
