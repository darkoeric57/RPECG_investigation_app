import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/backoffice_providers.dart';
import '../../../../core/theme/app_theme.dart';

class BillingSchedulePage extends ConsumerStatefulWidget {
  const BillingSchedulePage({super.key});

  @override
  ConsumerState<BillingSchedulePage> createState() => _BillingSchedulePageState();
}

class _BillingSchedulePageState extends ConsumerState<BillingSchedulePage> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _balanceController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    _updateDateText();
    
    // Initialize balance from selected account if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final account = ref.read(selectedBillingAccountProvider);
      if (account != null) {
        // Remove 'GHS ' prefix if present for the controller
        final bal = account['balance']?.replaceAll('GHS ', '').replaceAll(',', '') ?? '0.00';
        _balanceController.text = bal;
      }
    });
  }

  void _updateDateText() {
    _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate);
  }

  @override
  void dispose() {
    _dateController.dispose();
    _reasonController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateDateText();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(selectedBillingAccountProvider);
    if (account == null) {
      return const Center(child: Text('No account selected'));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Navigation
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Payments', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                        Text('Queues', style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                        const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                        const Text('Schedule Payment Date', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Schedule Payment Date',
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppTheme.textDark, letterSpacing: -1.5, fontFamily: 'Manrope'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Update the commitment period for high-value utility accounts.',
                      style: const TextStyle(fontSize: 16, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                _buildBackButton(),
              ],
            ),

            const SizedBox(height: 48),

            // Two Column Layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Form
                Expanded(
                  flex: 7,
                  child: _buildFormSection(account),
                ),
                const SizedBox(width: 48),
                // Right Column: Context Sidebar
                Expanded(
                  flex: 5,
                  child: _buildContextSidebar(account),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingDashboard,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.arrow_back_rounded, size: 18, color: AppTheme.primary),
            SizedBox(width: 12),
            Text('Back to Billing', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(Map<String, String> account) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
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
          // Read-only Info Grid
          Row(
            children: [
              Expanded(
                child: _buildInfoDisplay(
                  'Customer Name',
                  account['name'] ?? 'N/A',
                  Icons.person_rounded,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _buildInfoDisplay(
                  'Outstanding Balance',
                  'GHS ${_balanceController.text}',
                  Icons.payments_rounded,
                  isHighlight: true,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 40),

          // Date Picker Field
          const Text('SCHEDULED DUE DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildDateField(),
          const SizedBox(height: 8),
          Text(
            'Extensions beyond 30 days require supervisor clearance.',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
          ),

          const SizedBox(height: 32),

          // Reason Field
          const Text('REASON FOR EXTENSION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
          const SizedBox(height: 16),
          _buildReasonField(),

          const SizedBox(height: 48),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildActionButton(
                  'Confirm & Schedule',
                  Icons.calendar_today_rounded,
                  AppTheme.error,
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment schedule updated successfully!')),
                    );
                    ref.read(backofficePageProvider.notifier).state = BackofficePage.billingDashboard;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildActionButton(
                  'Cancel',
                  Icons.close_rounded,
                  Colors.white,
                  () => ref.read(backofficePageProvider.notifier).state = BackofficePage.billingDashboard,
                  isSecondary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDisplay(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isHighlight ? AppTheme.primary : const Color(0xFF64748B)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    color: isHighlight ? AppTheme.primary : AppTheme.textDark,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _dateController,
        readOnly: true,
        onTap: () => _selectDate(context),
        style: const TextStyle(fontWeight: FontWeight.w800, color: AppTheme.textDark),
        decoration: InputDecoration(
          hintText: 'Select Date',
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.calendar_month_rounded, color: AppTheme.primary),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
      ),
    );
  }

  Widget _buildReasonField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        controller: _reasonController,
        maxLines: 4,
        style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textDark),
        decoration: InputDecoration(
          hintText: 'Briefly document the field context or customer commitment details...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14, fontWeight: FontWeight.w400),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(24),
        ),
      ),
    );
  }
 
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap, {bool isSecondary = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(100),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(100),
          border: isSecondary ? Border.all(color: const Color(0xFFE2E8F0)) : null,
          boxShadow: isSecondary ? null : [
            BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSecondary ? const Color(0xFF475569) : Colors.white, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isSecondary ? const Color(0xFF475569) : Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContextSidebar(Map<String, String> account) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Operational Alert
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFCDF46).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
            border: const Border(left: BorderSide(color: Color(0xFFFCDF46), width: 8)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_rounded, color: Color(0xFF6D5E00), size: 32),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Operational Alert', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF211B00), fontSize: 18)),
                    SizedBox(height: 8),
                    Text(
                      'This customer has 3 previous extensions. Scheduling a new date will trigger a mandatory field verification walk by the Field Ops team within 48 hours.',
                      style: TextStyle(color: Color(0xFF524600), fontSize: 14, height: 1.5, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Location Context
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('LOCATION CONTEXT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
                  _buildPulseIndicator(),
                ],
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuD-rOcSuifQLUMV8mZZ8bUSSwwftUiAb6hezy1J-fsd9HQymT63Y8oYtAe1Nejp3RUyNrQ1x6DirZrEWL6m95GxZtVTaTeanmacnCj3gsDao1N_0OWrlqEHTI6-R6NxFIr1EIXQgkxMrJRO8CGNEZzTgky1OPGZQlfzL1DxATzDQCcoH7Yz86SQKRduuMrHHJisnMutUJXGo7nDCThs_O2uyzgZdGzyEhBabSZ9Yqb_9phu86JAoxWw7n6BzDLEzpIOcNlkuOh-XBE',
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  color: Colors.grey,
                  colorBlendMode: BlendMode.saturation,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.location_on_rounded, color: AppTheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(account['address'] ?? 'Osu Industrial Area', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textDark, fontSize: 16)),
                      const Text('Zone 4 - Utility Corridor A', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Statistics Summary
        Row(
          children: [
            Expanded(child: _buildStatTile('Payment History', 'Fair', Colors.blue)),
            const SizedBox(width: 16),
            Expanded(child: _buildStatTile('Risk Score', 'High', AppTheme.error)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 24, fontFamily: 'Manrope')),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: const BoxDecoration(color: Color(0xFFFCDF46), shape: BoxShape.circle),
        ),
      ],
    );
  }
}
