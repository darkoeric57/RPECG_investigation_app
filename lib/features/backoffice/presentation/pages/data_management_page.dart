import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/backoffice_providers.dart';
import '../../../../features/meters/domain/meter.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/web_utils.dart';

class DataManagementPage extends ConsumerWidget {
  const DataManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meters = ref.watch(filteredMetersProvider);
    final metersAsync = ref.watch(backofficeMetersProvider);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainHeader(),
            const SizedBox(height: 32),
            _buildFiltersAndActions(context, ref, metersAsync),
            const SizedBox(height: 32),
            _buildDataTable(context, meters, metersAsync, ref),
            const SizedBox(height: 40),
            _buildAnalyticsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        _buildSearchField(ref),
        const Spacer(),
        _buildIconButton(Icons.notifications_none_rounded, hasBadge: true),
        const SizedBox(width: 24),
        _buildIconButton(Icons.help_outline_rounded),
        const SizedBox(width: 32),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          child: const Text('Create Task', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 24),
        const CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=backoffice_user'),
        ),
      ],
    );
  }

  Widget _buildSearchField(WidgetRef ref) {
    return Container(
      width: 400,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Slate 100
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        onChanged: (value) => ref.read(meterSearchQueryProvider.notifier).state = value,
        decoration: InputDecoration(
          hintText: 'Search Utility Infrastructure...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, {bool hasBadge = false}) {
    return Stack(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 24),
        if (hasBadge)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }

  Widget _buildMainHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Infrastructure Hub',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppTheme.primary,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Managing 1,284 active nodes across Northwest Region',
          style: TextStyle(color: AppTheme.textMedium.withOpacity(0.8), fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildFiltersAndActions(BuildContext context, WidgetRef ref, AsyncValue<List<Meter>> metersAsync) {
    final statusFilter = ref.watch(meterStatusFilterProvider);
    final isLoading = metersAsync is AsyncLoading;

    final statusOptions = <String, MeterStatus?>{
      'All Statuses': null,
      'Operational': MeterStatus.active,
      'Low Throughput': MeterStatus.pending,
      'Critical Failure': MeterStatus.faulty,
    };

    return Row(
      children: [
        // STATUS filter dropdown
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
            const SizedBox(height: 8),
            PopupMenuButton<MeterStatus?>(
              onSelected: (val) => ref.read(meterStatusFilterProvider.notifier).state = val,
              itemBuilder: (_) => statusOptions.entries
                  .map((e) => PopupMenuItem(value: e.value, child: Text(e.key)))
                  .toList(),
              child: Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: statusFilter != null ? AppTheme.primary.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusFilter != null ? AppTheme.primary.withOpacity(0.4) : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      statusOptions.entries.firstWhere((e) => e.value == statusFilter).key,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: statusFilter != null ? AppTheme.primary : const Color(0xFF1E293B)),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 24),
        _buildFilterDropdown('REGION', 'All Regions'),
        const Spacer(),
        // Export CSV
        GestureDetector(
          onTap: () {
            final meters = ref.read(filteredMetersProvider);
            if (meters.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export.')));
              return;
            }
            final csv = StringBuffer('Meter ID,Customer,Address,Status\n');
            for (final m in meters) {
              csv.writeln('${m.id},${m.customerName},${m.address},${m.status.name}');
            }
            WebUtils.downloadFile('meters_export.csv', csv.toString());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export started — check your downloads.'), backgroundColor: Colors.green),
            );
          },
          child: _buildActionSecondary(Icons.upload_outlined, 'Export Data'),
        ),
        const SizedBox(width: 16),
        // Refresh Sync
        GestureDetector(
          onTap: isLoading ? null : () {
            ref.invalidate(backofficeMetersProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Syncing data from server...'), duration: Duration(seconds: 2)),
            );
          },
          child: _buildActionPrimary(
            isLoading ? Icons.hourglass_top_rounded : Icons.sync_rounded,
            isLoading ? 'Syncing...' : 'Refresh Sync',
          ),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(String label, String value, {bool isDatePicker = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(width: 12),
              Icon(
                isDatePicker ? Icons.calendar_today_rounded : Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: const Color(0xFF64748B),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionSecondary(IconData icon, String label) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF475569)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildActionPrimary(IconData icon, String label) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE047), // Yellow 300
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: AppTheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(BuildContext context, List<Meter> meters, AsyncValue<List<Meter>> metersAsync, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildTableHead(),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          metersAsync.when(
            loading: () => const SizedBox(height: 400, child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => SizedBox(height: 400, child: Center(child: Text('Error: $err'))),
            data: (_) => ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: meters.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF8FAFC)),
              itemBuilder: (context, index) => _buildTableRow(context, index, meters[index]),
            ),
          ),
          _buildTableFooter(meters.length),
        ],
      ),
    );
  }

  Widget _buildTableHead() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          _buildHeadCell('METER ID', 1),
          _buildHeadCell('CUSTOMER', 2),
          _buildHeadCell('ADDRESS', 2),
          _buildHeadCell('EFFICIENCY', 1),
          _buildHeadCell('STATUS', 1),
          _buildHeadCell('ACTIONS', 1, Alignment.centerRight),
        ],
      ),
    );
  }

  Widget _buildHeadCell(String label, int flex, [Alignment alignment = Alignment.centerLeft]) {
    return Expanded(
      flex: flex,
      child: Container(
        alignment: alignment,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, int index, Meter meter) {
    final initials = meter.customerName.split(' ').map((e) => e[0]).take(2).join().toUpperCase();
    final colors = [const Color(0xFFE0E7FF), const Color(0xFFFCD34D), const Color(0xFFFECACA), const Color(0xFFD1FAE5)];
    final avatarColor = colors[index % colors.length];
    final textColor = avatarColor == const Color(0xFFE0E7FF) ? const Color(0xFF4338CA) : 
                     avatarColor == const Color(0xFFFCD34D) ? const Color(0xFF92400E) :
                     avatarColor == const Color(0xFFFECACA) ? const Color(0xFFB91C1C) :
                     const Color(0xFF065F46);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              meter.id,
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 14),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: avatarColor,
                  child: Text(
                    initials,
                    style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meter.customerName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Commercial Plus', // Mock category
                      style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meter.address.split(',').first, 
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Northwest Metro', // Mock region
                  style: TextStyle(color: AppTheme.textLight, fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(right: 32),
              child: _buildEfficiencyBar(index),
            ),
          ),
          Expanded(
            flex: 1, 
            child: _buildStatusBadge(meter.status),
          ),
          Expanded(
            flex: 1,
            child: Container(
              alignment: Alignment.centerRight,
              child: const Icon(Icons.more_horiz_rounded, color: Color(0xFFCBD5E1)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEfficiencyBar(int index) {
    final values = [0.8, 0.4, 0.1, 0.9];
    final value = values[index % values.length];
    final color = value > 0.7 ? AppTheme.primary : value > 0.3 ? const Color(0xFF854D0E) : const Color(0xFFB91C1C);

    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(MeterStatus status) {
    Color color;
    String label;
    switch (status) {
      case MeterStatus.active:
        color = const Color(0xFF22C55E); // Operational
        label = 'OPERATIONAL';
        break;
      case MeterStatus.pending:
        color = const Color(0xFFEAB308); // Low Throughput
        label = 'LOW THROUGHPUT';
        break;
      case MeterStatus.faulty:
        color = const Color(0xFFEF4444); // Critical Failure
        label = 'CRITICAL FAILURE';
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildTableFooter(int total) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing 1 to $total of 1,284 nodes',
            style: TextStyle(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Row(
            children: [
              _buildPagerArrow(Icons.chevron_left_rounded, false),
              const SizedBox(width: 16),
              _buildPagerNumber('1', true),
              const SizedBox(width: 8),
              _buildPagerNumber('2', false),
              const SizedBox(width: 8),
              _buildPagerNumber('3', false),
              const SizedBox(width: 8),
              const Text('...', style: TextStyle(color: Color(0xFF94A3B8))),
              const SizedBox(width: 8),
              _buildPagerNumber('321', false),
              const SizedBox(width: 16),
              _buildPagerArrow(Icons.chevron_right_rounded, true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPagerNumber(String label, bool active) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF64748B),
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildPagerArrow(IconData icon, bool enabled) {
    return Icon(icon, color: enabled ? const Color(0xFFCBD5E1) : const Color(0xFFF1F5F9), size: 24);
  }

  Widget _buildAnalyticsSection(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildConsumptionTrend(),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 1,
          child: _buildSecurityCard(),
        ),
      ],
    );
  }

  Widget _buildConsumptionTrend() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Regional Consumption Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.trending_up, size: 14, color: Color(0xFF166534)),
                    SizedBox(width: 4),
                    Text(
                      '+12.4%',
                      style: TextStyle(color: Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),
          SizedBox(
            height: 200,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBar('MON', 0.4),
                _buildBar('TUE', 0.6),
                _buildBar('WED', 0.5),
                _buildBar('THU', 0.8),
                _buildBar('FRI', 1.0, isActive: true),
                _buildBar('SAT', 0.7),
                _buildBar('SUN', 0.4),
                _buildBar('TODAY', 0.9),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(String day, double heightFactor, {bool isActive = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 40,
          height: 160 * heightFactor,
          decoration: BoxDecoration(
            color: isActive ? AppTheme.primary : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          day,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: NetworkImage('https://i.ibb.co/vzYyX1g/security-bg.png'), // Mock pattern
          fit: BoxFit.cover,
          opacity: 0.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE047),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.shield_rounded, color: AppTheme.primary, size: 24),
          ),
          const SizedBox(height: 24),
          const Text(
            'Network Security',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          const SizedBox(height: 12),
          const Text(
            'All encrypted data streams are operating under Protocol v4.2. No anomalies detected in the last 24 hours.',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Run Full Audit', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String titleCase() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}
