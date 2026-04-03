import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

// ---------------------------------------------------------------------------
// State providers
// ---------------------------------------------------------------------------
final _reportFrequencyProvider = StateProvider<String>((ref) => 'Weekly');
final _currentPageProvider = StateProvider<int>((ref) => 1);

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
class _BillingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
          label: 'Import Excel File',
          icon: Icons.upload_file,
          color: AppTheme.secondary,
          textColor: const Color(0xFF0F172A),
          onTap: () {},
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Metrics Row
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
            title: 'Total Bills Generated',
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
    final freq = ref.watch(_reportFrequencyProvider);
    final options = ['Weekly', 'Monthly', 'Custom'];

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
          const Text('FREQUENCY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: options.map((o) {
              final isSelected = freq == o;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: o != options.last ? 8 : 0),
                  child: GestureDetector(
                    onTap: () => ref.read(_reportFrequencyProvider.notifier).state = o,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFF3F3F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(o,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.grey[600])),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
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
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening schedule settings…')),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E3A8A),
                side: const BorderSide(color: Color(0xFFDCE1FF), width: 2),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Update Schedule Settings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// Tracking Feed Card
class _TrackingFeedCard extends StatelessWidget {
  const _TrackingFeedCard();

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              children: [
                _TrackingItem(
                  category: 'Revenue Analysis',
                  categoryBg: const Color(0xFFEBF2FF),
                  categoryColor: Colors.blue[700]!,
                  title: 'Q4 Initial Projection Draft',
                  progress: 0.85,
                  barColor: const Color(0xFF1E3A8A),
                  statusWidget: Row(
                    children: const [
                      _PulsingDot(color: Color(0xFF1E3A8A)),
                      SizedBox(width: 4),
                      Text('Analyzing Data (85%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                _TrackingItem(
                  category: 'Audit Logs',
                  categoryBg: const Color(0xFFDCFCE7),
                  categoryColor: Colors.green,
                  title: 'Monthly Compliance Verification',
                  progress: 1.0,
                  barColor: Colors.green,
                  statusWidget: Row(
                    children: const [
                      Icon(Icons.check_circle, size: 14, color: Colors.green),
                      SizedBox(width: 4),
                      Text('Draft Ready', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                  actions: [
                    _SmallBtn(label: 'Review Draft', primary: true, onTap: () {}),
                    const SizedBox(width: 8),
                    _SmallBtn(label: 'Approve Report', primary: false, onTap: () {}),
                  ],
                ),
                const SizedBox(height: 28),
                _TrackingItem(
                  category: 'Meter Ops',
                  categoryBg: const Color(0xFFF1F5F9),
                  categoryColor: Colors.grey,
                  title: 'Zone-wide Disconnection List',
                  progress: 0.0,
                  barColor: Colors.grey[300]!,
                  statusWidget: const Text('Scheduled for 04:00 AM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingItem extends StatelessWidget {
  final String category;
  final Color categoryBg;
  final Color categoryColor;
  final String title;
  final double progress;
  final Color barColor;
  final Widget statusWidget;
  final List<Widget>? actions;

  const _TrackingItem({
    required this.category,
    required this.categoryBg,
    required this.categoryColor,
    required this.title,
    required this.progress,
    required this.barColor,
    required this.statusWidget,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
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
                  child: Text(category.toUpperCase(),
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: categoryColor)),
                ),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A))),
              ],
            ),
            statusWidget,
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: const Color(0xFFF3F3F5),
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 7,
          ),
        ),
        if (actions != null) ...[
          const SizedBox(height: 10),
          Row(children: actions!),
        ],
      ],
    );
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

  static const _accounts = [
    {'initials': 'RJ', 'name': 'Robert Jenkins', 'meter': 'MTR-88291', 'account': 'ACC-00412', 'spn': '99120-X', 'fraud': 'Tamper', 'bills': '12', 'balance': 'GHS 1,240.50', 'tariff': 'Residential', 'date': '08 Oct 2026', 'status': 'Overdue'},
    {'initials': 'AS', 'name': 'Alina Sterling', 'meter': 'MTR-90023', 'account': 'ACC-11892', 'spn': '44120-P', 'fraud': '—', 'bills': '4', 'balance': 'GHS 0.00', 'tariff': 'Residential', 'date': '14 Oct 2026', 'status': 'Paid'},
    {'initials': 'GC', 'name': 'Green City Logistics', 'meter': 'MTR-77121', 'account': 'ACC-88321', 'spn': '22900-L', 'fraud': 'Faulty meter', 'bills': '24', 'balance': 'GHS 14,500.00', 'tariff': 'Non-Residential', 'date': '15 Oct 2026', 'status': 'Scheduled'},
    {'initials': 'MM', 'name': 'Marcus Miller', 'meter': 'MTR-12554', 'account': 'ACC-55231', 'spn': '11204-K', 'fraud': 'Bypass', 'bills': '1', 'balance': 'GHS 245.20', 'tariff': 'Residential', 'date': '18 Oct 2026', 'status': 'Pending'},
    {'initials': 'SD', 'name': 'Sun Dry Cleaners', 'meter': 'MTR-44211', 'account': 'ACC-99011', 'spn': '88412-Y', 'fraud': 'No network service connection', 'bills': '36', 'balance': 'GHS 3,890.15', 'tariff': 'Non-Residential', 'date': '01 Oct 2026', 'status': 'Overdue'},
  ];

