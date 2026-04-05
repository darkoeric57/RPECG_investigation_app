import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../../meters/domain/meter.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metersAsync = ref.watch(metersProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Advanced Analytics'),
        elevation: 0,
      ),
      body: metersAsync.when(
        data: (meters) => _buildContent(context, ref, meters),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, List<Meter> allMeters) {
    final filter = ref.watch(analyticsFilterProvider);
    final now = DateTime.now();
    
    // Filter meters by date
    final meters = allMeters.where((m) {
      if (filter == AnalyticsFilter.allTime) return true;
      final days = filter == AnalyticsFilter.last7Days ? 7 : 30;
      return m.installationDate.isAfter(now.subtract(Duration(days: days)));
    }).toList();

    final syncedCount = meters.where((m) => m.isSynced).length;
    final localCount = meters.length - syncedCount;
    final syncProgress = meters.isEmpty ? 0.0 : syncedCount / meters.length;

    // Tariff Activity Stats
    final tariffStats = <TariffActivity, int>{};
    for (var m in meters) {
      tariffStats[m.tariffActivity] = (tariffStats[m.tariffActivity] ?? 0) + 1;
    }

    // Phase Stats
    final phaseStats = <MeterPhase, int>{};
    for (var m in meters) {
      phaseStats[m.phase] = (phaseStats[m.phase] ?? 0) + 1;
    }

    // Status Stats
    final statusStats = <MeterStatus, int>{};
    for (var m in meters) {
      statusStats[m.status] = (statusStats[m.status] ?? 0) + 1;
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Filter Switcher
        _buildFilterChips(ref, filter),
        const SizedBox(height: 24),

        // Daily Trend Section
        _buildSectionTitle('INVESTIGATION TREND'),
        const SizedBox(height: 16),
        _buildTrendChart(meters, filter),
        const SizedBox(height: 32),

        // Status Breakdown Section
        _buildSectionTitle('METER STATUS BREAKDOWN'),
        const SizedBox(height: 16),
        _buildStatusChart(statusStats),
        const SizedBox(height: 32),

        // Brand Breakdown Section
        _buildSectionTitle('TOP METER BRANDS'),
        const SizedBox(height: 16),
        _buildBrandBreakdown(meters),
        const SizedBox(height: 32),

        // Sync Progress Overview
        _buildSectionTitle('SYNC STATUS'),
        const SizedBox(height: 16),
        _buildSyncCard(syncedCount, localCount, syncProgress),
        const SizedBox(height: 32),

        // Tariff Breakdown
        _buildSectionTitle('TARIFF ACTIVITY DISTRIBUTION'),
        const SizedBox(height: 16),
        _buildTariffChart(tariffStats),
        const SizedBox(height: 32),

        // Phase Breakdown
        _buildSectionTitle('PHASE TYPE DISTRIBUTION'),
        const SizedBox(height: 16),
        _buildPhaseChart(phaseStats),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFilterChips(WidgetRef ref, AnalyticsFilter current) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: AnalyticsFilter.values.map((f) {
          final isSelected = current == f;
          final label = f == AnalyticsFilter.last7Days ? '7 DAYS' : f == AnalyticsFilter.last30Days ? '30 DAYS' : 'ALL TIME';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : AppTheme.textLight)),
              selected: isSelected,
              onSelected: (val) {
                if (val) ref.read(analyticsFilterProvider.notifier).state = f;
              },
              selectedColor: AppTheme.primary,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTrendChart(List<Meter> meters, AnalyticsFilter filter) {
    final days = filter == AnalyticsFilter.last7Days ? 7 : filter == AnalyticsFilter.last30Days ? 30 : 14; // Default to 14 for all time trend
    final now = DateTime.now();
    final dailyCounts = <DateTime, int>{};
    
    for (int i = 0; i < days; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      dailyCounts[date] = 0;
    }

    for (var m in meters) {
      final date = DateTime(m.installationDate.year, m.installationDate.month, m.installationDate.day);
      if (dailyCounts.containsKey(date)) {
        dailyCounts[date] = dailyCounts[date]! + 1;
      }
    }

    final sortedDates = dailyCounts.keys.toList()..sort();
    final spots = sortedDates.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), dailyCounts[e.value]!.toDouble());
    }).toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.only(top: 24, right: 24, left: 8, bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  if (val.toInt() % (days ~/ 4 + 1) != 0) return const SizedBox.shrink();
                  final date = sortedDates[val.toInt()];
                  return Text('${date.month}/${date.day}', style: const TextStyle(fontSize: 9, color: AppTheme.textLight));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChart(Map<MeterStatus, int> stats) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (stats.values.isEmpty ? 0 : stats.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final status = MeterStatus.values[val.toInt()];
                  return Text(status.name.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold));
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: MeterStatus.values.asMap().entries.map((e) {
            final status = e.value;
            final count = stats[status] ?? 0;
            final color = status == MeterStatus.paid ? Colors.green : status == MeterStatus.pending ? Colors.orange : Colors.red;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  color: color,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: AppTheme.textLight,
      ),
    );
  }

  Widget _buildSyncCard(int synced, int local, double progress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sync Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('${(progress * 100).toInt()}% of records uploaded', style: const TextStyle(color: AppTheme.textLight, fontSize: 12)),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      backgroundColor: AppTheme.backgroundLight,
                      color: AppTheme.primary,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('SYNCED', '$synced', Colors.green),
              _buildStatItem('LOCAL', '$local', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
      ],
    );
  }

  Widget _buildTariffChart(Map<TariffActivity, int> stats) {
    final colors = [AppTheme.primary, AppTheme.secondary, AppTheme.accent];
    final total = stats.values.fold(0, (a, b) => a + b);

    return Container(
      height: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: TariffActivity.values.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final activity = entry.value;
                  final count = stats[activity] ?? 0;
                  final percentage = total == 0 ? 0.0 : (count / total) * 100;
                  
                  return PieChartSectionData(
                    color: colors[idx % colors.length],
                    value: count.toDouble(),
                    title: count > 0 ? '${percentage.toInt()}%' : '',
                    radius: 50,
                    titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: TariffActivity.values.asMap().entries.map((entry) {
                final idx = entry.key;
                final activity = entry.value;
                final count = stats[activity] ?? 0;
                return _buildLegendItem(activity.name.toUpperCase(), colors[idx % colors.length], count);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseChart(Map<MeterPhase, int> stats) {
    final total = stats.values.fold(0, (a, b) => a + b);
    final singleCount = stats[MeterPhase.single] ?? 0;
    final threeCount = stats[MeterPhase.three] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildLinearIndicator('SINGLE PHASE', singleCount, total, Colors.blue),
          const SizedBox(height: 20),
          _buildLinearIndicator('THREE PHASE', threeCount, total, Colors.indigo),
        ],
      ),
    );
  }

  Widget _buildLinearIndicator(String label, int value, int total, Color color) {
    final progress = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Text('$value ($total total)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppTheme.backgroundLight,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildBrandBreakdown(List<Meter> meters) {
    if (meters.isEmpty) return const SizedBox.shrink();
    
    final brandCounts = <String, int>{};
    for (var m in meters) {
      final brand = m.brand.isEmpty ? 'Unknown' : m.brand;
      brandCounts[brand] = (brandCounts[brand] ?? 0) + 1;
    }

    final sortedBrands = brandCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topBrands = sortedBrands.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: topBrands.map((entry) {
          final percentage = (entry.value / meters.length * 100).toInt();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(color: AppTheme.backgroundLight, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.bolt, size: 16, color: AppTheme.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('${entry.value} Investigations', style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
                    ],
                  ),
                ),
                Text('$percentage%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primary)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label, 
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textLight),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          Text('$count', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
