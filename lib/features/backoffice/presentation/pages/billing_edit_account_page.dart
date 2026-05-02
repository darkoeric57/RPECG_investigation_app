import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:files/features/backoffice/presentation/providers/backoffice_providers.dart';
import 'package:files/core/theme/app_theme.dart';

class BillingEditAccountPage extends ConsumerStatefulWidget {
  const BillingEditAccountPage({super.key});

  @override
  ConsumerState<BillingEditAccountPage> createState() => _BillingEditAccountPageState();
}

class _BillingEditAccountPageState extends ConsumerState<BillingEditAccountPage> {
  late TextEditingController _nameCtrl;
  late TextEditingController _meterCtrl;
  late TextEditingController _accountCtrl;
  late TextEditingController _consumptionCtrl;
  late TextEditingController _balanceCtrl;
  late TextEditingController _totalAmountCtrl;
  late TextEditingController _scheduledDateCtrl;
  late TextEditingController _createdDateCtrl;
  late TextEditingController _remarksCtrl;
  late TextEditingController _fraudStatusCtrl;
  String _selectedStatus = 'Pending';
  String _selectedTariff = 'Residential';
  bool _saving = false;

  static const _statuses = ['Paid', 'Pending', 'Overdue', 'Scheduled'];
  static const _tariffs = ['Residential', 'Non-Residential'];

