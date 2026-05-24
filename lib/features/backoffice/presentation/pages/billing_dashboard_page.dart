import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/active_report.dart';
import '../../providers/active_report_provider.dart';
import '../../domain/report_config.dart';
import '../../../../core/utils/web_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel_plus/excel_plus.dart' as ex;
import '../../../../core/providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firebase_data_service.dart';
import '../../domain/billing_account.dart';
import '../providers/backoffice_providers.dart';
import '../../services/excel_web_worker_service.dart';
import '../widgets/report_schedule_dialog.dart';

// ... (rest of the file remains the same except for excel usage)


// ---------------------------------------------------------------------------
// State providers
// ---------------------------------------------------------------------------
final _isImportingProvider = StateProvider<bool>((ref) => false);
final _importProgressProvider = StateProvider<String>((ref) => '');

// ---------------------------------------------------------------------------
// Main page widget
// ---------------------------------------------------------------------------
class BillingDashboardPage extends ConsumerWidget {
  const BillingDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // Scrollable main canvas
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BillingHeader(),
              const SizedBox(height: 40),
              const _MetricsRow(),
              const SizedBox(height: 40),
              const _MidSection(),
              const SizedBox(height: 40),
              const _AccountActivitySection(),
              const SizedBox(height: 40),
              const _BottomInsightsRow(),
            ],
          ),
        ),
        // Floating Action Button
        Positioned(
          bottom: 32,
          right: 32,
          child: _QuickInvestigationFab(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------
class _BillingHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isImporting = ref.watch(_isImportingProvider);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Text('Overview',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B))),
                  Icon(Icons.chevron_right, size: 14, color: Color(0xFF64748B)),
                  Text('Billing Intelligence',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A8A))),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Billing Intelligence Overview',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1E3A8A),
                      letterSpacing: -1)),
              const SizedBox(height: 4),
              const Text(
                  'Real-time analysis of utility collections and outstanding liabilities.',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
            ],
          ),
        ),
        const SizedBox(width: 24),
        _PrimaryButton(
          label: isImporting ? ref.watch(_importProgressProvider).isNotEmpty ? ref.watch(_importProgressProvider) : 'Importing...' : 'Import Excel File',
          icon: isImporting ? Icons.sync : Icons.upload_file,
          isAnimatingIcon: isImporting,
          color: AppTheme.secondary,
          textColor: const Color(0xFF0F172A),
          onTap: isImporting ? () {} : () => _importExcel(ref, context),
        ),
      ],
    );
  }

  Future<void> _importExcel(WidgetRef ref, BuildContext context) async {
    if (ref.read(_isImportingProvider)) return;

    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true,
      );

      if (result == null) return;
        final Uint8List? fileBytes = result.files.first.bytes;
        if (fileBytes == null) return;

        // Capture current date for "File import Date" column
        final now = DateTime.now();
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final importDate = '${months[now.month - 1]} ${now.day.toString().padLeft(2, '0')}, ${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      ref.read(_isImportingProvider.notifier).state = true;

      try {
        // ─────────────────────────────────────────────────────────────────
        // Native Dart excel package — no CDN, no web worker required.
        // Works fully offline and on all platforms.
        // ─────────────────────────────────────────────────────────────────
        ref.read(_importProgressProvider.notifier).state = 'Parsing Excel file (Background Thread)...';
        
        // Restore background parsing using the worker_manager package.
        // This ensures the UI remains responsive during large file imports.
        final List<Map<String, String>> newAccounts = await parseExcelInBackground(fileBytes);

        if (newAccounts.isNotEmpty) {
          ref.read(_importProgressProvider.notifier).state = 'Saving to Firebase...';
          
          final dataService = FirestoreDataService();
          await dataService.saveBillingAccountsBatch(newAccounts);
          
          // Refresh the data from Firebase
          ref.invalidate(billingAccountsProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully imported ${newAccounts.length} records.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No records found. Check your column headers match expected names.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Import failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        ref.read(_isImportingProvider.notifier).state = false;
        ref.read(_importProgressProvider.notifier).state = '';
      }
    } catch (e) {
      ref.read(_isImportingProvider.notifier).state = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------


class _MetricsRow extends StatelessWidget {
  const _MetricsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.receipt_long_rounded,
            title: 'Total Outstanding',
            value: 'GHS 4,281,092',
            trend: '+12.5% from last month',
            trendColor: const Color(0xFFBA1A1A),
            trendIcon: Icons.trending_up,
            isLive: true,
            iconBgColor: AppTheme.primary,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _MetricCard(
            icon: Icons.payments_rounded,
            title: 'Collection Rate',
            value: '84.2%',
            trend: '+2.1% efficiency gain',
            trendColor: Colors.green,
            trendIcon: Icons.trending_up,
            iconBgColor: const Color(0xFF10B981),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _MetricCard(
            icon: Icons.pending_actions_rounded,
            title: 'Overdue Accounts',
            value: '1,204',
            trend: 'Action required on 85',
            trendColor: const Color(0xFFBA1A1A),
            trendIcon: Icons.warning_rounded,
            iconBgColor: const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _MetricCard(
            icon: Icons.description_rounded,
            title: 'Total Amount',
            value: '18,590',
            trend: 'Cycle ends in 4 days',
            trendColor: const Color(0xFF1E3A8A),
            trendIcon: Icons.info_outline,
            iconBgColor: const Color(0xFF6366F1),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String trend;
  final Color trendColor;
  final IconData trendIcon;
  final bool isLive;
  final Color? iconBgColor;
  final Color? iconColor;

  const _MetricCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.trend,
    required this.trendColor,
    required this.trendIcon,
    this.isLive = false,
    this.iconBgColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = iconBgColor?.withValues(alpha: 0.12) ?? AppTheme.primary.withValues(alpha: 0.12);
    final fgColor = iconBgColor ?? AppTheme.primary;
 
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: bgColor, 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: fgColor, size: 20),
              ),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), 
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LIVE', 
                    style: TextStyle(
                      fontSize: 9, 
                      fontWeight: FontWeight.w900, 
                      color: Color(0xFF64748B), 
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title, 
            style: const TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.w700, 
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value, 
            style: const TextStyle(
              fontSize: 28, 
              fontWeight: FontWeight.w900, 
              color: Color(0xFF1E3A8A), 
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(trendIcon, size: 14, color: trendColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  trend, 
                  style: TextStyle(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold, 
                    color: trendColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Mid Section (Alert + Scheduler | Tracking Feed)
// ---------------------------------------------------------------------------
class _MidSection extends StatelessWidget {
  const _MidSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        SizedBox(
          width: 280,
          child: Column(
            children: const [
              _IntelligenceAlertCard(),
              SizedBox(height: 20),
              _ReportSchedulerCard(),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right: Tracking Feed
        const Expanded(child: _TrackingFeedCard()),
      ],
    );
  }
}

// Intelligence Alert
class _IntelligenceAlertCard extends StatefulWidget {
  const _IntelligenceAlertCard();

  @override
  State<_IntelligenceAlertCard> createState() => _IntelligenceAlertCardState();
}

class _IntelligenceAlertCardState extends State<_IntelligenceAlertCard> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFEEEEF0)),
        ),
        child: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text('Alert dismissed successfully.', style: TextStyle(fontSize: 12, color: Color(0xFF444651)))),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome, color: Color(0xFFFCDF46), size: 18),
              ),
              const SizedBox(width: 12),
              const Text('Intelligence Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Anomaly detected in Zone B Residential collection patterns. Analysis ready for review.',
            style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFCDF46),
                foregroundColor: const Color(0xFF0F172A),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Proceed to Audit', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => setState(() => _dismissed = true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Dismiss Notification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

// Report Scheduler Card
class _ReportSchedulerCard extends ConsumerWidget {
  const _ReportSchedulerCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Report Scheduler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1E3A8A))),
              Icon(Icons.schedule, color: Colors.grey[400], size: 18),
            ],
          ),
          const SizedBox(height: 20),
          const Text('NEXT RUN DATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FB),
              border: Border.all(color: const Color(0xFFE2E2E4)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Mon, 26 Oct 2026', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                Icon(Icons.calendar_month, size: 16, color: Color(0xFF1E3A8A)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ref.read(backofficePageProvider.notifier).state = BackofficePage.analyticalReports;
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('View Analytical Reports', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ReportScheduleDialog(),
                );
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              child: const Text('Configure Schedule', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// Tracking Feed Card
class _TrackingFeedCard extends ConsumerWidget {
  const _TrackingFeedCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeReports = ref.watch(activeReportsProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9FB),
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEF0))),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Periodic Report Tracking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    SizedBox(height: 2),
                    Text('Automated generation pipeline and review status', style: TextStyle(fontSize: 11, color: Color(0xFF444651))),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All Reports', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: activeReports.isEmpty 
              ? Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No active reports in pipeline', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : Column(
                  children: activeReports.map((report) {
                    final isLast = report == activeReports.last;
                    return Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
                      child: _TrackingItem(
                        report: report,
                        onReview: () => _handleReview(context, report),
                        onApprove: () => _handleApprove(context, ref, report),
                      ),
                    );
                  }).toList(),
                ),
          ),
        ],
      ),
    );
  }

  void _handleReview(BuildContext context, ActiveReport report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Review ${report.title}'),
        content: const Text('This would show a preview of the generated data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
        ],
      ),
    );
  }

  void _handleApprove(BuildContext context, WidgetRef ref, ActiveReport report) async {
    ref.read(activeReportsProvider.notifier).approveReport(report.id);
    
    // Simulate generation and download
    final reportService = ref.read(reportServiceProvider);
    final reportData = await reportService.processData(report.config);
    final fileBytes = await reportService.generateFile(reportData, report.config.format);
    
    final filename = 'RPECG_Final_${report.title.replaceAll(' ', '_')}.${report.config.format.name.toLowerCase()}';
    final mimeType = report.config.format == ReportFormat.pdf ? 'application/pdf' : 
                     report.config.format == ReportFormat.excel ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' : 
                     'text/csv';
                     
    WebUtils.downloadBytes(filename, fileBytes, mimeType);

    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report approved and downloaded: $filename')),
    );
  }
}

