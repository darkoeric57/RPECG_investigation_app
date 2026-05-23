import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../features/meters/domain/meter.dart';
import '../providers/backoffice_providers.dart';

class AddInfrastructureDialog extends ConsumerStatefulWidget {
  const AddInfrastructureDialog({super.key});

  @override
  ConsumerState<AddInfrastructureDialog> createState() => _AddInfrastructureDialogState();
}

class _AddInfrastructureDialogState extends ConsumerState<AddInfrastructureDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _findingsController = TextEditingController();
  final _spnController = TextEditingController();
  final _gpsController = TextEditingController();
  final _billAmountController = TextEditingController();
  final _paidAmountController = TextEditingController();
  
  MeterStatus _selectedStatus = MeterStatus.pending;
  final Set<String> _selectedFindings = {};
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _findingsController.dispose();
    _spnController.dispose();
    _gpsController.dispose();
    _billAmountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  void _generateGps() {
    final rand = math.Random();
    // Centered around Accra, GH (5.6037, -0.1870)
    final lat = 5.6037 + (rand.nextDouble() - 0.5) * 0.1;
    final long = -0.1870 + (rand.nextDouble() - 0.5) * 0.1;
    setState(() {
      _gpsController.text = "${lat.toStringAsFixed(6)}, ${long.toStringAsFixed(6)}";
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      // Combine chip findings and custom text findings
      final findingsList = [..._selectedFindings];
      if (_findingsController.text.trim().isNotEmpty) {
        findingsList.add(_findingsController.text.trim());
      }
      final combinedFindings = findingsList.join(", ");

      final newMeter = Meter(
        id: _idController.text.trim(),
        customerName: _nameController.text.trim(),
        address: _addressController.text.trim(),
        telephone: _phoneController.text.trim(),
        findings: combinedFindings,
        status: _selectedStatus,
        installationDate: DateTime.now(),
        spnNumber: _spnController.text.trim().isEmpty ? 'N/A' : _spnController.text.trim(),
        gpsCoordinates: _gpsController.text.trim().isEmpty ? '0.0, 0.0' : _gpsController.text.trim(),
        debtAmount: double.tryParse(_billAmountController.text.trim()) ?? 0.0,
        paidAmount: double.tryParse(_paidAmountController.text.trim()) ?? 0.0,
        // Defaults
        tariffClass: 'Residential',
        tariffActivity: TariffActivity.residential,
        geocode: 'ACC',
        rating: '5/60A',
        phase: MeterPhase.single,
        type: MeteringType.prepaid,
      );

      await ref.read(addMeterActionProvider)(newMeter);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('New entry successfully synchronized to cloud'),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Dialog(
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 700,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildModernHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildTextField('CUSTOMER NAME', _nameController, Icons.person_outline_rounded)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('METER ID', _idController, Icons.tag_rounded)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        _buildAddressField(),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(child: _buildTextField('TELEPHONE', _phoneController, Icons.phone_iphone_rounded)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('SPN NUMBER', _spnController, Icons.electric_bolt_rounded)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(child: _buildTextField('BILL AMOUNT (GHS)', _billAmountController, Icons.payments_outlined, isNumeric: true)),
                            const SizedBox(width: 24),
                            Expanded(child: _buildTextField('PAID AMOUNT (GHS)', _paidAmountController, Icons.check_circle_outline, isNumeric: true)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(child: _buildTextField('GPS COORDINATES', _gpsController, Icons.gps_fixed_rounded, isReadOnly: false)),
                            const Spacer(),
                          ],
                        ),
                        const SizedBox(height: 32),

                        const Text('INVESTIGATION FINDINGS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
                        const SizedBox(height: 16),
                        _buildFindingsChips(),
                        const SizedBox(height: 16),
                        _buildTextField('ADDITIONAL NOTES / OTHERS', _findingsController, Icons.edit_note_rounded, maxLines: 2),
                        
                        const SizedBox(height: 32),

                        const Text('INITIAL STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF64748B), letterSpacing: 1.2)),
                        const SizedBox(height: 16),
                        _buildStatusSelector(),
                        
                        const SizedBox(height: 48),
                        _buildActions(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(40, 48, 40, 40),
      decoration: const BoxDecoration(
        color: AppTheme.primary,
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Text('New Infrastructure Node', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5)),
                ],
              ),
              const SizedBox(height: 12),
              Text('Advanced Data Synchronization Utility', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.1), padding: const EdgeInsets.all(12)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1, bool isReadOnly = false, bool isNumeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: isReadOnly,
          keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : null,
          validator: (val) {
            if ((val == null || val.isEmpty) && label != 'SPN NUMBER' && label != 'GPS COORDINATES' && label != 'ADDITIONAL NOTES / OTHERS') return 'Required';
            if (isNumeric && val != null && val.isNotEmpty && double.tryParse(val) == null) return 'Invalid amount';
            return null;
          },
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: AppTheme.primary.withValues(alpha: 0.4)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            // Yellowish outline for focused fields
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFACC15), width: 2.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 21, vertical: 18),
            hintText: label == 'GPS COORDINATES' ? 'Lat, Long' : null,
            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5), fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ADDRESS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
        const SizedBox(height: 10),
        TextFormField(
          controller: _addressController,
          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1E293B)),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.location_on_outlined, size: 18, color: AppTheme.primary.withValues(alpha: 0.4)),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: _generateGps,
                icon: const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFFFACC15)),
                label: const Text('GPS', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w900, fontSize: 11)),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFFACC15).withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFFACC15), width: 2.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 21, vertical: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildFindingsChips() {
    const categories = [
      'Tampered Meter',
      'Meter By-pass',
      'Direct Connection',
      'Communication Error',
      'Burnt Meter',
      'Relay Not Tripping',
      'Unauthorized Service',
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((cat) {
        final isSelected = _selectedFindings.contains(cat);
        return FilterChip(
          label: Text(cat),
          selected: isSelected,
          onSelected: (sel) {
            setState(() {
              if (sel) {
                _selectedFindings.add(cat);
              } else {
                _selectedFindings.remove(cat);
              }
            });
          },
          labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155), fontWeight: FontWeight.w700, fontSize: 13),
          selectedColor: AppTheme.primary,
          backgroundColor: Colors.white,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0))),
        );
      }).toList(),
    );
  }

  Widget _buildStatusSelector() {
    final statuses = [
      {'val': MeterStatus.paid, 'label': 'Paid', 'color': const Color(0xFF10B981)},
      {'val': MeterStatus.pending, 'label': 'Pending', 'color': const Color(0xFFF59E0B)},
      {'val': MeterStatus.billed, 'label': 'Billed', 'color': const Color(0xFF6366F1)},
      {'val': MeterStatus.scheduled, 'label': 'Scheduled', 'color': const Color(0xFFA855F7)},
    ];

    return Wrap(
      spacing: 12,
      children: statuses.map((s) {
        final isSelected = _selectedStatus == s['val'];
        final color = s['color'] as Color;
        return ChoiceChip(
          label: Text(s['label'] as String),
          selected: isSelected,
          onSelected: (sel) => setState(() => _selectedStatus = s['val'] as MeterStatus),
          selectedColor: color,
          labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF64748B), fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: Colors.white,
          side: BorderSide(color: isSelected ? color : const Color(0xFFE2E8F0)),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Discard Changes', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w800, fontSize: 14)),
        ),
        const SizedBox(width: 32),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 12,
            shadowColor: AppTheme.primary.withValues(alpha: 0.4),
          ),
          child: _isSubmitting 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : const Text('Save Node', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 0.5)),
        ),
      ],
    );
  }
}
