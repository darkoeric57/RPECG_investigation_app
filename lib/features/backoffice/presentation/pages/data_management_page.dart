import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/add_infrastructure_dialog.dart';
import '../providers/backoffice_providers.dart';
import '../../../../features/meters/domain/meter.dart';
import '../../../../core/utils/web_utils.dart';
import '../widgets/refresh_sync_button.dart';

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
            _buildAnalyticsSection(context, ref),
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
        Consumer(
          builder: (context, ref, child) {
            final total = ref.watch(totalMetersCountProvider);
            return Text(
              'Managing $total active nodes across Northwest Region',
              style: TextStyle(color: AppTheme.textMedium.withValues(alpha: 0.8), fontSize: 16),
            );
          },
        ),
      ],
    );
  }

  Widget _buildFiltersAndActions(BuildContext context, WidgetRef ref, AsyncValue<List<Meter>> metersAsync) {
    return Row(
      children: [
        _buildPremiumFilterButton(context, ref),
        const SizedBox(width: 16),
        _buildAddDataButton(context, ref),
        const Spacer(),
        // Export CSV
        GestureDetector(
          onTap: () {
            final meters = ref.read(filteredMetersProvider);
            if (meters.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export.')));
              return;
            }
            final csv = StringBuffer('Customer,Meter ID,Phone Number,Findings,Bill Amount,Paid Amount\n');
            for (final m in meters) {
              final findings = m.findings ?? 'None';
              final debt = m.debtAmount ?? 0.0;
              final paid = m.paidAmount ?? 0.0;
              csv.writeln('"${m.customerName}","${m.id}","${m.telephone}","$findings","GHS ${debt.toStringAsFixed(2)}","GHS ${paid.toStringAsFixed(2)}"');
            }
            WebUtils.downloadFile('infrastructure_report.csv', csv.toString());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Export started — check your downloads.'), backgroundColor: Colors.green),
            );
          },
          child: _buildActionSecondary(Icons.upload_outlined, 'Export Data'),
        ),
        const SizedBox(width: 16),
        const SizedBox(width: 16),
        // Refresh Sync (Animated)
        const RefreshSyncButton(),
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

  Widget _buildPremiumFilterButton(BuildContext context, WidgetRef ref) {
    final statusFilters = ref.watch(meterStatusFilterSetProvider);
    final findingsFilters = ref.watch(meterFindingsFilterSetProvider);

    int activeCount = statusFilters.length + findingsFilters.length;

    return GestureDetector(
      onTap: () => Scaffold.of(context).openEndDrawer(),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: activeCount > 0 ? AppTheme.primary.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: activeCount > 0 ? AppTheme.primary : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 18, color: activeCount > 0 ? AppTheme.primary : const Color(0xFF64748B)),
            const SizedBox(width: 8),
            Text(
              'Filters',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: activeCount > 0 ? AppTheme.primary : const Color(0xFF1E293B),
              ),
            ),
            if (activeCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                child: Text(
                  activeCount.toString(),
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddDataButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.1),
        builder: (_) => const AddInfrastructureDialog(),
      ),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, Color(0xFF818CF8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'ADD DATA',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
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
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
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
              itemBuilder: (context, index) => _buildTableRow(context, ref, index, meters[index]),
            ),
          ),
          _buildTableFooter(meters.length, ref),
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
          _buildHeadCell('CUSTOMER', 1.2),
          const SizedBox(width: 32),
          _buildHeadCell('METER ID', 1.0),
          const SizedBox(width: 32),
          _buildHeadCell('PHONE NUMBER', 1.0),
          const SizedBox(width: 32),
          _buildHeadCell('FINDINGS', 1.1),
          const SizedBox(width: 32),
          _buildHeadCell('BILL AMOUNT', 0.9),
          const SizedBox(width: 32),
          _buildHeadCell('PAID', 1.0),
          const SizedBox(width: 32),
          _buildHeadCell('STATUS', 0.8),
          const SizedBox(width: 32),
          _buildHeadCell('ACTIONS', 0.5, Alignment.centerRight),
        ],
      ),
    );
  }

  Widget _buildHeadCell(String label, num flex, [Alignment alignment = Alignment.centerLeft]) {
    return Expanded(
      flex: (flex * 10).toInt(),
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

  Widget _buildTableRow(BuildContext context, WidgetRef ref, int index, Meter meter) {
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
          // 1. CUSTOMER - Flex 1.2
          Expanded(
            flex: 12,
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
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    meter.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),
          // 2. METER ID - Flex 1.0
          Expanded(
            flex: 10,
            child: Text(
              meter.id,
              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 32),
          // 3. PHONE - Flex 1.0
          Expanded(
            flex: 10,
            child: Text(
              meter.telephone,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Color(0xFF64748B)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 32),
          // 4. FINDINGS - Flex 1.1
          Expanded(
            flex: 11,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (meter.findings ?? '').isNotEmpty && (meter.findings ?? '').toLowerCase().contains('critical') 
                    ? const Color(0xFFFEF2F2) 
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                (meter.findings ?? '').isEmpty ? 'No significant findings' : meter.findings!,
                style: TextStyle(
                  color: (meter.findings ?? '').isNotEmpty && (meter.findings ?? '').toLowerCase().contains('critical') 
                      ? const Color(0xFFB91C1C) 
                      : const Color(0xFF64748B),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 32),
          // 6. BILL AMOUNT - Flex 0.9
          Expanded(
            flex: 9,
            child: Text(
              'GHS ${(meter.debtAmount ?? 0.0).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF334155)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 32),
          // 7. PAID - Flex 1.0 (NEW)
          Expanded(
            flex: 10,
            child: Text(
              'GHS ${(meter.paidAmount ?? 0.0).toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF10B981)),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 32),
          // 8. STATUS - Flex 0.8
          Expanded(
            flex: 8,
            child: _buildStatusBadge(meter.status),
          ),
          const SizedBox(width: 32),
          // 9. ACTIONS - Flex 0.5
          Expanded(
            flex: 5,
            child: Container(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFFCBD5E1)),
                tooltip: 'Actions',
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'edit') {
                    ref.read(selectedMeterProvider.notifier).state = meter;
                    ref.read(backofficePageProvider.notifier).state = BackofficePage.editInvestigation;
                  } else if (value == 'summary') {
                    ref.read(selectedMeterProvider.notifier).state = meter;
                    ref.read(backofficePageProvider.notifier).state = BackofficePage.meterDetails;
                  } else if (value == 'delete') {
                    _showDeleteConfirmationDialog(context, ref, meter);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_note_rounded, size: 18, color: AppTheme.secondary),
                        SizedBox(width: 12),
                        Text('Edit Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'summary',
                    child: Row(
                      children: [
                        Icon(Icons.summarize_outlined, size: 18, color: AppTheme.primary),
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
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, WidgetRef ref, Meter meter) {
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
                    // Meter Info Chip
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
                          const Icon(Icons.account_balance_rounded, color: Color(0xFF64748B), size: 16),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              '${meter.customerName} (${meter.id})',
                              style: const TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
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
                          const TextSpan(text: 'all investigation records and historical data for this node. There is no recovery for this operation.'),
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
                            final deleteAction = ref.read(deleteMeterActionProvider);
                            await deleteAction(meter.objectId!);
                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text('Record for ${meter.customerName} securely removed.')),
                                    ],
                                  ),
                                  backgroundColor: const Color(0xFF1E293B),
                                  behavior: SnackBarBehavior.floating,
                                  width: 400,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Failed to delete node. Encryption mismatch or link failure.'),
                                  backgroundColor: const Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                  width: 400,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delete_forever_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('Secure Delete', style: TextStyle(fontWeight: FontWeight.w900)),
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
      case MeterStatus.paid:
        color = const Color(0xFF10B981); // Emerald 500
        label = 'PAID';
        break;
      case MeterStatus.pending:
        color = const Color(0xFFF59E0B); // Amber 500
        label = 'PENDING';
        break;
      case MeterStatus.billed:
        color = const Color(0xFF6366F1); // Indigo 500
        label = 'BILLED';
        break;
      case MeterStatus.scheduled:
        color = const Color(0xFFA855F7); // Purple 500
        label = 'SCHEDULED';
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
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTableFooter(int total, WidgetRef ref) {
    final overallTotal = ref.watch(totalMetersCountProvider);
    final isPlural = total != 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing $total of $overallTotal node${isPlural ? 's' : ''}',
            style: TextStyle(color: AppTheme.textLight, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (int.tryParse(overallTotal) != null && int.parse(overallTotal) > 10)
            Row(
              children: [
                _buildPagerArrow(Icons.chevron_left_rounded, false),
                const SizedBox(width: 16),
                _buildPagerNumber('1', true),
                const SizedBox(width: 8),
                const Text('...', style: TextStyle(color: Color(0xFF94A3B8))),
                const SizedBox(width: 8),
                _buildPagerNumber(((int.parse(overallTotal) / 10).ceil()).toString(), false),
                const SizedBox(width: 16),
                _buildPagerArrow(Icons.chevron_right_rounded, true),
              ],
            )
          else
            const Text(
              'End of records',
              style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12, fontWeight: FontWeight.bold),
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

  Widget _buildAnalyticsSection(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildConsumptionTrend(ref),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 1,
          child: _buildSecurityCard(),
        ),
      ],
    );
  }

  Widget _buildConsumptionTrend(WidgetRef ref) {
    final activity = ref.watch(meterActivityByDayProvider);
    final days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    final maxActivity = activity.isEmpty ? 1.0 : activity.reduce((a, b) => a > b ? a : b);
    final normalization = maxActivity == 0 ? 1.0 : maxActivity;

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
                'Regional Activity Trend',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.analytics_outlined, size: 14, color: Color(0xFF166534)),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE DATA',
                      style: TextStyle(color: const Color(0xFF166534).withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.w900),
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
              children: List.generate(7, (index) {
                final heightFactor = activity[index] / normalization;
                return _buildBar(days[index], heightFactor, isActive: DateTime.now().weekday - 1 == index);
              }),
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