class _TrackingItem extends StatelessWidget {
  final ActiveReport report;
  final VoidCallback onReview;
  final VoidCallback onApprove;

  const _TrackingItem({
    required this.report,
    required this.onReview,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = report.status == ActiveReportStatus.draftReady 
        ? Colors.green 
        : (report.status == ActiveReportStatus.approved ? const Color(0xFF1E3A8A) : const Color(0xFF64748B));

    final categoryBg = report.category == 'Revenue' 
        ? const Color(0xFFEBF2FF) 
        : (report.category == 'Meter Ops' ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9));

    final categoryColor = report.category == 'Revenue' 
        ? Colors.blue[700]! 
        : (report.category == 'Meter Ops' ? Colors.green : Colors.grey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: categoryBg, borderRadius: BorderRadius.circular(4)),
                  child: Text(report.category.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: categoryColor)),
                ),
                const SizedBox(height: 4),
                Text(report.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              ],
            ),
            _buildStatusWidget(report),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: report.progress,
            backgroundColor: const Color(0xFFF3F3F5),
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            minHeight: 7,
          ),
        ),
        if (report.status == ActiveReportStatus.draftReady) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              _SmallBtn(label: 'Review Draft', primary: true, onTap: onReview),
              const SizedBox(width: 8),
              _SmallBtn(label: 'Approve Report', primary: false, onTap: onApprove),
            ],
          ),
        ] else if (report.status == ActiveReportStatus.approved) ...[
           const SizedBox(height: 12),
           const Row(
            children: [
              Icon(Icons.check_circle, size: 14, color: Color(0xFF1E3A8A)),
              SizedBox(width: 4),
              Text('COMPLETED & DOWNLOADED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatusWidget(ActiveReport report) {
    switch (report.status) {
      case ActiveReportStatus.scheduled:
        return const Text('Scheduled', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey));
      case ActiveReportStatus.processing:
        return Row(
          children: [
            const _PulsingDot(color: Color(0xFF1E3A8A)),
            const SizedBox(width: 4),
            Text('Processing (${(report.progress * 100).toInt()}%)', 
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          ],
        );
      case ActiveReportStatus.draftReady:
        return Row(
          children: const [
            Icon(Icons.check_circle, size: 14, color: Colors.green),
            SizedBox(width: 4),
            Text('Draft Ready', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
          ],
        );
      case ActiveReportStatus.approved:
        return Row(
          children: const [
            Icon(Icons.verified, size: 14, color: Color(0xFF1E3A8A)),
            SizedBox(width: 4),
            Text('Approved', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          ],
        );
      case ActiveReportStatus.cancelled:
        return Row(
          children: const [
            Icon(Icons.cancel_outlined, size: 14, color: Colors.red),
            SizedBox(width: 4),
            Text('Cancelled', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        );
    }
  }
}

// ---------------------------------------------------------------------------
// Account Activity Section
// ---------------------------------------------------------------------------
class _AccountActivitySection extends ConsumerStatefulWidget {
  const _AccountActivitySection();

  @override
  ConsumerState<_AccountActivitySection> createState() => _AccountActivitySectionState();
}

class _AccountActivitySectionState extends ConsumerState<_AccountActivitySection> {
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  bool _searchExpanded = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allAccounts = ref.watch(filteredBillingAccountsProvider);
    final totalPages = (allAccounts.length / _itemsPerPage).ceil();
    final currentPage = _currentPage > totalPages ? (totalPages > 0 ? totalPages : 1) : _currentPage;
    final startIndex = (currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    final accounts = allAccounts.isEmpty ? <BillingAccount>[] : allAccounts.sublist(
      startIndex,
      endIndex > allAccounts.length ? allAccounts.length : endIndex,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: const Color(0xFF1E3A8A).withValues(alpha: 0.06), blurRadius: 32, offset: const Offset(0, 12))],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Account Activity Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                Row(
                  children: [
                    // Premium Enhanced Animated Search Bar
                    TapRegion(
                      onTapOutside: (event) {
                        if (_searchExpanded && _searchController.text.isEmpty) {
                          setState(() => _searchExpanded = false);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.fastOutSlowIn,
                        width: _searchExpanded ? 320 : 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: _searchExpanded ? Colors.white : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(23),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1E3A8A).withOpacity(_searchExpanded ? 0.12 : 0.05),
                              blurRadius: _searchExpanded ? 20 : 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            const SizedBox(width: 3),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(23),
                                onTap: () {
                                  setState(() {
                                    if (!_searchExpanded) {
                                      _searchExpanded = true;
                                    } else if (_searchController.text.isEmpty) {
                                      _searchExpanded = false;
                                    }
                                  });
                                },
                                child: SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.search_rounded, 
                                    size: 20, 
                                    color: _searchExpanded ? const Color(0xFF1E3A8A) : const Color(0xFF64748B)
                                  ),
                                ),
                              ),
                            ),
                            if (_searchExpanded)
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: TextField(
                                    controller: _searchController,
                                    autofocus: true,
                                    decoration: const InputDecoration(
                                      hintText: 'Search records...',
                                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), fontWeight: FontWeight.w400),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                      filled: false,
                                    ),
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), fontWeight: FontWeight.w600),
                                    onChanged: (val) {
                                      ref.read(billingSearchQueryProvider.notifier).state = val;
                                      setState(() => _currentPage = 1);
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _IconBtn(icon: Icons.filter_list, onTap: () {}),
                    const SizedBox(width: 8),
                    _IconBtn(icon: Icons.download, onTap: () {}),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEF0)),
          // Table
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final double width = constraints.maxWidth < 1250 ? 1250.0 : constraints.maxWidth;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: Column(
                  children: [
                  // Table header
                  Container(
                    color: const Color(0xFFF3F3F5),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12),
                        child: Row(
                          children: const [
                            _TH(label: 'Customer Name', flex: 2),
                            _TH(label: 'Meter / Account', flex: 2),
                            _TH(label: 'kWh', flex: 1),
                            _TH(label: 'Fraud Type', flex: 2),
                            _TH(label: 'Total Amount', flex: 1),
                            _TH(label: 'Amount Paid', flex: 1),
                            _TH(label: 'Fraud Bill Status', flex: 2),
                            _TH(label: 'Outstanding', flex: 1),
                            _TH(label: 'Tariff', flex: 1),
                            _TH(label: 'Created At', flex: 1),
                            _TH(label: 'Date Scheduled', flex: 1),
                            _TH(label: 'File import Date', flex: 1),
                            _TH(label: 'Actions', flex: 1),
                          ],
                        ),
                      ),
                    ),
                  // Rows
                  ...accounts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final a = entry.value;
                    return _AccountRow(
                      data: a, 
                      isEven: index % 2 == 0,
                    );
                  }),
                ],
              ),
            ),
          );
          }),
        ),
          // Footer / Pagination
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Showing ${allAccounts.isEmpty ? 0 : startIndex + 1} to ${endIndex > allAccounts.length ? allAccounts.length : endIndex} of ${allAccounts.length} accounts', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                Row(
                  children: [
                    InkWell(
                      onTap: () { if (_currentPage > 1) setState(() => _currentPage--); },
                      child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.chevron_left, size: 16, color: Color(0xFF94A3B8))),
                    ),
                    const SizedBox(width: 8),
                    ...List.generate(totalPages > 5 ? 5 : totalPages, (index) => index + 1).map((p) => GestureDetector(
                      onTap: () => setState(() => _currentPage = p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: _currentPage == p ? const Color(0xFF00164E) : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: _currentPage == p ? null : Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        alignment: Alignment.center,
                        child: Text('$p', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _currentPage == p ? Colors.white : const Color(0xFF64748B))),
                      ),
                    )),
                    if (totalPages > 5) ...[
                      const SizedBox(width: 4),
                      const Text('...', style: TextStyle(color: Color(0xFF64748B))),
                      const SizedBox(width: 4),
                    ],
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () { if (_currentPage < totalPages) setState(() => _currentPage++); },
                      child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.chevron_right, size: 16, color: Color(0xFF94A3B8))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TH extends StatelessWidget {
  final String label;
  final int flex;
  const _TH({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        alignment: Alignment.centerLeft,
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 9, 
            fontWeight: FontWeight.w900, 
            color: Color(0xFF64748B), 
            letterSpacing: 0.5
          ),
        ),
      ),
    );
  }
}

