import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/backoffice_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/report_schedule_dialog.dart';
import '../../domain/active_report.dart';
import '../../domain/report_config.dart';
import '../../providers/active_report_provider.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/web_utils.dart';
import '../../providers/revenue_analysis_provider.dart';

class BillingAnalyticalReportsPage extends ConsumerWidget {
  const BillingAnalyticalReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revenueStats = ref.watch(billingRevenueStatsProvider);
    final currencyFormat = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, ref),
            const SizedBox(height: 40),
            
            // KPI Summary Row
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    title: 'TOTAL BILLED',
                    value: currencyFormat.format(revenueStats.billed),
                    icon: Icons.account_balance_wallet_rounded,
                    color: const Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _MetricTile(
                    title: 'TOTAL COLLECTED',
                    value: currencyFormat.format(revenueStats.paid),
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF10B981),
                    trend: '${revenueStats.rate.toStringAsFixed(1)}% recovery rate',
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _MetricTile(
                    title: 'OUTSTANDING',
                    value: currencyFormat.format(revenueStats.outstanding),
                    icon: Icons.pending_actions_rounded,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),

            // Charts Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Fraud & Status Distribution
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildFraudDistributionCard(ref),
                      const SizedBox(height: 24),
                      _buildStatusDistributionCard(ref),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right: Performance & Trends
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      _buildTariffPerformanceCard(ref),
                      const SizedBox(height: 24),
                      _buildRevenueTrendCard(ref),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            // Active Reports Tracking Section
            _buildActiveReportsFeed(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingDashboard,
                    icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 8),
                  const Text('Billing Intelligence', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                  const Text('Analytical Reports', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Analytical Reports Dashboard',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1),
              ),
              const SizedBox(height: 4),
              const Text(
                'Professional data analysis of utility billing cycles and recovery performance.',
                style: TextStyle(fontSize: 15, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildHeaderAction(Icons.calendar_month_rounded, 'Last 30 Days'),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(backofficePageProvider.notifier).state =
                    BackofficePage.revenueAnalysisReport;
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 14),
              label: const Text('Revenue Analysis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(backofficePageProvider.notifier).state =
                    BackofficePage.consumptionReport;
              },
              icon: const Icon(Icons.bolt_rounded, size: 14),
              label: const Text('Consumption'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(backofficePageProvider.notifier).state =
                    BackofficePage.tariffActivityReport;
              },
              icon: const Icon(Icons.account_balance_wallet_rounded, size: 14),
              label: const Text('Tariff Activity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                showGeneralDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: 'Report Schedule',
                  transitionDuration: const Duration(milliseconds: 400),
                  pageBuilder: (context, animation, secondaryAnimation) => const ReportScheduleDialog(),
                  transitionBuilder: (context, a1, a2, child) {
                    return ScaleTransition(
                      scale: CurvedAnimation(parent: a1, curve: Curves.easeOutBack),
                      child: FadeTransition(opacity: a1, child: child),
                    );
                  },
                );
              },
              icon: const Icon(Icons.description_rounded, size: 14),
              label: const Text('Export Intelligence'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(width: 6),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }

  Widget _buildFraudDistributionCard(WidgetRef ref) {
    final distribution = ref.watch(fraudDistributionProvider);
    final colors = [const Color(0xFF1E3A8A), const Color(0xFFFCDF46), const Color(0xFF10B981), const Color(0xFFEF4444), const Color(0xFF6366F1)];

    return _ChartCard(
      title: 'FRAUD STATUS DISTRIBUTION',
      subtitle: 'Breakdown of active investigation categories',
      child: SizedBox(
        height: 240,
        child: Row(
          children: [
            Expanded(
              flex: 4,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 50,
                  sections: distribution.entries.toList().asMap().entries.map((entry) {
                    final idx = entry.key;
                    final val = entry.value; // MapEntry<String, int>
                    return PieChartSectionData(
                      color: colors[idx % colors.length],
                      value: val.value.toDouble(),
                      title: '${val.value}',
                      radius: 30,
                      titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: distribution.entries.toList().asMap().entries.map((entry) {
                  final idx = entry.key;
                  final val = entry.value; // MapEntry<String, int>
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: colors[idx % colors.length], shape: BoxShape.circle)),
                        const SizedBox(width: 12),
                        Expanded(child: Text(val.key, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDistributionCard(WidgetRef ref) {
    final distribution = ref.watch(billingStatusDistributionProvider);
    return _ChartCard(
      title: 'BILLING STATUS MIX',
      subtitle: 'Aging profile of current billing cycle',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= distribution.length) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(distribution.keys.elementAt(index), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            barGroups: distribution.entries.toList().asMap().entries.map((entry) {
              final idx = entry.key;
              final val = entry.value.value;
              return BarChartGroupData(
                x: idx,
                barRods: [
                  BarChartRodData(
                    toY: val.toDouble(),
                    color: const Color(0xFF1E3A8A),
                    width: 32,
                    borderRadius: BorderRadius.circular(6),
                    backDrawRodData: BackgroundBarChartRodData(show: true, toY: 10, color: const Color(0xFFF1F5F9)),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTariffPerformanceCard(WidgetRef ref) {
    final performance = ref.watch(tariffPerformanceProvider);
    return _ChartCard(
      title: 'TARIFF PERFORMANCE ANALYSIS',
      subtitle: 'Recovery comparison by customer category',
      child: Column(
        children: performance.entries.map((e) {
          final billed = e.value.billed;
          final paid = e.value.paid;
          final rate = billed > 0 ? (paid / billed) : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A), letterSpacing: 0.5)),
                    Text('${(rate * 100).toStringAsFixed(1)}% Efficiency', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: rate,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _SmallIndicator(label: 'Billed: ${NumberFormat.compact().format(billed)}', color: const Color(0xFF94A3B8)),
                    const SizedBox(width: 16),
                    _SmallIndicator(label: 'Collected: ${NumberFormat.compact().format(paid)}', color: const Color(0xFF10B981)),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRevenueTrendCard(WidgetRef ref) {
    return _ChartCard(
      title: 'ESTIMATED REVENUE RECOVERY TREND',
      subtitle: 'Aggregated monthly collections trajectory',
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: const [
                  FlSpot(0, 3),
                  FlSpot(1, 4),
                  FlSpot(2, 3.5),
                  FlSpot(3, 5),
                  FlSpot(4, 4.5),
                  FlSpot(5, 6),
                ],
                isCurved: true,
                color: const Color(0xFF1E3A8A),
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [const Color(0xFF1E3A8A).withValues(alpha: 0.2), const Color(0xFF1E3A8A).withValues(alpha: 0.0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveReportsFeed(BuildContext context, WidgetRef ref) {
    final activeReports = ref.watch(activeReportsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.analytics_outlined, size: 20, color: Color(0xFF1E3A8A)),
              SizedBox(width: 12),
              Text(
                'LIVE REPORTING PIPELINE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A8A),
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (activeReports.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              children: [
                Icon(Icons.description_outlined, size: 48, color: const Color(0xFFCBD5E1)),
                const SizedBox(height: 16),
                const Text(
                  'No Active Reports',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Reports generated from this workspace will appear here.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            padding: const EdgeInsets.only(bottom: 40),
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 24,
              mainAxisSpacing: 24,
              mainAxisExtent: 220,
            ),
            itemCount: activeReports.length,
            itemBuilder: (context, index) {
              final report = activeReports[index];
              return TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: 1),
                duration: Duration(milliseconds: 400 + (index * 100)),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: _ActiveReportCard(
                  key: ValueKey(report.id),
                  report: report,
                  onApprove: () => _handleApprove(context, ref, report),
                  onCancel: () => ref.read(activeReportsProvider.notifier).cancelReport(report.id),
                  onRemove: () => ref.read(activeReportsProvider.notifier).removeReport(report.id),
                  onDownload: () => _handleDownload(context, ref, report),
                  onRegenerate: () => ref.read(activeReportsProvider.notifier).regenerateReport(report.id),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref, ActiveReport report) async {
    ref.read(activeReportsProvider.notifier).approveReport(report.id);
    
    // Simulate email dispatch if recipients are configured
    if (report.config.recipients.isNotEmpty) {
      final reportService = ref.read(reportServiceProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Finalizing and dispatching to recipients...'), duration: Duration(seconds: 1)),
      );
      await reportService.simulateEmailDispatch(report.title, report.config.recipients);
    }
    
    await _handleDownload(context, ref, report);
  }

  Future<void> _handleDownload(BuildContext context, WidgetRef ref, ActiveReport report) async {
    final reportService = ref.read(reportServiceProvider);
    
    // Show a snackbar for feedback
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generating ${report.config.format.name.toUpperCase()} file...'), duration: const Duration(seconds: 1)),
      );
    }

    final reportData = await reportService.processData(report.config);
    final fileBytes = await reportService.generateFile(reportData, report.config.format);
    
    final filename = 'RPECG_Final_${report.title.replaceAll(' ', '_')}.${report.config.format.name.toLowerCase()}';
    final mimeType = report.config.format == ReportFormat.pdf ? 'application/pdf' : 
                     report.config.format == ReportFormat.excel ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' : 
                     'text/csv';
                     
    WebUtils.downloadBytes(filename, fileBytes, mimeType);

    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report downloaded: $filename')),
    );
  }
}

class _ActiveReportCard extends ConsumerStatefulWidget {
  final ActiveReport report;
  final VoidCallback onApprove;
  final VoidCallback onCancel;
  final VoidCallback onRemove;
  final VoidCallback onDownload;
  final VoidCallback onRegenerate;
  
  const _ActiveReportCard({
    super.key,
    required this.report, 
    required this.onApprove,
    required this.onCancel,
    required this.onRemove,
    required this.onDownload,
    required this.onRegenerate,
  });

  @override
  ConsumerState<_ActiveReportCard> createState() => _ActiveReportCardState();
}

class _ActiveReportCardState extends ConsumerState<_ActiveReportCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered ? statusColor.withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? statusColor.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
              blurRadius: _isHovered ? 20 : 10,
              offset: Offset(0, _isHovered ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.report.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, HH:mm').format(widget.report.createdAt),
                        style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                _buildActions(),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'FORMAT: ${widget.report.config.format.name.toUpperCase()}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 0.5),
                ),
                if (widget.report.status == ActiveReportStatus.processing)
                  Text(
                    '${(widget.report.progress * 100).toInt()}%',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: statusColor),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: widget.report.progress),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    minHeight: 6,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _buildStatusFooter(statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _getActionsRow(),
    );
  }

  Widget _getActionsRow() {
    switch (widget.report.status) {
      case ActiveReportStatus.draftReady:
        return Row(
          key: const ValueKey('draft_actions'),
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                final type = widget.report.config.type;
                if (type == ReportType.revenue) {
                  ref.read(activeRevenueReportProvider.notifier).state = widget.report;
                  ref.read(backofficePageProvider.notifier).state = BackofficePage.revenueAnalysisReport;
                } else if (type == ReportType.consumption) {
                  ref.read(activeConsumptionReportProvider.notifier).state = widget.report;
                  ref.read(backofficePageProvider.notifier).state = BackofficePage.consumptionReport;
                } else if (type == ReportType.tariff) {
                  ref.read(activeTariffReportProvider.notifier).state = widget.report;
                  ref.read(backofficePageProvider.notifier).state = BackofficePage.tariffActivityReport;
                }
              },
              icon: const Icon(Icons.preview_rounded, color: Color(0xFF8B5CF6), size: 20),
              tooltip: 'Review Draft Ledger',
            ),
            IconButton(
              key: const ValueKey('approve'),
              onPressed: widget.onApprove,
              icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
              tooltip: 'Approve & Dispatch',
            ),
          ],
        );
      case ActiveReportStatus.approved:
        return Row(
          key: const ValueKey('approved_actions'),
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {
                final type = widget.report.config.type;
                if (type == ReportType.revenue) {
                  ref.read(activeRevenueReportProvider.notifier).state = widget.report;
                  ref.read(backofficePageProvider.notifier).state = BackofficePage.revenueAnalysisReport;
                } else if (type == ReportType.consumption) {
                  ref.read(activeConsumptionReportProvider.notifier).state = widget.report;
                  ref.read(backofficePageProvider.notifier).state = BackofficePage.consumptionReport;
                } else if (type == ReportType.tariff) {
                  ref.read(activeTariffReportProvider.notifier).state = widget.report;
                  ref.read(backofficePageProvider.notifier).state = BackofficePage.tariffActivityReport;
                }
              },
              icon: const Icon(Icons.preview_rounded, color: Color(0xFF10B981), size: 20),
              tooltip: 'View Ledger',
            ),
            IconButton(
              onPressed: widget.onDownload,
              icon: const Icon(Icons.file_download_outlined, color: Color(0xFF10B981), size: 20),
              tooltip: 'Download Final',
            ),
            IconButton(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.archive_outlined, color: Color(0xFF64748B), size: 20),
              tooltip: 'Archive',
            ),
          ],
        );
      case ActiveReportStatus.cancelled:
        return Row(
          key: const ValueKey('cancelled_actions'),
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: widget.onRegenerate,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF3B82F6), size: 20),
              tooltip: 'Restart',
            ),
            IconButton(
              onPressed: widget.onRemove,
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
              tooltip: 'Remove',
            ),
          ],
        );
      case ActiveReportStatus.processing:
      case ActiveReportStatus.scheduled:
        return IconButton(
          key: const ValueKey('cancel'),
          onPressed: widget.onCancel,
          icon: const Icon(Icons.stop_circle_outlined, color: Color(0xFFEF4444), size: 24),
          tooltip: 'Terminate',
        );
    }
  }

  Widget _buildStatusIcon(Color color) {
    final icon = switch (widget.report.status) {
      ActiveReportStatus.scheduled => Icons.timer_outlined,
      ActiveReportStatus.processing => Icons.sync_rounded,
      ActiveReportStatus.draftReady => Icons.assignment_turned_in_outlined,
      ActiveReportStatus.approved => Icons.verified_rounded,
      ActiveReportStatus.cancelled => Icons.error_outline_rounded,
    };
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: widget.report.status == ActiveReportStatus.processing
        ? RotationTransition(
            turns: _pulseController,
            child: Icon(icon, size: 18, color: color),
          )
        : Icon(icon, size: 18, color: color),
    );
  }

  Widget _buildStatusFooter(Color color) {
    final text = _getStatusText();
    
    if (widget.report.status == ActiveReportStatus.processing) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
        child: Text(
          text,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1),
        ),
      );
    }
    
    return Text(
      text,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 1),
    );
  }

  Color _getStatusColor() {
    switch (widget.report.status) {
      case ActiveReportStatus.scheduled: return const Color(0xFFF59E0B);
      case ActiveReportStatus.processing: return const Color(0xFF3B82F6);
      case ActiveReportStatus.draftReady: return const Color(0xFF8B5CF6);
      case ActiveReportStatus.approved: return const Color(0xFF10B981);
      case ActiveReportStatus.cancelled: return const Color(0xFF64748B);
    }
  }

  String _getStatusText() {
    switch (widget.report.status) {
      case ActiveReportStatus.scheduled: return 'QUEUED FOR DISPATCH';
      case ActiveReportStatus.processing: return 'ANALYZING DATA...';
      case ActiveReportStatus.draftReady: return 'DRAFT PENDING APPROVAL';
      case ActiveReportStatus.approved: return 'ANALYSIS COMPLETED';
      case ActiveReportStatus.cancelled: return 'PROCESS HALTED';
    }
  }
}

class _MetricTile extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;

  const _MetricTile({required this.title, required this.value, required this.icon, required this.color, this.trend});

  @override
  State<_MetricTile> createState() => _MetricTileState();
}

class _MetricTileState extends State<_MetricTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(28),
        transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered ? widget.color.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered ? widget.color.withValues(alpha: 0.12) : widget.color.withValues(alpha: 0.04),
              blurRadius: _isHovered ? 30 : 20,
              offset: Offset(0, _isHovered ? 12 : 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _isHovered ? widget.color : widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    widget.icon,
                    color: _isHovered ? Colors.white : widget.color,
                    size: 20,
                  ),
                ),
                if (widget.trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      widget.trend!,
                      style: const TextStyle(color: Color(0xFF166534), fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              widget.title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2),
            ),
            const SizedBox(height: 8),
            Text(
              widget.value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _ChartCard({required this.title, required this.subtitle, required this.child});

  @override
  State<_ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<_ChartCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _isHovered ? const Color(0xFF1E3A8A).withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _isHovered ? 0.05 : 0.02),
              blurRadius: _isHovered ? 40 : 20,
              offset: Offset(0, _isHovered ? 12 : 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E3A8A),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (_isHovered)
                  const Icon(Icons.insights_rounded, color: Color(0xFF1E3A8A), size: 20),
              ],
            ),
            const SizedBox(height: 32),
            widget.child,
          ],
        ),
      ),
    );
  }
}

class _SmallIndicator extends StatelessWidget {
  final String label;
  final Color color;
  const _SmallIndicator({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
      ],
    );
  }
}
