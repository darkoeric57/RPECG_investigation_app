import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:files/features/backoffice/presentation/providers/backoffice_providers.dart';
import 'package:files/core/theme/app_theme.dart';
import '../../domain/billing_account.dart';

class BillingStatusHistoryPage extends ConsumerWidget {
  const BillingStatusHistoryPage({super.key});

  Color _statusColor(String s) {
    switch (s) {
      case 'Paid': return const Color(0xFF10B981);
      case 'Overdue': return const Color(0xFFEF4444);
      case 'Scheduled': return const Color(0xFF2563EB);
      case 'Pending': return const Color(0xFFD97706);
      default: return const Color(0xFF64748B);
    }
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'Paid': return Icons.verified_rounded;
      case 'Overdue': return Icons.warning_amber_rounded;
      case 'Scheduled': return Icons.calendar_today_rounded;
      case 'Pending': return Icons.hourglass_top_rounded;
      default: return Icons.receipt_long_rounded;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(selectedBillingAccountProvider);
    final name = account?.name ?? 'Unknown Account';
    final historyAsync = account != null 
        ? ref.watch(billingAccountHistoryProvider(account.account))
        : const AsyncValue<List<BillingAccount>>.data([]);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              GestureDetector(
                onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingDashboard,
                child: const Text('BILLING INTELLIGENCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2.5)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingAccountDetails,
                child: const Text('ACCOUNT DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2.5)),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 8),
              const Text('STATUS HISTORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 2.5)),
            ],
          ),
          const SizedBox(height: 48),

          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.history_rounded, color: AppTheme.primary, size: 32),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Status History', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: -1)),
                  Text(name, style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4))],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.download_rounded, color: AppTheme.primary, size: 16),
                    SizedBox(width: 8),
                    Text('EXPORT HISTORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 1)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 48),

          // Summary stats
          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (historyList) {
              final history = historyList.isNotEmpty ? historyList : []; // Can fallback to _history if empty for demo
              return Column(
                children: [
                  Row(
                    children: [
                      _StatCard(label: 'TOTAL EVENTS', value: '${history.length}', icon: Icons.timeline_rounded, color: AppTheme.primary),
                      const SizedBox(width: 20),
                      _StatCard(label: 'OVERDUE FLAGS', value: '${history.where((h) => h.status == 'Overdue').length}', icon: Icons.warning_amber_rounded, color: const Color(0xFFEF4444)),
                      const SizedBox(width: 20),
                      _StatCard(label: 'SCHEDULED EVENTS', value: '${history.where((h) => h.status == 'Scheduled').length}', icon: Icons.calendar_today_rounded, color: const Color(0xFF2563EB)),
                      const SizedBox(width: 20),
                      _StatCard(label: 'DAYS TRACKED', value: history.isEmpty ? '0' : '21', icon: Icons.date_range_rounded, color: const Color(0xFF7C3AED)),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Timeline
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF1F5F9)),
                      boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.04), blurRadius: 40, offset: const Offset(0, 10))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.timeline_rounded, color: AppTheme.primary, size: 20),
                            ),
                            const SizedBox(width: 16),
                            const Text('BILLING STATUS TIMELINE', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: -0.5)),
                          ],
                        ),
                        const SizedBox(height: 40),
                        if (history.isEmpty)
                          const Center(child: Padding(
                            padding: EdgeInsets.all(40.0),
                            child: Text('No historical records found for this account.'),
                          ))
                        else
                          ...history.asMap().entries.map((entry) {
                            final i = entry.key;
                            final item = entry.value;
                            final isLast = i == history.length - 1;
                            final color = _statusColor(item.status);
                            final dateStr = item.importedAt != null 
                                ? '${item.importedAt!.day} ${_getMonth(item.importedAt!.month)} ${item.importedAt!.year}'
                                : item.createdAt;

                            return IntrinsicHeight(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Timeline spine
                                  SizedBox(
                                    width: 48,
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 44, height: 44,
                                          decoration: BoxDecoration(
                                            color: color.withValues(alpha: 0.1),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: color.withValues(alpha: 0.4), width: 2),
                                          ),
                                          child: Icon(_getIconForStatus(item.status), color: color, size: 20),
                                        ),
                                        if (!isLast)
                                          Expanded(
                                            child: Container(
                                              width: 2,
                                              margin: const EdgeInsets.symmetric(vertical: 4),
                                              color: const Color(0xFFF1F5F9),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // Content
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
                                      child: Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(color: const Color(0xFFEEEEF0)),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: color.withValues(alpha: 0.1),
                                                          borderRadius: BorderRadius.circular(20),
                                                          border: Border.all(color: color.withValues(alpha: 0.3)),
                                                        ),
                                                        child: Text(item.status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: color, letterSpacing: 1)),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(dateStr, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                    'Snapshot from billing cycle. Fraud Status: ${item.fraudStatus}. Tariff: ${item.tariff}.', 
                                                    style: const TextStyle(fontSize: 13, color: Color(0xFF475569), fontWeight: FontWeight.w500, height: 1.5)
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 20),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                const Text('OUTSTANDING', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'GHS ${item.balance}',
                                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: item.status == 'Overdue' ? const Color(0xFFEF4444) : AppTheme.primary),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),

          // Back buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _NavBtn(
                label: 'ACCOUNT DETAILS',
                icon: Icons.info_outline_rounded,
                onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingAccountDetails,
                primary: false,
              ),
              const SizedBox(width: 16),
              _NavBtn(
                label: 'BACK TO BILLING',
                icon: Icons.arrow_back_rounded,
                onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingDashboard,
                primary: true,
              ),
            ],
          ),
          const SizedBox(height: 64),
          const Center(
            child: Text(
              'SOVEREIGN UTILITY INTELLIGENCE SYSTEM • PAYMENT AUDIT LOG • CONFIDENTIAL',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFCBD5E1), letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color, letterSpacing: -1)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;
  const _NavBtn({required this.label, required this.icon, required this.onTap, required this.primary});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: primary ? AppTheme.primary : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: primary ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: primary ? Colors.white : const Color(0xFF475569), size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: primary ? Colors.white : const Color(0xFF475569), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}