class _AccountRow extends ConsumerWidget {
  final BillingAccount data;
  final bool isEven;
  const _AccountRow({required this.data, required this.isEven});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = data.status;
    final isOverdue = status == 'Overdue';
    final isPaid = status == 'Paid';
    final isScheduled = status == 'Scheduled';
    final isPending = status == 'Pending';

    final initials = data.initials;
    
    // Circle styling for avatar
    final avatarBg = isOverdue
        ? const Color(0xFFFEE2E2)
        : isPaid
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFF1F5F9);
            
    final avatarText = isOverdue
        ? const Color(0xFF991B1B)
        : isPaid
            ? const Color(0xFF166534)
            : const Color(0xFF475569);

    final rowBg = isEven ? Colors.white : const Color(0xFFF9F9FB);

    return InkWell(
      onTap: () {
        ref.read(selectedBillingAccountProvider.notifier).state = data;
        ref.read(backofficePageProvider.notifier).state = BackofficePage.billingAccountDetails;
      },
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 12),
        decoration: BoxDecoration(
          color: rowBg,
          border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            child: Row(children: [
              Container(
                width: 32, height: 32, 
                decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle), 
                alignment: Alignment.center,
                child: Text(initials, style: TextStyle(color: avatarText, fontWeight: FontWeight.w900, fontSize: 11))
              ),
              const SizedBox(width: 12),
              Flexible(child: Text(data.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)))),
            ]),
          )),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(data.meter, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(data.account, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ]),
          )),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(data.consumption, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          )),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9), 
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(data.fraudStatus, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                  ),
                ),
              ],
            ),
          )),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF), 
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFD8B4FE)),
                    ),
                    child: Text('GHS ${data.totalAmount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF6B21A8))),
                  ),
                ),
              ],
            ),
          )),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFCCB), 
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFBEF264)),
                    ),
                    child: Text('GHS ${data.amountPaid}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF3F6212))),
                  ),
                ),
              ],
            ),
          )),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE), 
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF7DD3FC)),
                    ),
                    child: Text(data.fraudBillStatus, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF0369A1))),
                  ),
                ),
              ],
            ),
          )),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isOverdue ? const Color(0xFFEF4444) : (isPaid ? const Color(0xFF10B981) : const Color(0xFF0F172A))),
                children: [
                  const TextSpan(text: 'GHS ', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 10)),
                  TextSpan(text: data.balance),
                ],
              ),
            ),
          )),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: data.tariff == 'Non-Residential' ? const Color(0xFF1E3A8A).withValues(alpha: 0.08) : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(data.tariff,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                            color: data.tariff == 'Non-Residential' ? const Color(0xFF1E3A8A) : Colors.grey[700])),
                  ),
                ),
              ],
            ),
          )),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(data.createdAt, style: const TextStyle(fontSize: 11, color: Color(0xFF444651))),
          )),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(data.scheduled, style: const TextStyle(fontSize: 11, color: Color(0xFF444651))),
          )),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(data.importedAt != null ? '${data.importedAt!.day}/${data.importedAt!.month}/${data.importedAt!.year}' : '—', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
          )),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF64748B)),
                tooltip: 'Actions',
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  // Set the selected account data
                  ref.read(selectedBillingAccountProvider.notifier).state = data;
                  
                  // Navigate to the respective page
                  switch (value) {
                    case 'edit':
                      ref.read(backofficePageProvider.notifier).state = BackofficePage.billingEditAccount;
                      break;
                    case 'summary':
                      ref.read(backofficePageProvider.notifier).state = BackofficePage.billingAccountDetails;
                      break;
                    case 'history':
                      ref.read(backofficePageProvider.notifier).state = BackofficePage.billingStatusHistory;
                      break;
                    case 'delete':
                      _showDeleteConfirmationDialog(context, ref, data);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded, size: 18, color: Color(0xFFFCDF46)),
                        SizedBox(width: 12),
                        Text('Edit Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'summary',
                    child: Row(
                      children: [
                        Icon(Icons.summarize_outlined, size: 18, color: Color(0xFF00164E)),
                        SizedBox(width: 12),
                        Text('View Summary', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history_rounded, size: 18, color: Color(0xFF64748B)),
                        SizedBox(width: 12),
                        Text('Status History', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                        SizedBox(width: 12),
                        Text('Delete Record', style: TextStyle(fontSize: 13, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    ),
  );
}
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'Overdue':
        return Row(children: const [
          _PulsingDot(color: Color(0xFFEF4444)),
          SizedBox(width: 8),
          Flexible(child: Text('OVERDUE', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFEF4444), letterSpacing: 0.5))),
        ]);
      case 'Paid':
        return Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Flexible(child: Text('PAID', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981), letterSpacing: 0.5))),
        ]);
      case 'Scheduled':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F7FF), 
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: const [
            Icon(Icons.calendar_today_rounded, size: 10, color: Color(0xFF2563EB)),
            SizedBox(width: 6),
            Flexible(child: Text('Scheduled: 22 Oct', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF2563EB)))),
          ]),
        );
      case 'Pending':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFCE8), 
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFFEF08A)),
          ),
          child: const Text('PENDING', overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF854D0E))),
        );
      default:
        return Text(status);
    }
  }
}

