import 'dart:convert' show utf8;
import 'dart:typed_data' show Uint8List;
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers.dart';
import '../../meters/domain/meter.dart';
import 'profile_drawer.dart';
import 'sync_provider.dart';
import 'package:share_plus/share_plus.dart';

class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  Future<void> _exportAll(WidgetRef ref) async {
    final csv = await ref.read(meterRepositoryProvider).generateCsvReport();
    
    if (kIsWeb) {
      final bytes = utf8.encode(csv);
      await Share.shareXFiles(
        [XFile.fromData(Uint8List.fromList(bytes), name: 'all_records_export.csv', mimeType: 'text/csv')],
        text: 'Full Investigation Report',
      );
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = io.File('${tempDir.path}/all_records_export.csv');
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(file.path)], text: 'Full Investigation Report');
    }
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('DASHBOARD_DEBUG: Building DashboardHome...');
    final metersAsync = ref.watch(metersProvider);
    final filteredMetersAsync = ref.watch(dashboardFilteredMetersProvider);
    final syncState = ref.watch(syncProvider);
    final syncNotifier = ref.read(syncProvider.notifier);
    final currentFilter = ref.watch(dashboardFilterProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Export All Records',
            onPressed: () => _exportAll(ref),
          ),
          _buildSyncButton(syncState, syncNotifier),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Notifications'),
                  content: const Text('You have no new notifications at this time.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CLOSE')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      drawer: const ProfileDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Activity Overview Card
          _buildActivityCard(context, syncState, metersAsync),
          const SizedBox(height: 24),

          // Search Bar
          _buildSearchBar(),
          const SizedBox(height: 24),

          // Filter Chips
          _buildFilterChips(ref, currentFilter),
          const SizedBox(height: 32),

          // Meter Records Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'METER RECORDS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppTheme.textDark,
                ),
              ),
              filteredMetersAsync.when(
                data: (list) => Chip(
                  label: Text(
                    '${list.length} ${currentFilter.name.toUpperCase()}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.borderLight),
                ),
                loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Records List
          filteredMetersAsync.when(
            data: (meters) => Column(
              children: meters.map((meter) => _buildMeterCard(meter)).toList(),
            ),
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            )),
            error: (err, stack) => Center(child: Text('Error loading meters: $err')),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(WidgetRef ref, MeterSyncFilter currentFilter) {
    return Row(
      children: MeterSyncFilter.values.map((filter) {
        final isSelected = currentFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(
              filter.name.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textLight,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                ref.read(dashboardFilterProvider.notifier).state = filter;
              }
            },
            selectedColor: AppTheme.primary,
            backgroundColor: Colors.white,
            side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.borderLight),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            showCheckmark: false,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSyncButton(SyncState state, SyncNotifier notifier) {
    if (state.unsyncedCount == 0 && !state.isSyncing) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextButton.icon(
        onPressed: state.isSyncing ? null : () => notifier.performSync(),
        icon: state.isSyncing 
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary))
          : const Icon(Icons.sync_outlined, size: 18),
        label: Text(
          state.isSyncing ? 'SYNCING...' : 'SYNC ALL (${state.unsyncedCount})',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppTheme.primary,
          backgroundColor: AppTheme.primary.withValues(alpha: 0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, SyncState syncState, AsyncValue<List<Meter>> metersAsync) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6), // Blue from screenshot
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          metersAsync.when(
            data: (meters) {
              final syncedCount = meters.where((m) => m.isSynced).length;
              final localCount = meters.length - syncedCount;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity Overview',
                        style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${meters.length} Records',
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Synced: $syncedCount | Local: $localCount',
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.analytics_outlined, color: Colors.white),
                          onPressed: () => context.push('/analytics'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'REPORTS',
                        style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
            error: (err, _) => Text('Error loading stats: $err', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ),
          const SizedBox(height: 24),
          // Bar Chart with Real Data
          metersAsync.when(
            data: (meters) {
              final dailyCounts = _calculateWeeklyActivity(meters);
              final maxCount = dailyCounts.values.fold(0, (prev, curr) => curr > prev ? curr : prev);
              
              final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final today = DateTime.now().weekday; // 1 = Mon, 7 = Sun

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  final dayIndex = (index + 1); // 1-7
                  final count = dailyCounts[dayIndex] ?? 0;
                  final normalizedHeight = maxCount == 0 ? 0.1 : (count / maxCount).clamp(0.1, 1.0);
                  
                  return _buildBar(
                    normalizedHeight, 
                    days[index], 
                    isActive: dayIndex == today,
                    count: count,
                  );
                }),
              );
            },
            loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Colors.white))),
            error: (_, _) => const SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Map<int, int> _calculateWeeklyActivity(List<Meter> meters) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    final counts = <int, int>{};
    for (var m in meters) {
      if (m.installationDate.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) && 
          m.installationDate.isBefore(endOfWeek.add(const Duration(seconds: 1)))) {
        final day = m.installationDate.weekday;
        counts[day] = (counts[day] ?? 0) + 1;
      }
    }
    return counts;
  }

  Widget _buildBar(double height, String label, {bool isActive = false, int count = 0}) {
    return Column(
      children: [
        if (count > 0)
          Text(
            '$count',
            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: 100 * height,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.3),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          hintText: 'Search meters or customers...',
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildMeterCard(Meter meter) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              image: meter.capturedImagePaths.isNotEmpty
                  ? (meter.capturedImagePaths.first.startsWith('http')
                      ? DecorationImage(image: NetworkImage(meter.capturedImagePaths.first), fit: BoxFit.cover)
                      : (kIsWeb 
                          ? null // Cannot use FileImage on web with local paths
                          : DecorationImage(image: FileImage(io.File(meter.capturedImagePaths.first)), fit: BoxFit.cover)))
                  : null,
            ),
            child: meter.capturedImagePaths.isEmpty 
              ? const Icon(Icons.electric_meter_outlined, color: AppTheme.textLight) 
              : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        meter.customerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        meter.id,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: meter.isSynced ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        meter.isSynced ? 'SYNCED' : 'LOCAL',
                        style: TextStyle(
                          fontSize: 8, 
                          fontWeight: FontWeight.bold, 
                          color: meter.isSynced ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 12, color: AppTheme.textLight),
                    Expanded(
                      child: Text(
                        meter.address,
                        style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
