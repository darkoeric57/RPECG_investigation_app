import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers.dart';
import '../domain/meter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class MeterDetailsScreen extends ConsumerWidget {
  final String meterId;

  const MeterDetailsScreen({super.key, required this.meterId});

  Future<void> _shareMeter(Meter meter) async {
    final csv = 'Meter ID,Customer Name,Address,Status\n${meter.id},"${meter.customerName}","${meter.address}",${meter.status.name}';
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/meter_${meter.id}.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'Installation Record: ${meter.id}');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metersAsync = ref.watch(metersProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Record Details'),
        actions: [
          metersAsync.when(
            data: (meters) {
              final meter = meters.where((m) => m.id == meterId).firstOrNull;
              if (meter == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () => _shareMeter(meter),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: metersAsync.when(
        data: (meters) {
          final meter = meters.where((m) => m.id == meterId).firstOrNull;
          if (meter == null) {
            return const Center(child: Text('Record not found'));
          }
          return _buildDetails(context, meter);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildDetails(BuildContext context, Meter meter) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildStatusHeader(meter),
        const SizedBox(height: 32),
        _buildSection('Customer Information', [
          _buildInfoRow('Full Name', meter.customerName),
          _buildInfoRow('Address', meter.address),
          _buildInfoRow('Telephone', meter.telephone),
          _buildInfoRow('Tariff Class', meter.tariffClass),
          _buildInfoRow('Tariff Activity', meter.tariffActivity.name.toUpperCase()),
        ]),
        const SizedBox(height: 24),
        _buildSection('Technical Specifications', [
          _buildInfoRow('Meter ID', meter.id),
          _buildInfoRow('Brand', meter.brand),
          _buildInfoRow('Rating', meter.rating),
          _buildInfoRow('Phase', meter.phase.name.toUpperCase()),
          _buildInfoRow('Metering Type', meter.type.name.toUpperCase()),
          _buildInfoRow('SPN Number', meter.spnNumber),
        ]),
        const SizedBox(height: 24),
        _buildSection('Geolocation & Metadata', [
          _buildInfoRow('Geocode', meter.geocode),
          _buildInfoRow('Coordinates', meter.gpsCoordinates),
          _buildInfoRow('Installed On', meter.installationDate.toString().split(' ')[0]),
          _buildInfoRow('Sync Status', meter.isSynced ? 'SYNCED' : 'PENDING SYNC', 
            valueColor: meter.isSynced ? Colors.green : AppTheme.accent),
        ]),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStatusHeader(Meter meter) {
    Color statusColor;
    switch (meter.status) {
      case MeterStatus.active: statusColor = Colors.green; break;
      case MeterStatus.pending: statusColor = Colors.orange; break;
      case MeterStatus.faulty: statusColor = Colors.red; break;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt, color: statusColor, size: 32),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meter.id,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  meter.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12, 
                    fontWeight: FontWeight.bold, 
                    color: statusColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          if (meter.isSynced)
            const Icon(Icons.cloud_done_outlined, color: Colors.blue, size: 24),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.bold, 
            color: AppTheme.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderLight.withOpacity(0.5)),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textLight),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13, 
              fontWeight: FontWeight.w600, 
              color: valueColor ?? AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