// ---------------------------------------------------------------------------
// Bottom Insights Row (Bar Chart + System Health)
// ---------------------------------------------------------------------------
class _BottomInsightsRow extends StatelessWidget {
  const _BottomInsightsRow();

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _BarChartCard()),
          const SizedBox(width: 20),
          Expanded(flex: 1, child: _SystemHealthCard()),
        ],
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  final _bars = const [
    {'label': 'Jul', 'h': 0.4, 'value': 'GHS 2.1M', 'highlight': false},
    {'label': 'Aug', 'h': 0.65, 'value': 'GHS 3.4M', 'highlight': false},
    {'label': 'Sep', 'h': 0.55, 'value': 'GHS 2.9M', 'highlight': false},
    {'label': 'Oct (Est)', 'h': 0.85, 'value': 'GHS 4.2M', 'highlight': true},
    {'label': 'Nov', 'h': 0.7, 'value': 'GHS 3.8M', 'highlight': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('GHS 4,281,092', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00164E))),
          const SizedBox(height: 24),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _bars.map((b) {
                final isHighlight = b['highlight'] as bool;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _HoverBar(
                      heightFactor: b['h'] as double,
                      label: b['label'] as String,
                      value: b['value'] as String,
                      isHighlight: isHighlight,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HoverBar extends StatefulWidget {
  final double heightFactor;
  final String label;
  final String value;
  final bool isHighlight;

  const _HoverBar({required this.heightFactor, required this.label, required this.value, required this.isHighlight});

  @override
  State<_HoverBar> createState() => _HoverBarState();
}

class _HoverBarState extends State<_HoverBar> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final barColor = _hovered || widget.isHighlight
        ? (widget.isHighlight ? const Color(0xFFFCDF46) : const Color(0xFF00236F))
        : const Color(0xFF1E3A8A).withValues(alpha: 0.1);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (_hovered || widget.isHighlight)
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: widget.isHighlight ? const Color(0xFF6D5E00) : const Color(0xFF00236F),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(widget.value, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 130 * widget.heightFactor,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ),
          const SizedBox(height: 12),
          Text(widget.label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: widget.isHighlight ? const Color(0xFF6D5E00) : const Color(0xFF444651),
                  letterSpacing: 1.2)),
        ],
      ),
    );
  }
}

