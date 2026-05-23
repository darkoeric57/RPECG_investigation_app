import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/web_utils.dart';
import '../../domain/report_config.dart';
import '../../../meters/domain/meter.dart';
import './multi_select_field.dart';
import '../../domain/active_report.dart';
import '../../providers/active_report_provider.dart';
import './report_dialog_components.dart';
import '../providers/backoffice_providers.dart';

class ReportScheduleDialog extends ConsumerStatefulWidget {
  const ReportScheduleDialog({super.key});

  @override
  ConsumerState<ReportScheduleDialog> createState() => _ReportScheduleDialogState();
}

class _ReportScheduleDialogState extends ConsumerState<ReportScheduleDialog> {
  DateTime? startDate;
  DateTime? endDate;
  String selectedFrequency = 'Weekly';
  String selectedFormat = 'PDF';
  List<String> selectedSegments = ['Residential', 'Commercial', 'Industrial'];
  List<String> selectedStatuses = ['Paid', 'Pending', 'Scheduled', 'Billed'];
  List<String>? selectedFraudTypes;
  String selectedReportType = 'Revenue Analysis';
  
  double minKwh = 0;
  double maxKwh = 15000;
  bool restrictedMode = true;
  
  final TextEditingController _emailController = TextEditingController();
  bool _isEmailValid = true;
  bool _isGenerating = false;
  String _generationStatus = '';

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateEmails);
  }

  String? _validationError;

  bool _validateConfiguration() {
    setState(() => _validationError = null);
    
    // Custom schedule validation
    if (selectedFrequency.toLowerCase() == 'custom') {
      if (startDate == null) {
        setState(() => _validationError = 'PLEASE SELECT A START DATE FOR CUSTOM SCHEDULE');
        return false;
      }
      
      if (endDate != null && startDate!.isAfter(endDate!)) {
        setState(() => _validationError = 'START DATE MUST BE BEFORE END DATE');
        return false;
      }
    }

    if (selectedSegments.isEmpty) {
      setState(() => _validationError = 'SELECT AT LEAST ONE CUSTOMER SEGMENT');
      return false;
    }


    if (selectedStatuses.isEmpty) {
      setState(() => _validationError = 'SELECT AT LEAST ONE PAYMENT STATUS');
      return false;
    }

    if (selectedFraudTypes != null && selectedFraudTypes!.isEmpty) {
      setState(() => _validationError = 'SELECT AT LEAST ONE FRAUD TYPE');
      return false;
    }

    if (!_isEmailValid) {
      setState(() => _validationError = 'FIX INVALID EMAIL FORMATS');
      return false;
    }

    return true;
  }

  void _validateEmails() {
    final text = _emailController.text.trim();
    if (text.isEmpty) {
      if (!_isEmailValid) setState(() => _isEmailValid = true);
      return;
    }
    
    final emails = text.split(',').map((e) => e.trim());
    final emailRegex = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+");
    
    bool allValid = true;
    for (var email in emails) {
      if (email.isNotEmpty && !emailRegex.hasMatch(email)) {
        allValid = false;
        break;
      }
    }
    
    if (_isEmailValid != allValid) {
      setState(() => _isEmailValid = allValid);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? startDate : endDate) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1E3A8A),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(billingAccountsProvider).valueOrNull ?? [];
    final availableFraudTypes = accounts.isNotEmpty
        ? accounts
            .map((a) => a.fraudStatus.trim())
            .where((s) => s.isNotEmpty && s != '—')
            .toSet()
            .toList()
        : const ['Normal', 'Meter Bypass', 'Direct Connection', 'Tampering'];

    selectedFraudTypes ??= List<String>.from(availableFraudTypes);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        width: 1200,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.95),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withValues(alpha: 0.15),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    // Row 1: Reporting Window (Dates), Report Type, Frequency
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1 Column 1: Dates
                        Expanded(
                          flex: 5,
                          child: _buildReportingWindowSection(),
                        ),
                        const SizedBox(width: 32),
                        
                        // Row 1 Column 2: Report Type
                        Expanded(
                          flex: 4,
                          child: _buildReportTypeSection(),
                        ),
                        const SizedBox(width: 32),
                        
                        // Row 1 Column 3: Frequency
                        Expanded(
                          flex: 3,
                          child: _buildFrequencySection(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    
                    // Row 2: Filters, Format & Consumption, Recipients
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 2 Column 1: Filters
                        Expanded(
                          flex: 5,
                          child: _buildFiltersSection(availableFraudTypes),
                        ),
                        const SizedBox(width: 32),
                        
                        // Row 2 Column 2: Format & Consumption
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildFormatSection(),
                              const SizedBox(height: 24),
                              _buildConsumptionSection(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        
                        // Row 2 Column 3: Recipients
                        Expanded(
                          flex: 3,
                          child: _buildRecipientsSection(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3A8A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Configure Report Schedule', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              const Text('AUTOMATED DISPATCH PARAMETERS', style: TextStyle(color: Color(0xFF90A8FF), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            ],
          ),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
        ],
      ),
    );
  }


  Widget _buildFrequencySection() {
    return ReportSection(
      number: '3',
      label: 'FREQUENCY',
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: ['Custom', 'Weekly', 'Monthly'].map((f) {
            final isSelected = selectedFrequency == f;
            return Expanded(
              child: _SelectableTabHorizontal(
                label: f,
                isSelected: isSelected,
                onTap: () => setState(() => selectedFrequency = f),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportTypeSection() {
    return ReportSection(
      number: '2',
      label: 'REPORT TYPE',
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: ['Revenue Analysis', 'Consumption', 'Tariff Activity'].map((t) {
            final isSelected = selectedReportType == t;
            return Expanded(
              child: _SelectableTabHorizontal(
                label: t,
                isSelected: isSelected,
                onTap: () => setState(() => selectedReportType = t),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildReportingWindowSection() {
    return ReportSection(
      number: '1',
      label: 'REPORT GENERATION WINDOW',
      child: Row(
        children: [
          Expanded(
            child: DatePickerField(
              icon: Icons.calendar_today_rounded,
              value: startDate != null ? DateFormat('MMM dd, yyyy').format(startDate!) : 'Start Date',
              onTap: () => _selectDate(context, true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DatePickerField(
              icon: Icons.event_busy_rounded,
              value: endDate != null ? DateFormat('MMM dd, yyyy').format(endDate!) : 'End Date (Optional)',
              onTap: () => _selectDate(context, false),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFiltersSection(List<String> availableFraudTypes) {
    return ReportSection(
      number: '4',
      label: 'DATA SEGMENT FILTERS',
      child: Column(
        children: [
          MultiSelectField(
            label: 'CUSTOMER SEGMENTS',
            selectedItems: selectedSegments,
            options: const ['Residential', 'Commercial', 'Industrial'],
            onSelectionChanged: (items) => setState(() => selectedSegments = items),
          ),
          const SizedBox(height: 12),
          MultiSelectField(
            label: 'PAYMENT STATUSES',
            selectedItems: selectedStatuses,
            options: const ['Paid', 'Pending', 'Scheduled', 'Billed'],
            onSelectionChanged: (items) => setState(() => selectedStatuses = items),
          ),
          const SizedBox(height: 12),
          MultiSelectField(
            label: 'FRAUD TYPES',
            selectedItems: selectedFraudTypes ?? [],
            options: availableFraudTypes,
            onSelectionChanged: (items) => setState(() => selectedFraudTypes = items),
          ),
        ],
      ),
    );
  }

  Widget _buildFormatSection() {
    return ReportSection(
      number: '6',
      label: 'FORMAT',
      child: Row(
        children: ['CSV', 'PDF', 'EXCEL'].map((f) {
          final isSelected = selectedFormat == f;
          return Expanded(
            child: FormatButton(
              label: f,
              isSelected: isSelected,
              onTap: () => setState(() => selectedFormat = f),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRecipientsSection() {
    return ReportSection(
      number: '7',
      label: 'RECIPIENT EMAILS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _isEmailValid ? const Color(0xFFE2E8F0) : const Color(0xFFEF4444).withValues(alpha: 0.5)),
            ),
            child: TextField(
              controller: _emailController,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: 'Enter emails separated by commas...',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),
          if (!_isEmailValid) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Color(0xFFEF4444)),
                SizedBox(width: 6),
                Text('INVALID EMAIL FORMAT DETECTED', style: TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(color: Color(0xFFF1F5F9), borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              RestrictedToggle(
                isRestricted: restrictedMode,
                onChanged: (v) => setState(() => restrictedMode = v),
              ),
              if (_validationError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Text(_validationError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 24),
              if (_isGenerating)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E3A8A))),
                      const SizedBox(width: 12),
                      Text(_generationStatus, style: const TextStyle(color: Color(0xFF1E3A8A), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                )
              else ...[
                ElevatedButton(
                  onPressed: () {
                    if (_validateConfiguration()) {
                      _performTestDispatch();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFCDF46), foregroundColor: const Color(0xFF726200), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
                  child: const Text('TEST DISPATCH', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_validateConfiguration()) {
                      _activateSchedule();
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)), elevation: 10, shadowColor: const Color(0xFF1E3A8A).withValues(alpha: 0.3)),
                  child: const Text('ACTIVATE SCHEDULE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _activateSchedule() {
    final frequency = ReportFrequency.values.firstWhere(
      (e) => e.name.toLowerCase() == selectedFrequency.toLowerCase(),
      orElse: () => ReportFrequency.custom,
    );

    final format = ReportFormat.values.firstWhere(
      (e) => e.name.toLowerCase() == selectedFormat.toLowerCase(),
      orElse: () => ReportFormat.csv,
    );

    final segments = selectedSegments.map((s) => 
      TariffActivity.values.firstWhere((e) => e.name.toLowerCase() == s.toLowerCase())
    ).toList();

    final statuses = selectedStatuses.map((s) => 
      MeterStatus.values.firstWhere((e) => e.name.toLowerCase() == s.toLowerCase())
    ).toList();

    final type = selectedReportType == 'Revenue Analysis' 
      ? ReportType.revenue 
      : (selectedReportType == 'Consumption' ? ReportType.consumption : ReportType.tariff);

    final now = DateTime.now();
    final DateTime finalStartDate = startDate ?? (frequency == ReportFrequency.weekly
        ? now.subtract(const Duration(days: 7))
        : (frequency == ReportFrequency.monthly
            ? now.subtract(const Duration(days: 30))
            : now));

    final DateTime finalEndDate = endDate ?? (frequency == ReportFrequency.weekly
        ? now
        : (frequency == ReportFrequency.monthly
            ? now
            : DateTime(now.year, now.month, now.day, 23, 59, 59)));

    final config = ReportConfig(
      type: type,
      frequency: frequency,
      startDate: finalStartDate,
      endDate: finalEndDate,
      segments: segments,
      statuses: statuses,
      fraudTypes: selectedFraudTypes ?? [],
      minKwh: minKwh,
      maxKwh: maxKwh,
      format: format,
      recipients: _emailController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    );

    // Create ActiveReport
    final category = selectedReportType == 'Revenue Analysis' ? 'Revenue' : (selectedReportType == 'Consumption' ? 'Meter Ops' : 'Tariff');
    final title = '$selectedFrequency $selectedReportType';

    final report = ActiveReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      category: category,
      config: config,
      createdAt: DateTime.now(),
    );

    ref.read(activeReportsProvider.notifier).addReport(report);
    
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Schedule activated for $title'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
    );
  }

  void _performTestDispatch() async {
    final reportService = ref.read(reportServiceProvider);
    
    // Map UI values to Enums
    final frequency = ReportFrequency.values.firstWhere(
      (e) => e.name.toLowerCase() == selectedFrequency.toLowerCase(),
      orElse: () => ReportFrequency.custom,
    );

    final format = ReportFormat.values.firstWhere(
      (e) => e.name.toLowerCase() == selectedFormat.toLowerCase(),
      orElse: () => ReportFormat.csv,
    );

    final segments = selectedSegments.map((s) => 
      TariffActivity.values.firstWhere((e) => e.name.toLowerCase() == s.toLowerCase())
    ).toList();

    final statuses = selectedStatuses.map((s) => 
      MeterStatus.values.firstWhere((e) => e.name.toLowerCase() == s.toLowerCase())
    ).toList();

    final type = selectedReportType == 'Revenue Analysis' 
      ? ReportType.revenue 
      : (selectedReportType == 'Consumption' ? ReportType.consumption : ReportType.tariff);

    final now2 = DateTime.now();
    final DateTime finalStartDate = startDate ?? (frequency == ReportFrequency.weekly
        ? now2.subtract(const Duration(days: 7))
        : (frequency == ReportFrequency.monthly
            ? now2.subtract(const Duration(days: 30))
            : now2));

    final DateTime finalEndDate = endDate ?? (frequency == ReportFrequency.weekly
        ? now2
        : (frequency == ReportFrequency.monthly
            ? now2
            : DateTime(now2.year, now2.month, now2.day, 23, 59, 59)));

    final config = ReportConfig(
      type: type,
      frequency: frequency,
      startDate: finalStartDate,
      endDate: finalEndDate,
      segments: segments,
      statuses: statuses,
      fraudTypes: selectedFraudTypes ?? [],
      minKwh: minKwh,
      maxKwh: maxKwh,
      format: format,
      recipients: _emailController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
    );

    try {
      // Show loading
      setState(() {
        _isGenerating = true;
        _generationStatus = 'AGGREGATING DATA...';
      });

      final reportData = await reportService.processData(config);
      
      setState(() => _generationStatus = 'ENCODING $selectedFormat...');
      final fileBytes = await reportService.generateFile(reportData, format);

      // Trigger Download
      final filename = 'RPECG_Report_${DateFormat('yyyyMMdd').format(DateTime.now())}.${selectedFormat.toLowerCase()}';
      final mimeType = selectedFormat == 'PDF' ? 'application/pdf' : 
                       selectedFormat == 'EXCEL' ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' : 
                       'text/csv';
      
      WebUtils.downloadBytes(filename, fileBytes, mimeType);

      if (config.recipients.isNotEmpty) {
        setState(() => _generationStatus = 'DISPATCHING EMAILS...');
        await reportService.simulateEmailDispatch(filename, config.recipients);
      }

      setState(() => _isGenerating = false);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Report Generated', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                config.type == ReportType.revenue
                    ? 'Successfully generated report for ${reportData.revenueSummary?.totalAccounts ?? 0} billing accounts.'
                    : 'Successfully generated report for ${reportData.meters.length} meters.',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              if (config.type == ReportType.revenue) ...[
                PreviewRow(
                  label: 'Total Billed',
                  value: 'GHS ${reportData.revenueSummary?.grandTotalBilled.toStringAsFixed(2) ?? "0.00"}',
                ),
                PreviewRow(
                  label: 'Total Collected',
                  value: 'GHS ${reportData.revenueSummary?.grandTotalPaid.toStringAsFixed(2) ?? "0.00"}',
                ),
                PreviewRow(
                  label: 'Recovery Rate',
                  value: '${reportData.revenueSummary?.collectionRate.toStringAsFixed(1) ?? "0.0"}%',
                ),
              ] else ...[
                PreviewRow(label: 'Total Consumption', value: '${reportData.totalConsumption.toStringAsFixed(1)} kWh'),
              ],
              PreviewRow(label: 'Format', value: selectedFormat),
              PreviewRow(label: 'Recipients', value: config.recipients.isNotEmpty ? config.recipients.join(', ') : 'None (Downloaded Only)'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Color(0xFF1E3A8A)),
                    SizedBox(width: 8),
                    Expanded(child: Text('The report has been downloaded to your browser. No emails were sent in test mode.', style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold))),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E3A8A), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100))),
              child: const Text('GOT IT'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate report: $e'), backgroundColor: Colors.red),
      );
    }
  }


  Widget _buildConsumptionSection() {
    return ReportSection(
      number: '6',
      label: 'CONSUMPTION (KWH) RANGE',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${minKwh.toInt()} KWH', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
                Text('${maxKwh.toInt()} KWH', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A))),
              ],
            ),
            const SizedBox(height: 8),
            RangeSlider(
              values: RangeValues(minKwh, maxKwh),
              min: 0,
              max: 15000,
              divisions: 150,
              activeColor: const Color(0xFF1E3A8A),
              inactiveColor: const Color(0xFFE2E8F0),
              labels: RangeLabels('${minKwh.toInt()}', '${maxKwh.toInt()}'),
              onChanged: (values) {
                setState(() {
                  minKwh = values.start;
                  maxKwh = values.end;
                });
              },
            ),
            const SizedBox(height: 8),
            const Text('DRAG TO SET REPORTING THRESHOLD', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _SelectableTabHorizontal extends StatefulWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableTabHorizontal({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SelectableTabHorizontal> createState() => _SelectableTabHorizontalState();
}

class _SelectableTabHorizontalState extends State<_SelectableTabHorizontal> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? Colors.white 
                : (_isHovered ? Colors.white.withValues(alpha: 0.5) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            boxShadow: widget.isSelected 
                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))] 
                : null,
            border: Border.all(color: widget.isSelected ? const Color(0xFFE2E8F0) : Colors.transparent),
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF64748B),
              fontSize: 11,
              fontWeight: widget.isSelected ? FontWeight.w900 : FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

