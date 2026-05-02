import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/backoffice_providers.dart';
import '../../../../features/meters/domain/meter.dart';
import '../../domain/installment.dart';
import 'package:intl/intl.dart';

class EditInvestigationPage extends ConsumerStatefulWidget {
  const EditInvestigationPage({super.key});

  @override
  ConsumerState<EditInvestigationPage> createState() => _EditInvestigationPageState();
}

class _EditInvestigationPageState extends ConsumerState<EditInvestigationPage> {
  final _amountController = TextEditingController();
  final _totalChargesController = TextEditingController();
  final _remarksController = TextEditingController();
  MeterStatus? _selectedStatus;
  List<Installment> _installments = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final meter = ref.read(selectedMeterProvider);
    if (meter != null) {
      _totalChargesController.text = (meter.debtAmount ?? 0.0).toStringAsFixed(2);
      _amountController.text = (meter.paidAmount ?? 0.0).toStringAsFixed(2);
      _remarksController.text = meter.findings ?? '';
      _selectedStatus = meter.status;
      _installments = List.from(meter.installments ?? []);

      // Add listeners for real-time recalculation
      _totalChargesController.addListener(() => setState(() {}));
      _amountController.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _totalChargesController.dispose();
    _amountController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meter = ref.watch(selectedMeterProvider);
    if (meter == null) return const Center(child: Text("No investigation selected"));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopNavigation(context),
            const SizedBox(height: 32),
            _buildHeader(context, meter),
            const SizedBox(height: 48),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Identity & Status
                Expanded(
                  flex: 5,
                  child: Column(
                    children: [
                      _buildIdentityCard(meter),
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
                      if (_selectedStatus == MeterStatus.scheduled && _installments.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        _buildInstallmentTimeline(),
                      ],
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
      onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.dataManagement,
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
              'Back to Investigations',
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

  Widget _buildHeader(BuildContext context, Meter meter) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Case Management', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                const SizedBox(width: 8),
                Text('Edit Investigation', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w900)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Edit Case: ${meter.customerName}',
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
              onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.dataManagement,
              isSecondary: true,
            ),
            const SizedBox(width: 16),
            _buildHeaderButton(
              label: _isSaving ? 'Saving...' : 'Save Changes',
              icon: Icons.save_rounded,
              onTap: () async {
                if (_isSaving) return;
                
                setState(() => _isSaving = true);
                
                try {
                  final updatedMeter = meter.copyWith(
                    debtAmount: double.tryParse(_totalChargesController.text) ?? 0.0,
                    paidAmount: double.tryParse(_amountController.text) ?? 0.0,
                    findings: _remarksController.text.trim(),
                    status: _selectedStatus,
                    installments: _installments,
                  );
                  
                  await ref.read(addMeterActionProvider)(updatedMeter);
                  
                  if (context.mounted) {
                    ref.read(backofficePageProvider.notifier).state = BackofficePage.dataManagement;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Changes successfully synchronized to cloud'), backgroundColor: AppTheme.primary),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sync failed: $e'), backgroundColor: Colors.red),
                    );
                  }
                } finally {
                  if (mounted) setState(() => _isSaving = false);
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

  Widget _buildIdentityCard(Meter meter) {
    final initials = meter.customerName.split(' ').map((e) => e[0]).take(2).join().toUpperCase();

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
                  meter.customerName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textDark),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: AppTheme.primary, size: 16),
                    const SizedBox(width: 6),
                    Text('Premium Service Account', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildIdentityBadge('SPN NUMBER', '#77422910'),
                    const SizedBox(width: 16),
                    _buildIdentityBadge('METER ID', meter.id),
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
              const Text('Edit Case Status', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary, fontFamily: 'Manrope')),
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
              _buildStatusCard(MeterStatus.pending, Icons.hourglass_empty_rounded, 'Pending'),
              _buildStatusCard(MeterStatus.billed, Icons.receipt_long_rounded, 'Billed'),
              _buildStatusCard(MeterStatus.scheduled, Icons.calendar_today_rounded, 'Scheduled'),
              _buildStatusCard(MeterStatus.paid, Icons.check_circle_rounded, 'Paid'),
            ],
          ),
        ],
      ),
    );
  }

  Future<List<Installment>?> _showInstallmentDialog() {
    final double totalCharges = double.tryParse(_totalChargesController.text) ?? 0.0;
    
    return showDialog<List<Installment>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _InstallmentConfigurator(totalCharges: totalCharges, initialInstallments: _installments),
    );
  }

  Widget _buildInstallmentTimeline() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.04),
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
                    decoration: BoxDecoration(color: AppTheme.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.event_repeat_rounded, color: AppTheme.secondary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text('Payment Schedule', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Manrope')),
                ],
              ),
              InkWell(
                onTap: () async {
                  final result = await _showInstallmentDialog();
                  if (result != null && result.isNotEmpty) {
                    setState(() {
                      _installments = result;
                      _amountController.text = result.first.amount.toStringAsFixed(2);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    children: [
                      Icon(Icons.edit_calendar_rounded, size: 14, color: AppTheme.primary),
                      SizedBox(width: 8),
                      Text('EDIT PLAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary, letterSpacing: 0.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _installments.length,
            separatorBuilder: (context, index) => Container(
              margin: const EdgeInsets.only(left: 20),
              height: 24,
              width: 2,
              color: const Color(0xFFF1F5F9),
            ),
            itemBuilder: (context, index) {
              final ins = _installments[index];
              final isOverdue = ins.dueDate.isBefore(DateTime.now()) && !ins.isPaid;
              
              return Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isOverdue ? AppTheme.error.withValues(alpha: 0.1) : const Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOverdue ? Icons.priority_high_rounded : Icons.calendar_month_rounded, 
                      size: 18, 
                      color: isOverdue ? AppTheme.error : const Color(0xFF94A3B8)
                    ),
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
                              'Installment ${index + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark, fontSize: 13),
                            ),
                            Text(
                              'GH₵ ${ins.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 13, fontFamily: 'Manrope'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(ins.dueDate),
                              style: TextStyle(color: isOverdue ? AppTheme.error : const Color(0xFF64748B), fontSize: 12, fontWeight: isOverdue ? FontWeight.w700 : FontWeight.w500),
                            ),
                            if (isOverdue)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(4)),
                                child: const Text('OVERDUE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
                              )
                            else
                              const Text('PENDING', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(MeterStatus status, IconData icon, String label) {
    final isActive = _selectedStatus == status;

    return InkWell(
      onTap: () async {
        if (status == MeterStatus.scheduled) {
          final result = await _showInstallmentDialog();
          if (result != null && result.isNotEmpty) {
            setState(() {
              _selectedStatus = status;
              _installments = result;
              _amountController.text = result.first.amount.toStringAsFixed(2);
            });
          }
        } else {
          setState(() => _selectedStatus = status);
        }
      },
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
              label,
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
                  const Text('Payment Information', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Manrope')),
                ],
              ),
              if (_selectedStatus != null)
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
                      Icon(_getStatusIcon(_selectedStatus!), color: AppTheme.secondary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _selectedStatus!.name.toUpperCase(),
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
                    const Text('AMOUNT PAID (GH₵)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 2)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
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
                              'Adjusting the \'Amount Paid\' will automatically recalculate the outstanding balance shown in the summary.',
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
    final double totalCharges = double.tryParse(_totalChargesController.text) ?? 0.0;
    final double amountPaid = double.tryParse(_amountController.text) ?? 0.0;
    final double outstanding = totalCharges - amountPaid;
    final bool isLocked = amountPaid > 0;

    return Container(
      padding: const EdgeInsets.all(32),
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
          
          // Editable Total Charges Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Charges', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13)),
              SizedBox(
                width: 140,
                child: TextField(
                  controller: _totalChargesController,
                  enabled: !isLocked,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: isLocked ? const Color(0xFF94A3B8) : AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Manrope',
                  ),
                  decoration: InputDecoration(
                    prefixText: 'GH₵ ',
                    prefixStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    suffixIcon: isLocked ? const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF94A3B8)) : const Icon(Icons.edit_note_rounded, size: 18, color: AppTheme.primary),
                    border: isLocked ? InputBorder.none : const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.primary)),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          _buildSummaryRow('Paid to Date', 'GH₵ ${amountPaid.toStringAsFixed(2)}', isNegative: true),
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
                        'GH₵ ${outstanding.toStringAsFixed(2)}',
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
        Text(label, style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w600, fontSize: 13)),
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
              const Text('Field Investigation Remarks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary, fontFamily: 'Manrope')),
            ],
          ),
          const SizedBox(height: 24),
          Stack(
            children: [
              TextField(
                controller: _remarksController,
                maxLines: 6,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFE2E2E4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  hintText: 'Enter detailed field notes here...',
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
                      const Text('ATTACH FILES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildEvidenceThumbnail('https://i.ibb.co/3W6pZPx/meter-1.jpg'),
              const SizedBox(width: 12),
              _buildEvidenceThumbnail('https://i.ibb.co/680L93L/meter-2.jpg'),
              const SizedBox(width: 16),
              const Text(
                '+2 MORE ATTACHMENTS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF475569), letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceThumbnail(String url) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)],
        image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
      ),
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
                  const Text('Last updated: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  const Text('Oct 24, 2023 - 14:32', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark)),
                  const Text(' by Admin_Kwadwo', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(width: 24),
                  Container(width: 1, height: 16, color: const Color(0xFFCBD5E1)),
                  const SizedBox(width: 24),
                  Row(
                    children: [
                      const Text('System Status: ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      const Text('ONLINE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green)),
                    ],
                  ),
                ],
              ),
              const Row(
                children: [
                  Text('AUDIT POLICY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1)),
                  SizedBox(width: 32),
                  Text('PRIVACY STANDARDS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1)),
                  SizedBox(width: 32),
                  Text('HELP DESK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 1)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(MeterStatus status) {
    switch (status) {
      case MeterStatus.pending:
        return Icons.hourglass_empty_rounded;
      case MeterStatus.billed:
        return Icons.receipt_long_rounded;
      case MeterStatus.scheduled:
        return Icons.calendar_today_rounded;
      case MeterStatus.paid:
        return Icons.check_circle_rounded;
    }
  }
}

class _InstallmentConfigurator extends StatefulWidget {
  final double totalCharges;
  final List<Installment> initialInstallments;

  const _InstallmentConfigurator({required this.totalCharges, this.initialInstallments = const []});

  @override
  State<_InstallmentConfigurator> createState() => _InstallmentConfiguratorState();
}

class _InstallmentConfiguratorState extends State<_InstallmentConfigurator> {
  int _count = 2;
  late List<TextEditingController> _amountControllers;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    if (widget.initialInstallments.isNotEmpty) {
      _count = widget.initialInstallments.length;
      _amountControllers = widget.initialInstallments.map((e) => TextEditingController(text: e.amount.toStringAsFixed(2))).toList();
      _dates = widget.initialInstallments.map((e) => e.dueDate).toList();
    } else {
      _initializeDefaults();
    }
  }

  void _initializeDefaults() {
    _amountControllers = List.generate(_count, (index) => TextEditingController());
    _dates = List.generate(_count, (index) => DateTime.now().add(Duration(days: (index + 1) * 30)));
    _distributeEqually();
  }

  void _distributeEqually() {
    if (_count == 0) return;
    final perInstallment = (widget.totalCharges / _count).floorToDouble();
    double currentSum = 0;
    
    for (var i = 0; i < _count - 1; i++) {
      _amountControllers[i].text = perInstallment.toStringAsFixed(2);
      currentSum += perInstallment;
    }
    
    // Last installment gets the remainder to avoid rounding issues
    _amountControllers[_count - 1].text = (widget.totalCharges - currentSum).toStringAsFixed(2);
  }

  double get _currentTotal => _amountControllers.fold(0.0, (sum, controller) => sum + (double.tryParse(controller.text) ?? 0.0));
  double get _remaining => widget.totalCharges - _currentTotal;
  bool get _isValid => _remaining.abs() < 0.01;

  @override
  void dispose() {
    for (var controller in _amountControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 100, vertical: 40),
      child: Container(
        width: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(40),
              decoration: const BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configure Payment Schedule',
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Manrope'),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Set installment amounts and future due dates',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Main Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoBlock('TOTAL DEBT DUE', 'GH₵ ${widget.totalCharges.toStringAsFixed(2)}', Icons.payments_rounded),
                        ),
                        const SizedBox(width: 32),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('INSTALLMENT COUNT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<int>(
                                    value: _count,
                                    isExpanded: true,
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary),
                                    items: [2, 3, 4, 6, 8, 12].map((e) => DropdownMenuItem(
                                      value: e,
                                      child: Text('$e Payments', style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.primary)),
                                    )).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setState(() {
                                          _count = val;
                                          _initializeDefaults();
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 40),
                    const Text('ADJUST PAYMENT PLAN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
                    const SizedBox(height: 24),
                    ...List.generate(_count, (index) => _buildInstallmentEditor(index)),
                  ],
                ),
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _remaining.abs() < 0.01 ? 'Balance Fully Allocated' : 'Unallocated: GH₵ ${_remaining.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: _isValid ? Colors.green : AppTheme.error,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isValid ? 'All installments sum up correctly.' : 'Please adjust amounts to match total debt.',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildDialogButton('Reset to Equal Split', Icons.balance_rounded, _distributeEqually, isSecondary: true),
                      const SizedBox(width: 16),
                      _buildDialogButton('Save Schedule', Icons.check_circle_rounded, () {
                        if (_isValid) {
                          final installments = List.generate(_count, (i) => Installment(
                            amount: double.tryParse(_amountControllers[i].text) ?? 0.0,
                            dueDate: _dates[i],
                          ));
                          Navigator.pop(context, installments);
                        }
                      }, isDisabled: !_isValid),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBlock(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppTheme.primary),
              const SizedBox(width: 16),
              Text(value, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w900, fontSize: 20, fontFamily: 'Manrope')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInstallmentEditor(int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: TextField(
              controller: _amountControllers[index],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => setState(() {}),
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark, fontFamily: 'Manrope'),
              decoration: InputDecoration(
                prefixText: 'GH₵ ',
                prefixStyle: const TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w700),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 4,
            child: InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _dates[index],
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  builder: (context, child) => Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(primary: AppTheme.primary, onPrimary: Colors.white, onSurface: AppTheme.textDark),
                    ),
                    child: child!,
                  ),
                );
                if (date != null) setState(() => _dates[index] = date);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 20, color: Color(0xFF64748B)),
                    const SizedBox(width: 16),
                    Text(
                      DateFormat('MMM dd, yyyy').format(_dates[index]),
                      style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogButton(String label, IconData icon, VoidCallback onTap, {bool isSecondary = false, bool isDisabled = false}) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isDisabled ? const Color(0xFFE2E8F0) : (isSecondary ? Colors.white : AppTheme.primary),
          borderRadius: BorderRadius.circular(16),
          border: isSecondary ? Border.all(color: const Color(0xFFCBD5E1), width: 2) : null,
          boxShadow: (isDisabled || isSecondary) ? null : [
            BoxShadow(color: AppTheme.primary.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 8))
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: isDisabled ? const Color(0xFF94A3B8) : (isSecondary ? AppTheme.primary : Colors.white), size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? const Color(0xFF94A3B8) : (isSecondary ? AppTheme.primary : Colors.white),
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