class _SystemHealthCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF00236F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('System Health', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(height: 8),
              Text('Infrastructure status is currently stable with 99.9% uptime for automated metering cycles.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF90A8FF), height: 1.5)),
            ],
          ),
          const SizedBox(height: 24),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sync Rate', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                  const Text('94%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: const LinearProgressIndicator(
                  value: 0.94,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFCDF46)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('System Diagnostics'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('✅  Metering sync: 94% online'),
                            SizedBox(height: 8),
                            Text('✅  Backend connectivity: Stable'),
                            SizedBox(height: 8),
                            Text('✅  Report pipeline: Running'),
                            SizedBox(height: 8),
                            Text('⚠️  Zone B anomaly: Under review'),
                          ],
                        ),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white10,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('RUN DIAGNOSTICS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Floating Action Button
// ---------------------------------------------------------------------------
class _QuickInvestigationFab extends StatefulWidget {
  @override
  State<_QuickInvestigationFab> createState() => _QuickInvestigationFabState();
}

class _QuickInvestigationFabState extends State<_QuickInvestigationFab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hovered)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C1D),
                borderRadius: BorderRadius.circular(8),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: const Text('Quick Investigation', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Launching Quick Investigation…')),
              );
            },
            child: AnimatedScale(
              scale: _hovered ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 60, height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFF00236F),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x4400236F), blurRadius: 20, offset: Offset(0, 8))],
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared helper widgets
// ---------------------------------------------------------------------------
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(width: 8, height: 8, decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle)),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  final bool isAnimatingIcon;

  const _PrimaryButton({
    required this.label, 
    required this.icon, 
    required this.color, 
    required this.textColor, 
    required this.onTap,
    this.isAnimatingIcon = false,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    if (widget.isAnimatingIcon) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_PrimaryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimatingIcon && !oldWidget.isAnimatingIcon) {
      _controller.repeat();
    } else if (!widget.isAnimatingIcon && oldWidget.isAnimatingIcon) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          decoration: BoxDecoration(
            color: widget.color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.isAnimatingIcon 
                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: widget.textColor))
                  : Icon(widget.icon, color: widget.textColor, size: 18),
              const SizedBox(width: 8),
              Text(widget.label, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFF3F3F5), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: const Color(0xFF444651)),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;
  const _SmallBtn({required this.label, required this.primary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: primary ? const Color(0xFFFCDF46) : const Color(0xFFF3F3F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: primary ? const Color(0xFF00164E) : const Color(0xFF444651))),
      ),
    );
  }
}

