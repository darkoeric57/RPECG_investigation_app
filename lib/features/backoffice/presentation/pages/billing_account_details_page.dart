import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:files/features/backoffice/presentation/providers/backoffice_providers.dart';
import 'package:files/core/theme/app_theme.dart';

class BillingAccountDetailsPage extends ConsumerWidget {
  const BillingAccountDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(selectedBillingAccountProvider);

    if (account == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long_outlined, size: 64, color: Color(0xFFCBD5E1)),
            const SizedBox(height: 16),
            const Text('No account selected', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingDashboard,
              child: const Text('Back to Billing'),
            ),
          ],
        ),
      );
    }

    final status = account['status'] ?? '';
    final isOverdue = status == 'Overdue';
    final isPaid = status == 'Paid';
    final isScheduled = status == 'Scheduled';

    final Color statusColor = isOverdue
        ? const Color(0xFFEF4444)
        : isPaid
            ? const Color(0xFF10B981)
            : isScheduled
                ? const Color(0xFF2563EB)
                : const Color(0xFFD97706);

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
              const Text('ACCOUNT DETAILS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 2.5)),
            ],
          ),
          const SizedBox(height: 48),

          // Header
          Center(
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    account['initials'] ?? '??',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primary),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  account['name'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w800, color: AppTheme.primary, letterSpacing: -1),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                      child: Text(account['tariff'] ?? '', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF475569), letterSpacing: 0.5)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 56),

          // Balance + Lifecycle cards row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.04), blurRadius: 40, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('OUTSTANDING BALANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2)),
                      const SizedBox(height: 20),
                      Text(
                        account['balance'] ?? 'GHS 0.00',
                        style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: isOverdue ? const Color(0xFFEF4444) : AppTheme.primary, letterSpacing: -1),
                      ),
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 16),
                      _detailRow('Total Amount', account['total_amount'] ?? '0'),
                      const SizedBox(height: 10),
                      _detailRow('Amount Paid', account['amount_paid'] ?? '0'),
                      const SizedBox(height: 10),
                      _detailRow('Created At', account['created_at'] ?? '—'),
                      const SizedBox(height: 10),
                      _detailRow('Date Scheduled', account['scheduled'] ?? '—'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Meter info card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.04), blurRadius: 40, offset: const Offset(0, 10))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('METER INFORMATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2)),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                        child: Text(account['meter'] ?? '—', style: const TextStyle(fontFamily: 'monospace', fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                      ),
                      const SizedBox(height: 24),
                      _detailRow('Account No.', account['account'] ?? '—'),
                      const SizedBox(height: 10),
                      _detailRow('Consumption (kWh)', account['consumption'] ?? '—'),
                      const SizedBox(height: 10),
                      _detailRow('Fraud Type', account['fraud_status'] ?? '—'),
                      const SizedBox(height: 10),
                      _detailRow('Fraud Bill Status', account['fraud_bill_status'] ?? '—'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Status enforcement card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: isOverdue ? const Color(0xFFFEF2F2) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border(bottom: BorderSide(color: statusColor, width: 4)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isOverdue ? Icons.gavel_rounded : isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                        size: 40, color: statusColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isOverdue ? 'PAYMENT OVERDUE' : isPaid ? 'PAYMENT CLEARED' : isScheduled ? 'PAYMENT SCHEDULED' : 'PAYMENT PENDING',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isOverdue ? 'Immediate action required.' : isPaid ? 'Account is settled.' : isScheduled ? 'Instalment in progress.' : 'Awaiting payment confirmation.',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: statusColor),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Payment timeline card
          Container(
            padding: const EdgeInsets.all(32),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('FRAUD BILL LIFECYCLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 2)),
                        SizedBox(height: 4),
                        Text('Current fraud bill progress', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF726200), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text('STATUS: ${(account['fraud_bill_status'] ?? 'UNKNOWN').toUpperCase()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF726200))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const steps = ['Billed', 'Pending', 'Scheduled', 'Paid'];
                    final fbs = (account['fraud_bill_status'] ?? '').toString().toLowerCase();
                    final activeIndex = fbs.contains('paid') ? 3 : fbs.contains('sched') ? 2 : fbs.contains('pend') ? 1 : 0;
                    return Stack(
                      children: [
                        Positioned(top: 20, left: 40, right: 40, child: Container(height: 2, color: const Color(0xFFF1F5F9))),
                        Positioned(top: 20, left: 40, width: (constraints.maxWidth - 80) * (activeIndex / 3), child: Container(height: 2, color: AppTheme.primary)),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: steps.asMap().entries.map((e) {
                            final active = e.key <= activeIndex;
                            return Column(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: active ? AppTheme.primary : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 4),
                                    boxShadow: active ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5))] : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text('${e.key + 1}', style: TextStyle(color: active ? Colors.white : const Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w900)),
                                ),
                                const SizedBox(height: 16),
                                Text(e.value.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: active ? AppTheme.primary : const Color(0xFF64748B), letterSpacing: 1)),
                              ],
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 64),

          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionBtn(
                label: 'EDIT ACCOUNT',
                icon: Icons.edit_note_rounded,
                color: AppTheme.accent,
                textColor: const Color(0xFF00164E),
                onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingEditAccount,
              ),
              const SizedBox(width: 16),
              _ActionBtn(
                label: 'STATUS HISTORY',
                icon: Icons.history_rounded,
                color: AppTheme.primary,
                textColor: Colors.white,
                onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingStatusHistory,
              ),
              const SizedBox(width: 16),
              _ActionBtn(
                label: 'BACK TO BILLING',
                icon: Icons.arrow_back_rounded,
                color: const Color(0xFFF1F5F9),
                textColor: const Color(0xFF475569),
                onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingDashboard,
              ),
            ],
          ),
          const SizedBox(height: 64),
          const Center(
            child: Text(
              'SOVEREIGN UTILITY INTELLIGENCE SYSTEM • BILLING RECORD • CONFIDENTIAL',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFFCBD5E1), letterSpacing: 2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ActionBtn extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.icon, required this.color, required this.textColor, required this.onTap});

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
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
              Text(widget.label, style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
