import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../domain/investigator.dart';
import 'profile_drawer.dart';
import 'sync_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DashboardHome extends ConsumerWidget {
  const DashboardHome({super.key});

  Future<void> _exportAll(WidgetRef ref) async {
    final csv = await ref.read(meterRepositoryProvider).generateCsvReport();
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/all_records_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Full Investigation Report');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final investigatorsAsync = ref.watch(investigatorsProvider);
    final syncState = ref.watch(syncProvider);
    final syncNotifier = ref.read(syncProvider.notifier);

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
            onPressed: () {},
          ),
        ],
      ),
      drawer: const ProfileDrawer(),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Activity Overview Card
          _buildActivityCard(syncState),
          const SizedBox(height: 24),

          // Search Bar
          _buildSearchBar(),
          const SizedBox(height: 32),

          // Investigator Records Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'INVESTIGATOR RECORDS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: AppTheme.textDark,
                ),
              ),
              investigatorsAsync.when(
                data: (list) => Chip(
                  label: Text(
                    '${list.length} TOTAL',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: AppTheme.borderLight),
                ),
                loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Records List
          investigatorsAsync.when(
            data: (investigators) => Column(
              children: investigators.map((inv) => _buildInvestigatorCard(inv)).toList(),
            ),
            loading: () => const Center(child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            )),
            error: (err, stack) => Center(child: Text('Error loading investigators: $err')),
          ),
        ],
      ),
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
          backgroundColor: AppTheme.primary.withOpacity(0.05),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildActivityCard(SyncState syncState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6), // Blue from screenshot
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
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
                    'Activity Overview',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const Text(
                    '1,240 Records',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  if (syncState.unsyncedCount > 0)
                    Text(
                      '${syncState.unsyncedCount} records waiting to sync',
                      style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.analytics_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Bar Chart Simulation
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBar(0.5, 'M'),
              _buildBar(0.7, 'T'),
              _buildBar(0.4, 'W'),
              _buildBar(0.95, 'T', isActive: true),
              _buildBar(0.6, 'F'),
              _buildBar(0.3, 'S'),
              _buildBar(0.8, 'S'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, String label, {bool isActive = false}) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 100 * height,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
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
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search records, investigators...',
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }

  Widget _buildInvestigatorCard(Investigator investigator) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(image: NetworkImage(investigator.imageUrl), fit: BoxFit.cover),
                ),
              ),
              Positioned(
                bottom: -2,
                right: -2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: investigator.status == InvestigatorStatus.online ? Colors.green : Colors.grey.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      investigator.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'ID: ${investigator.id}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on, size: 12, color: AppTheme.textLight),
                    Text(
                      investigator.location,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
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