void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, BillingAccount account) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      contentPadding: EdgeInsets.zero,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Premium Header
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE047).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFDE047).withValues(alpha: 0.3), width: 2),
                      ),
                      child: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFFDE047), size: 54),
                    ),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.gpp_maybe_rounded, color: Color(0xFFEF4444), size: 12),
                        SizedBox(width: 4),
                        Text('DANGER ZONE', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Text(
                    'Confirm Permanent Deletion',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 20),
                  // Account Info Chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, color: Color(0xFF64748B), size: 16),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            '${account.name} (${account.account})',
                            style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(color: const Color(0xFF64748B).withValues(alpha: 0.9), fontSize: 14, height: 1.6, fontWeight: FontWeight.w500),
                      children: [
                        const TextSpan(text: 'Warning! This action will '),
                        const TextSpan(text: 'permanently erase ', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900)),
                        const TextSpan(text: 'all billing history and payment records for this account. This cannot be undone.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5)),
                        backgroundColor: Colors.white,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          if (account.id != null) {
                            final dataService = FirestoreDataService();
                            await dataService.deleteBillingAccount(account.id!);
                            
                            // Force a refresh of the billing accounts list
                            ref.invalidate(billingAccountsProvider);
                            
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Account ${account.account} deleted successfully.'),
                                  backgroundColor: const Color(0xFF0F172A),
                                ),
                              );
                            }
                          } else {
                            // If it's mock data or missing ID, notify the user
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Cannot delete mock record. Only records stored in Firebase can be deleted.'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Deletion failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_forever_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// TRUE WEB WORKER FUNCTION — Excel Parse Worker
// ---------------------------------------------------------------------------
// This function is completely SYNCHRONOUS (no async/await anywhere inside).
// That is the critical requirement for Isolate.run / Web Worker compatibility.
// Dart's Isolate.run() serialises this function + its argument (Uint8List)
// and sends it to a separate OS thread (Web Worker on Flutter Web, Dart
// Isolate on native). The main UI thread is 100% free while this runs.

/// Entry point for the background worker. Receives raw file bytes,
/// does all heavy work (unzip, patch XML, decode Excel, map headers,
/// convert rows), and returns the final list of account maps.
@pragma('vm:entry-point')
List<Map<String, String>> _excelParseWorker(Uint8List fileBytes) {
  // ── Step 1: Patch numFmtIds ────────────────────────────────────────────
  Uint8List patchedBytes;
  try {
    final archive = ZipDecoder().decodeBytes(fileBytes);
    final stylesFile = archive.findFile('xl/styles.xml');
    if (stylesFile != null) {
      final stylesXml = utf8.decode(stylesFile.content as List<int>);
      final Map<String, String> remapIds = {};
      int nextSafeId = 200;
      final numFmtPattern = RegExp(r'<numFmt[^>]+numFmtId="(\d+)"');
      for (final m in numFmtPattern.allMatches(stylesXml)) {
        final idStr = m.group(1)!;
        final id = int.parse(idStr);
        if (id < 164 && !remapIds.containsKey(idStr)) remapIds[idStr] = '${nextSafeId++}';
      }
      if (remapIds.isNotEmpty) {
        String patched = stylesXml;
        for (final e in remapIds.entries) {
          patched = patched.replaceAll('numFmtId="${e.key}"', 'numFmtId="${e.value}"');
        }
        final newArchive = Archive();
        for (final file in archive) {
          if (file.name == 'xl/styles.xml') {
            final b = utf8.encode(patched);
            newArchive.addFile(ArchiveFile('xl/styles.xml', b.length, b));
          } else {
            newArchive.addFile(file);
          }
        }
        final encoded = ZipEncoder().encode(newArchive);
        patchedBytes = Uint8List.fromList(encoded);
      } else {
        patchedBytes = fileBytes;
      }
    } else {
      patchedBytes = fileBytes;
    }
  } catch (_) {
    patchedBytes = fileBytes;
  }

  // ── Step 2: Decode Excel (ONE call — the expensive part) ─────────────
  final excel = ex.Excel.decodeBytes(patchedBytes);

  final List<Map<String, String>> results = [];

  for (final tableName in excel.tables.keys) {
    final sheet = excel.tables[tableName]!;
    if (sheet.maxRows < 2) continue;

    // ── Step 3: Map header columns ──────────────────────────────────────
    final Map<String, int> headerMap = {};
    for (int j = 0; j < sheet.rows[0].length; j++) {
      final cell = sheet.rows[0][j];
      if (cell?.value != null) {
        headerMap[cell!.value.toString().toLowerCase().trim()] = j;
      }
    }
    int idx(List<String> aliases) {
      for (final a in aliases) {
        if (headerMap.containsKey(a.toLowerCase())) return headerMap[a.toLowerCase()]!;
      }
      return -1;
    }
    final int iName    = idx(['name', 'customer name', 'customer', 'full name']);
    final int iMeter   = idx(['meter', 'meter number', 'meter no']);
    final int iAccount = idx(['account', 'account number', 'acc no', 'account no']);
    final int iSpn     = idx(['spn', 'spn number', 'spn no', 'consumption', 'kwh']);
    final int iFraud   = idx(['fraud', 'fraud status', 'fraud risk', 'fraud type']);
    final int iBills   = idx(['bills', 'total bills', 'no of bills', 'total amount', 'amount']);
    final int iPaid    = idx(['amount paid', 'paid amount', 'paid']);
    final int iFbs     = idx(['fraud bill status', 'fraud bill', 'bill status']);
    final int iBalance = idx(['balance', 'total balance', 'outstanding', 'outstanding balance']);
    final int iTariff  = idx(['tariff', 'tariff type', 'category']);
    final int iDate    = idx(['date', 'billing date', 'last billing date']);
    final int iSched   = idx(['scheduled date', 'scheduled', 'date scheduled']);
    final int iCreated = idx(['created date', 'created', 'date created', 'timestamp', 'created at']);
    final int iStatus  = idx(['status', 'billing status', 'payment status']);

    // ── Step 4: Convert every data row synchronously ────────────────────
    for (int r = 1; r < sheet.maxRows; r++) {
      final row = sheet.rows[r];
      if (row.isEmpty) continue;

      // Helper: get string value from column index
      String v(int col) {
        if (col < 0 || row.length <= col) return '—';
        final raw = row[col]?.value?.toString().trim() ?? '';
        return raw.isEmpty ? '—' : raw;
      }
      // Helper: format numbers to max 2 decimal places
      String n(String s) {
        if (s == '—') return '—';
        try {
          final only = s.replaceAll(RegExp(r'[^\d.-]'), '');
          if (only.isEmpty) return s;
          final d = double.parse(only);
          return d == d.toInt() ? d.toInt().toString() : d.toStringAsFixed(2);
        } catch (_) {
          return s;
        }
      }

      final String name = v(iName);
      final String initials = (name.isNotEmpty && name != '—')
          ? name.trim().split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).take(2).join().toUpperCase()
          : '??';

      results.add({
        'initials':          initials,
        'name':              name,
        'meter':             v(iMeter),
        'account':           v(iAccount),
        'consumption':       n(v(iSpn)),
        'fraud_status':      v(iFraud),
        'total_amount':      n(v(iBills)),
        'amount_paid':       n(v(iPaid)),
        'fraud_bill_status': v(iFbs),
        'balance':           n(v(iBalance)),
        'tariff':            v(iTariff),
        'date':              v(iDate),
        'scheduled':         v(iSched),
        'created_at':        v(iCreated),
        'status':            v(iStatus),
        'address':           '—',
      });
    }
    break; // use the first non-empty sheet only
  }
  return results;
}