  @override
  void initState() {
    super.initState();
    final account = ref.read(selectedBillingAccountProvider);
    _nameCtrl = TextEditingController(text: account?['name'] ?? '');
    _meterCtrl = TextEditingController(text: account?['meter'] ?? '');
    _accountCtrl = TextEditingController(text: account?['account'] ?? '');
    _consumptionCtrl = TextEditingController(text: account?['consumption'] ?? '');
    
    // In Billing Dashboard, 'balance' usually contains the outstanding amount.
    // We'll treat it as 'paid' vs 'total' in the new module.
    final currentBalance = account?['balance']?.replaceFirst('GHS ', '').replaceAll(',', '') ?? '0.00';
    _balanceCtrl = TextEditingController(text: currentBalance);
    _totalAmountCtrl = TextEditingController(text: account?['total_amount'] ?? '0');
    _scheduledDateCtrl = TextEditingController(text: account?['scheduled'] ?? '');
    _createdDateCtrl = TextEditingController(text: account?['created_at'] ?? '');
    _fraudStatusCtrl = TextEditingController(text: account?['fraud_status'] ?? 'Normal');
    _remarksCtrl = TextEditingController(text: 'Customer reports inconsistencies in recent billing cycle. Verification required.');
    _selectedStatus = account?['status'] ?? 'Pending';
    _selectedTariff = account?['tariff'] ?? 'Residential';

    // Add listeners for real-time recalculation
    _totalAmountCtrl.addListener(() => setState(() {}));
    _balanceCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _meterCtrl.dispose(); _accountCtrl.dispose();
    _consumptionCtrl.dispose(); _balanceCtrl.dispose(); _totalAmountCtrl.dispose();
    _scheduledDateCtrl.dispose(); _createdDateCtrl.dispose();
    _fraudStatusCtrl.dispose();
    _remarksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(selectedBillingAccountProvider);
    if (account == null) return const Center(child: Text("No account selected"));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopNavigation(context),
            const SizedBox(height: 32),
            _buildHeader(context, account),
            const SizedBox(height: 48),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Identity & Status
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildIdentityCard(account),
                      const SizedBox(height: 32),
                      _buildStatusSelector(),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
                // Right Column: Payment & Remarks
                Expanded(
                  flex: 7,
                  child: Column(
                    children: [
                      _buildPaymentModule(),
                      const SizedBox(height: 32),
                      _buildBillingDetailsModule(),
                      const SizedBox(height: 32),
                      _buildRemarksModule(),
                    ],
                  ),
                ),
              ],
            ),
            _buildFooterMeta(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNavigation(BuildContext context) {
    return InkWell(
      onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingDashboard,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              'Back to Billing Intelligence',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontFamily: 'Manrope',
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Map<String, String> account) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Billing Intelligence', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Text('Edit Account', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Edit Account: ${account['name']}',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: AppTheme.primary,
                fontFamily: 'Manrope',
                letterSpacing: -1.5,
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildHeaderButton(
              label: 'Cancel',
              icon: Icons.close_rounded,
              onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingDashboard,
              isSecondary: true,
            ),
            const SizedBox(width: 16),
            _buildHeaderButton(
              label: _saving ? 'Saving...' : 'Save Changes',
              icon: Icons.save_rounded,
              onTap: () async {
                if (_saving) return;
                setState(() => _saving = true);
                await Future.delayed(const Duration(milliseconds: 1500));
                if (mounted) {
                  setState(() => _saving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account changes synchronized successfully'), backgroundColor: AppTheme.primary),
                  );
                  ref.read(backofficePageProvider.notifier).state = BackofficePage.billingDashboard;
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderButton({required String label, required IconData icon, required VoidCallback onTap, bool isSecondary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        decoration: BoxDecoration(
          color: isSecondary ? Colors.white : AppTheme.error,
          borderRadius: BorderRadius.circular(100),
          border: isSecondary ? Border.all(color: const Color(0xFFC5C5D3), width: 2) : null,
          boxShadow: isSecondary ? null : [
            BoxShadow(
              color: AppTheme.error.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSecondary ? AppTheme.textDark : Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSecondary ? AppTheme.textDark : Colors.white,
                fontWeight: FontWeight.w800,
                fontFamily: 'Manrope',
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityCard(Map<String, String> account) {
    final initials = account['name']!.split(' ').map((e) => e[0]).take(2).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: const TextStyle(color: AppTheme.primary, fontSize: 32, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  account['name']!,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 16),
                    const SizedBox(width: 6),
                    Text(account['tariff'] ?? 'Residential', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildIdentityBadge('ACCOUNT NO.', account['account']!),
                    const SizedBox(width: 16),
                    _buildIdentityBadge('METER ID', account['meter']!),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentityBadge(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primary, fontFamily: 'Manrope')),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F3F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Update Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary, fontFamily: 'Manrope')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.3)),
                ),
                child: const Text('ACTION REQUIRED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF726200))),
              ),
            ],
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatusCard('Pending', Icons.hourglass_empty_rounded),
              _buildStatusCard('Overdue', Icons.error_outline_rounded),
              _buildStatusCard('Scheduled', Icons.calendar_today_rounded),
              _buildStatusCard('Paid', Icons.check_circle_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status, IconData icon) {
    final isActive = _selectedStatus == status;

    return InkWell(
      onTap: () => setState(() => _selectedStatus = status),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E3A8A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? AppTheme.secondary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isActive ? [
            BoxShadow(color: AppTheme.primary.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))
          ] : [
            BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isActive ? AppTheme.secondary : const Color(0xFF64748B)),
            ),
            const Spacer(),
            Text(
              status,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : AppTheme.textDark,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 32,
                decoration: BoxDecoration(color: AppTheme.secondary, borderRadius: BorderRadius.circular(2)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentModule() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 16),
                  const Text('Financial Information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Manrope')),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Icon(_getStatusIcon(_selectedStatus), color: AppTheme.secondary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _selectedStatus.toUpperCase(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('OUTSTANDING (GHS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _balanceCtrl,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Manrope'),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFE2E2E4),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        suffixIcon: const Icon(Icons.edit_rounded, color: AppTheme.primary),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppTheme.primary, size: 18),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'The outstanding balance is the primary amount tracked for this billing cycle.',
                              style: TextStyle(color: Color(0xFF264191), fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Expanded(
                child: _buildBalanceSummary(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSummary() {
    final double totalAmount = double.tryParse(_totalAmountCtrl.text) ?? 0.0;
    final double amountPaid = double.tryParse(_balanceCtrl.text) ?? 0.0;
    final double outstanding = totalAmount - amountPaid;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BALANCE SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
          const SizedBox(height: 32),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(child: Text('Total Amount', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13))),
              SizedBox(
                width: 80,
                child: TextField(
                  controller: _totalAmountCtrl,
                  textAlign: TextAlign.end,
                  style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontFamily: 'Manrope'),
                  decoration: const InputDecoration(
                    hintText: 'GHS 0.00',
                    border: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildSummaryRow('Initial Amount', 'GHS ${totalAmount.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Outstanding', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'GHS ${outstanding.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Manrope'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppTheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(100)),
                      child: Text(
                        outstanding > 0 ? 'DUE IN 3 DAYS' : 'SETTLED',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: outstanding > 0 ? AppTheme.error : Colors.green, letterSpacing: -0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isNegative = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(child: Text(label, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13))),
        Text(value, style: TextStyle(color: isNegative ? AppTheme.primary : AppTheme.textDark, fontWeight: FontWeight.w800, fontFamily: 'Manrope')),
      ],
    );
  }

  Widget _buildRemarksModule() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.history_edu_rounded, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              const Text('Billing Remarks & Notes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Manrope')),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              TextField(
                controller: _remarksCtrl,
                maxLines: 6,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE2E2E4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  hintText: 'Enter billing observations or verification notes...',
                  contentPadding: const EdgeInsets.all(24),
                ),
                style: const TextStyle(fontSize: 15, height: 1.6, color: AppTheme.textDark),
              ),
              Positioned(
                bottom: 24,
                right: 24,
                child: Opacity(
                  opacity: 0.6,
                  child: Row(
                    children: [
                      const Icon(Icons.attachment_rounded, size: 18),
                      const SizedBox(width: 8),
                      const Text('ATTACH DOCUMENTS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'NO ATTACHMENTS FOUND FOR THIS BILLING CYCLE',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingDetailsModule() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.analytics_rounded,
                    color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              const Text('Billing Cycle Details',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primary,
                      fontFamily: 'Manrope')),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'CONSUMPTION',
                  controller: _consumptionCtrl,
                  hint: 'Enter consumption value',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildTextField(
                  label: 'FRAUD STATUS',
                  controller: _fraudStatusCtrl,
                  hint: 'Enter fraud status',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  label: 'SCHEDULED',
                  controller: _scheduledDateCtrl,
                  hint: 'DD MMM YYYY',
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildTextField(
                  label: 'CREATED AT',
                  controller: _createdDateCtrl,
                  hint: 'DD MMM YYYY',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required TextEditingController controller,
      required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: Color(0xFF94A3B8),
                letterSpacing: 1.2)),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            hintText: hint,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterMeta() {
    return Padding(
      padding: const EdgeInsets.only(top: 64, bottom: 40),
      child: Column(
        children: [
          const Divider(color: Color(0xFFE2E8F0)),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('System Version: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  const Text('v2.4.0-Premium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                  const SizedBox(width: 24),
                  Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      const Text('Audit Status: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text('ENCRYPTED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                    ],
                  ),
                ],
              ),
              const Row(
                children: [
                  Text('COMPLIANCE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1)),
                  SizedBox(width: 32),
                  Text('SECURITY POLICY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1)),
                  SizedBox(width: 32),
                  Text('SUPPORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Icons.hourglass_empty_rounded;
      case 'Overdue':
        return Icons.error_outline_rounded;
      case 'Scheduled':
        return Icons.calendar_today_rounded;
      case 'Paid':
        return Icons.check_circle_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }
}