  @override
  Widget build(BuildContext context) {
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1200),
                child: Column(
                  children: [
                  // Table header
                  Container(
                    color: const Color(0xFFF3F3F5),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: const [
                            _TH(label: 'Customer Name', flex: 2),
                            _TH(label: 'Meter / Account', flex: 2),
                            _TH(label: 'SPN', flex: 1),
                            _TH(label: 'Fraud Type', flex: 2),
                            _TH(label: 'Total Bills', flex: 1),
                            _TH(label: 'Balance', flex: 2),
                            _TH(label: 'Tariff', flex: 2),
                            _TH(label: 'Bill Date', flex: 2),
                            _TH(label: 'Status', flex: 2),
                            _TH(label: '', flex: 1),
                          ],
                        ),
                      ),
                    ),
                  // Rows
                  ..._accounts.asMap().entries.map((entry) {
                    final index = entry.key;
                    final a = entry.value;
                    return _AccountRow(
                      data: a, 
                      isEven: index % 2 == 0,
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
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
                const Text('Showing 5 of 1,204 accounts', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                Row(
                  children: [
                    InkWell(
                      onTap: () { if (_currentPage > 1) setState(() => _currentPage--); },
                      child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.chevron_left, size: 16, color: Color(0xFF94A3B8))),
                    ),
                    const SizedBox(width: 8),
                    ...[1, 2, 3].map((p) => GestureDetector(
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
                    )).toList(),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () { if (_currentPage < 3) setState(() => _currentPage++); },
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9, 
              fontWeight: FontWeight.w900, 
              color: Color(0xFF64748B), 
              letterSpacing: 1.2
            )),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final Map<String, String> data;
  final bool isEven;
  const _AccountRow({required this.data, required this.isEven});

  @override
  Widget build(BuildContext context) {
    final status = data['status']!;
    final isOverdue = status == 'Overdue';
    final isPaid = status == 'Paid';
    final isScheduled = status == 'Scheduled';
    final isPending = status == 'Pending';

    final initials = data['initials']!;
    
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

    Color balanceColor = isOverdue ? const Color(0xFFBA1A1A) : isPaid ? Colors.green : const Color(0xFF00164E);

    return Container(
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
              Flexible(child: Text(data['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF0F172A)))),
            ]),
          )),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(data['meter']!, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: Color(0xFF475569), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(data['account']!, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
              ]),
          )),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(data['spn']!, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          )),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), 
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(data['fraud']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569))),
                ),
              ],
            ),
          )),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(data['bills']!, style: const TextStyle(fontSize: 13)),
          )),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: isOverdue ? const Color(0xFFEF4444) : (isPaid ? const Color(0xFF10B981) : const Color(0xFF0F172A))),
                children: [
                  const TextSpan(text: 'GHS ', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 10)),
                  TextSpan(text: data['balance']!.replaceFirst('GHS ', '')),
                ],
              ),
            ),
          )),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: data['tariff'] == 'Non-Residential' ? const Color(0xFF1E3A8A).withOpacity(0.08) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(data['tariff']!,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                          color: data['tariff'] == 'Non-Residential' ? const Color(0xFF1E3A8A) : Colors.grey[700])),
                ),
              ],
            ),
          )),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(data['date']!, style: const TextStyle(fontSize: 11, color: Color(0xFF444651))),
          )),
          Expanded(flex: 2, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _StatusBadge(status: status),
          )),
          Expanded(flex: 1, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: isPending
                ? InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFFFCDF46), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.more_vert, size: 16, color: Color(0xFF726200)),
                    ),
                  )
                : const SizedBox.shrink(),
          )),
        ],
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
          Text('OVERDUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFEF4444), letterSpacing: 0.5)),
        ]);
      case 'Paid':
        return Row(children: [
          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle)),
          const SizedBox(width: 8),
          const Text('PAID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF10B981), letterSpacing: 0.5)),
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
            Text('Scheduled: 22 Oct', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
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
          child: const Text('PENDING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF854D0E))),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 2, child: _BarChartCard()),
        const SizedBox(width: 20),
        Expanded(flex: 1, child: _SystemHealthCard()),
      ],
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
                  Text('Sync Rate', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7))),
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

  const _PrimaryButton({required this.label, required this.icon, required this.color, required this.textColor, required this.onTap});

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

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
              Icon(widget.icon, color: widget.textColor, size: 18),
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