// ---------------------------------------------------------------------------
// Chunked Streaming Excel Parser (non-blocking on Web)
// ---------------------------------------------------------------------------

/// Phase 1: Patch bytes, decode Excel ONCE, extract headers, and pre-convert
/// all cell values to strings. Returns a lightweight Map so Phase 2 never
/// touches the heavy Excel object again.
/// Keys: 'rows' (List<List<String>>), 'headerInfo' (Map<String,int>), 'totalRows' (int)
Future<Map<String, dynamic>?> _prepareSheetData(Uint8List fileBytes) async {
  // Yield so the UI can render the loading state before heavy work starts
  await Future.delayed(Duration.zero);

  // Step 1: Patch numFmtIds (fast, just string manipulation on XML)
  final patchedBytes = _patchExcelNumFmtIds(fileBytes);
  await Future.delayed(Duration.zero); // yield after patching

  // Step 2: Decode Excel — this is the ONE expensive call
  final excel = ex.Excel.decodeBytes(patchedBytes);
  await Future.delayed(Duration.zero); // yield after decode

  for (final tableName in excel.tables.keys) {
    final sheet = excel.tables[tableName]!;
    if (sheet.maxRows < 2) continue;

    // Step 3: Read headers
    final headerRow = sheet.rows[0];
    final Map<String, int> headerMap = {};
    for (int j = 0; j < headerRow.length; j++) {
      final cell = headerRow[j];
      if (cell != null && cell.value != null) {
        headerMap[cell.value.toString().toLowerCase().trim()] = j;
      }
    }

    int findIdx(List<String> aliases) {
      for (final alias in aliases) {
        if (headerMap.containsKey(alias.toLowerCase())) return headerMap[alias.toLowerCase()]!;
      }
      return -1;
    }

    final headerInfo = <String, int>{
      'idxName': findIdx(['name', 'customer name', 'customer', 'full name']),
      'idxMeter': findIdx(['meter', 'meter number', 'meter no']),
      'idxAccount': findIdx(['account', 'account number', 'acc no', 'account no']),
      'idxSpn': findIdx(['spn', 'spn number', 'spn no', 'consumption', 'kwh']),
      'idxFraud': findIdx(['fraud', 'fraud status', 'fraud risk', 'fraud type']),
      'idxBills': findIdx(['bills', 'total bills', 'no of bills', 'total amount', 'amount']),
      'idxAmountPaid': findIdx(['amount paid', 'paid amount', 'paid']),
      'idxFraudBillStatus': findIdx(['fraud bill status', 'fraud bill', 'bill status']),
      'idxBalance': findIdx(['balance', 'total balance', 'outstanding', 'outstanding balance']),
      'idxTariff': findIdx(['tariff', 'tariff type', 'category']),
      'idxDate': findIdx(['date', 'billing date', 'last billing date']),
      'idxScheduledDate': findIdx(['scheduled date', 'scheduled', 'date scheduled']),
      'idxCreatedDate': findIdx(['created date', 'created', 'date created', 'timestamp', 'created at']),
      'idxStatus': findIdx(['status', 'billing status', 'payment status']),
      'idxAddress': findIdx(['address', 'location', 'site', 'customer address']),
    };

    // Step 4: Pre-convert ALL cells to strings (lightweight, avoids re-decoding later)
    // We do this in batches with yields so the UI stays alive
    final List<List<String>> allRows = [];
    const int conversionBatchSize = 200;
    for (int i = 1; i < sheet.maxRows; i++) {
      if (i % conversionBatchSize == 0) await Future.delayed(Duration.zero);
      final row = sheet.rows[i];
      final List<String> strRow = row.map((cell) => cell?.value?.toString() ?? '').toList();
      allRows.add(strRow);
    }

    return {
      'rows': allRows,
      'headerInfo': headerInfo,
      'totalRows': allRows.length,
    };
  }
  return null;
}

