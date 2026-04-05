import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/backoffice_providers.dart';
import '../../../../features/meters/domain/meter.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  String selectedPeriod = 'Month';
  String selectedFinding = 'All Faulty';
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Content
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(ref),
                const SizedBox(height: 32),
                _buildStatCards(ref),
                const SizedBox(height: 48),
                _buildActivitySection(),
                const SizedBox(height: 48),
                _buildLiveOpsCard(),
              ],
            ),
          ),
        ),
        // Right Activity Panel — must be in an Expanded so its inner Column/Expanded works
        SizedBox(
          width: 320,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: _buildRecentActivityPanel(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(WidgetRef ref) {
    final metersAsync = ref.watch(backofficeMetersProvider);
    final isSyncing = metersAsync.isLoading;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Field Operations Overview',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Real-time intelligence from Backendless',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: isSyncing ? null : () {
            ref.invalidate(backofficeMetersProvider);
            ref.invalidate(backofficeInvestigatorsProvider);
          },
          icon: isSyncing 
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.sync_rounded, size: 18),
          label: Text(isSyncing ? 'SYNCING...' : 'SYNC DATA'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards(WidgetRef ref) {
    final total = ref.watch(totalMetersCountProvider);
    final payment = ref.watch(totalPaymentReportProvider);
    final pending = ref.watch(pendingReportsCountProvider);
    final investigatorsCount = ref.watch(activeInvestigatorsCountProvider);
    final faultyCount = ref.watch(faultyMetersCountProvider(selectedFinding)).toString();
    
    final metersAsync = ref.watch(backofficeMetersProvider);
    final isSyncing = metersAsync.isLoading;

    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 12.0;
        final totalGaps = 4;
        final availableWidth = constraints.maxWidth - (totalGaps * spacing);
        
        final baseFlex = [10.0, 10.0, 10.0, 10.0, 15.0];
        final totalBaseFlex = baseFlex.reduce((a, b) => a + b);
        
        return Row(
          children: List.generate(5, (index) {
            double currentFlex = baseFlex[index];
            if (_hoveredIndex != null) {
              if (_hoveredIndex == index) {
                currentFlex += 12.0;
              } else {
                currentFlex -= 3.0;
              }
            }
            
            final targetWidth = (currentFlex / (totalBaseFlex + (_hoveredIndex != null ? 0 : 0))) * availableWidth;
            
            Widget card;
            if (index == 0) card = _buildStatCard('Payment Report', isSyncing ? '...' : payment, Icons.payments_rounded, Colors.green, 'On Track', Colors.green, constraints, isHovered: _hoveredIndex == 0);
            else if (index == 1) card = _buildStatCard('Total Meters', isSyncing ? '...' : total, Icons.speed_rounded, const Color(0xFF1E3A8A), '+2.4%', Colors.green, constraints, isHovered: _hoveredIndex == 1);
            else if (index == 2) card = _buildStatCard('Active Investigators', isSyncing ? '...' : investigatorsCount, Icons.groups_rounded, const Color(0xFFD97706), 'Stable', const Color(0xFF64748B), constraints, isHovered: _hoveredIndex == 2);
            else if (index == 3) card = _buildStatCard('Pending Activation', isSyncing ? '...' : pending, Icons.assignment_rounded, const Color(0xFFD97706), 'Urgent', Colors.red, constraints, isHovered: _hoveredIndex == 3);
            else card = _buildStatCard(
                selectedFinding == 'All Faulty' ? 'Billed Meters' : selectedFinding,
                isSyncing ? '...' : faultyCount,
                Icons.report_problem_rounded,
                Colors.white,
                'High Priority',
                Colors.white,
                constraints,
                isDark: true,
                menu: _buildFindingsMenu(),
                isHovered: _hoveredIndex == 4,
              );

            return AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              width: targetWidth,
              margin: EdgeInsets.only(right: index < 4 ? spacing : 0),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveredIndex = index),
                onExit: (_) => setState(() => _hoveredIndex = null),
                child: Opacity(
                  opacity: isSyncing ? 0.6 : 1.0,
                  child: card,
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildFindingsMenu() {
    return PopupMenuButton<String>(
      initialValue: selectedFinding,
      tooltip: 'Filter by finding',
      onSelected: (value) {
        setState(() {
          selectedFinding = value;
        });
      },
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => findingCategories.map((cat) {
        final isSelected = selectedFinding == cat;
        return PopupMenuItem<String>(
          value: cat,
          child: Row(
            children: [
              Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16,
                color: isSelected ? AppTheme.primary : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 12),
              Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primary : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  selectedFinding == 'All Faulty' ? 'Findings' : selectedFinding,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color iconBgColor, String badgeText, Color badgeColor, BoxConstraints constraints, {bool isDark = false, Widget? menu, bool isHovered = false}) {
    final displayBgColor = isDark ? (isHovered ? const Color(0xFF991B1B) : const Color(0xFF7F1D1D)) : Colors.white;
    final contentColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final secondaryColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    return AnimatedScale(
      scale: isHovered ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: displayBgColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark ? (isHovered ? [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ] : []) : [
            BoxShadow(
              color: isHovered ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.03),
              blurRadius: isHovered ? 30 : 20,
              offset: Offset(0, isHovered ? 15 : 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.15) : iconBgColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: isDark ? Colors.white : iconBgColor, size: 24),
                ),
                if (menu != null)
                  menu
                else
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : badgeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          color: isDark ? Colors.white : badgeColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                color: secondaryColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  color: contentColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection() {
    final dailyCounts = ref.watch(meterActivityByDayProvider);
    final maxCount = dailyCounts.isEmpty ? 10.0 : (dailyCounts.reduce((a, b) => a > b ? a : b) + 5.0).clamp(10.0, 500.0);

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Investigator Activity',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Daily inspection performance metrics',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  ),
                ],
              ),
              // Filter logic (Week/Month) — Simplified for daily data
            ],
          ),
          const SizedBox(height: 40),
          AspectRatio(
            aspectRatio: 2.5,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxCount,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    tooltipRoundedRadius: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.round().toString(),
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(days[value.toInt()], style: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.bold, fontSize: 11)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (i) => _makeGroupData(i, dailyCounts[i], i == DateTime.now().weekday - 1, maxCount)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y, bool isHighlighted, double maxY) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: isHighlighted ? AppTheme.primary : const Color(0xFFF1F5F9),
          width: 40,
          borderRadius: BorderRadius.circular(6),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: const Color(0xFFF8FAFC),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveOpsCard() {
    final recent = ref.watch(recentMetersProvider);
    final latestSector = recent.isNotEmpty ? recent.first.geocode : 'District Alpha';

    return Container(
      height: 360,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&q=80&w=1000'),
          fit: BoxFit.cover,
          opacity: 0.4,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 32,
            bottom: 32,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    const Text('LIVE OPERATIONS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 1.2)),
                  ],
                ),
                const SizedBox(height: 12),
                Text('Active Grid Status: $latestSector', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                const Text('Real-time geocode tracking enabled for all field investigators.', style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityPanel() {
    final recentMeters = ref.watch(recentMetersProvider);
    final investigatorsAsync = ref.watch(backofficeInvestigatorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
              TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Activity items — scrollable flex child
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Stack(
              children: [
                Positioned(
                  left: 19,
                  top: 0,
                  bottom: 24,
                  child: Container(width: 2, color: const Color(0xFFF1F5F9)),
                ),
                recentMeters.isEmpty 
                  ? const Center(child: Text('No recent activity', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)))
                  : ListView.builder(
                      itemCount: recentMeters.length,
                      itemBuilder: (context, i) {
                        final meter = recentMeters[i];
                        final timeAgo = _getTimeAgo(meter.installationDate);
                        return _buildActivityItem(
                          'Inspection: ${meter.id}', 
                          '${meter.customerName} @ ${meter.address}', 
                          timeAgo, 
                          Icons.speed_rounded, 
                          AppTheme.primary
                        );
                      },
                    ),
              ],
            ),
          ),
        ),
        // Bottom compliance card
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE047),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Row(
                   children: [
                     const Icon(Icons.group_rounded, color: Color(0xFF1E293B)),
                     const SizedBox(width: 12),
                     Expanded(child: Text('${investigatorsAsync.maybeWhen(data: (d) => d.length, orElse: () => 0)} Active Investigators', style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13))),
                   ],
                 ),
                 const SizedBox(height: 16),
                 ElevatedButton(
                   onPressed: () {},
                   style: ElevatedButton.styleFrom(
                     backgroundColor: const Color(0xFF1E293B),
                     foregroundColor: Colors.white,
                     minimumSize: const Size(double.infinity, 48),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                   child: const Text('Broadcast Sync'),
                 ),
               ],
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes} MINS AGO';
    if (diff.inHours < 24) return '${diff.inHours} HOURS AGO';
    return '${diff.inDays} DAYS AGO';
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 12),
                Text(time, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