/// Phase 2: Convert a slice of the pre-extracted string rows into account maps.
/// Fully synchronous — no file I/O, no decoding. Very fast per call.
List<Map<String, String>> _parseRowsChunk({
  required List<List<String>> rows,
  required Map<String, int> headerInfo,
  required int startRow,
  required int endRow,
}) {
  final int idxName = headerInfo['idxName']!;
  final int idxMeter = headerInfo['idxMeter']!;
  final int idxAccount = headerInfo['idxAccount']!;
  final int idxSpn = headerInfo['idxSpn']!;
  final int idxFraud = headerInfo['idxFraud']!;
  final int idxBills = headerInfo['idxBills']!;
  final int idxAmountPaid = headerInfo['idxAmountPaid']!;
  final int idxFraudBillStatus = headerInfo['idxFraudBillStatus']!;
  final int idxBalance = headerInfo['idxBalance']!;
  final int idxTariff = headerInfo['idxTariff']!;
  final int idxDate = headerInfo['idxDate']!;
  final int idxScheduledDate = headerInfo['idxScheduledDate']!;
  final int idxCreatedDate = headerInfo['idxCreatedDate']!;
  final int idxStatus = headerInfo['idxStatus']!;
  final int idxAddress = headerInfo['idxAddress']!;

  String val(List<String> row, int col) {
    if (col < 0 || row.length <= col) return '—';
    final v = row[col].trim();
    return v.isEmpty ? '—' : v;
  }

  String formatNum(String valStr) {
    if (valStr == '—' || valStr.isEmpty) return '—';
    try {
      final numericOnly = valStr.replaceAll(RegExp(r'[^\d.-]'), '');
      if (numericOnly.isEmpty) return valStr;
      final n = double.parse(numericOnly);
      return n == n.toInt() ? n.toInt().toString() : n.toStringAsFixed(2);
    } catch (_) {
      return valStr;
    }
  }

  final List<Map<String, String>> results = [];
  final int end = endRow.clamp(0, rows.length - 1);

  for (int i = startRow; i <= end; i++) {
    final row = rows[i];
    if (row.isEmpty || row.every((c) => c.isEmpty)) continue;

    final String name = val(row, idxName);
    final String initials = name.isNotEmpty && name != '—'
        ? name.trim().split(' ').where((s) => s.isNotEmpty).map((s) => s[0]).take(2).join().toUpperCase()
        : '??';

    results.add({
      'initials': initials,
      'name': name,
      'meter': val(row, idxMeter),
      'account': val(row, idxAccount),
      'consumption': formatNum(val(row, idxSpn)),
      'fraud_status': val(row, idxFraud),
      'total_amount': formatNum(val(row, idxBills)),
      'amount_paid': formatNum(val(row, idxAmountPaid)),
      'fraud_bill_status': val(row, idxFraudBillStatus),
      'balance': formatNum(val(row, idxBalance)),
      'tariff': val(row, idxTariff),
      'date': val(row, idxDate),
      'scheduled': val(row, idxScheduledDate),
      'created_at': val(row, idxCreatedDate),
      'status': val(row, idxStatus),
      'address': val(row, idxAddress),
    });
  }
  return results;
}


// ---------------------------------------------------------------------------
// Background Isolate for Parsing Excel
// ---------------------------------------------------------------------------
// NOTE: The new chunked import pipeline (_prepareSheetData + _parseRowsChunk)
// is used by _importExcel. The function below is kept as a utility.

/// Patches raw XLSX bytes to remap any custom numFmtId < 164 to safe values
/// (>= 200), preventing the excel package from throwing format errors.
Uint8List _patchExcelNumFmtIds(Uint8List bytes) {
  try {
    final archive = ZipDecoder().decodeBytes(bytes);
    final stylesFile = archive.findFile('xl/styles.xml');
    if (stylesFile == null) return bytes;

    final stylesXml = utf8.decode(stylesFile.content as List<int>);
    final Map<String, String> remapIds = {};
    int nextSafeId = 200;

    final numFmtPattern = RegExp(r'<numFmt[^>]+numFmtId="(\d+)"');
    for (final match in numFmtPattern.allMatches(stylesXml)) {
      final idStr = match.group(1)!;
      final id = int.parse(idStr);
      if (id < 164 && !remapIds.containsKey(idStr)) {
        remapIds[idStr] = '${nextSafeId++}';
      }
    }

    if (remapIds.isEmpty) return bytes;

    String patchedXml = stylesXml;
    for (final entry in remapIds.entries) {
      patchedXml = patchedXml.replaceAll(
        'numFmtId="${entry.key}"',
        'numFmtId="${entry.value}"',
      );
    }

    final newArchive = Archive();
    for (final file in archive) {
      if (file.name == 'xl/styles.xml') {
        final patchedBytes = utf8.encode(patchedXml);
        newArchive.addFile(ArchiveFile('xl/styles.xml', patchedBytes.length, patchedBytes));
      } else {
        newArchive.addFile(file);
      }
    }

    final encoded = ZipEncoder().encode(newArchive);
    return Uint8List.fromList(encoded);
  } catch (_) {}
  return bytes;
}
