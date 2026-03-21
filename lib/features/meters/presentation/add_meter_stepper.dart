import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../../core/theme/app_theme.dart';
import '../../../shared_widgets/custom_button.dart';
import '../../../shared_widgets/custom_text_field.dart';
import 'add_meter_provider.dart';
import '../domain/meter.dart';
import '../../dashboard/presentation/sync_provider.dart';
import '../../../core/providers.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/device_service.dart';
import 'video_player_overlay.dart';
import 'load_details_screen.dart';

class AddMeterStepper extends ConsumerWidget {
  const AddMeterStepper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addMeterState = ref.watch(addMeterProvider);
    final notifier = ref.read(addMeterProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundLight,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () {
              if (addMeterState.currentStep > 0) {
                notifier.prevStep();
              } else {
                context.pop();
              }
            },
          ),
        ),
        title: Column(
          children: [
            const Text('Add Meter'),
            Text(
              'Step ${addMeterState.currentStep + 1} of 3',
              style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildStepperHeader(addMeterState.currentStep),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
              child: _buildCurrentStep(context, addMeterState.currentStep, ref),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomActions(context, ref, addMeterState, notifier),
    );
  }

  Widget _buildStepperHeader(int currentStep) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(color: Colors.grey.shade300, thickness: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStepIndicator(0, currentStep, 'Customer'),
              _buildStepIndicator(1, currentStep, 'Details'),
              _buildStepIndicator(2, currentStep, 'Review'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, int currentStep, String label) {
    final isCompleted = currentStep > step;
    final isActive = currentStep == step;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (isActive || isCompleted)
                ? (isCompleted
                      ? AppTheme.accent.withValues(alpha: 0.1)
                      : AppTheme.secondary)
                : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? AppTheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: AppTheme.primary)
                : Text(
                    '${step + 1}',
                    style: TextStyle(
                      color: isActive ? AppTheme.primary : AppTheme.textLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? AppTheme.primary : AppTheme.textLight,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(BuildContext context, int step, WidgetRef ref) {
    switch (step) {
      case 0:
        return _buildStep1(context, ref);
      case 1:
        return _buildStep2(context, ref);
      case 2:
        return _buildStep3(context, ref);
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Step 1: Customer Information ---
  Widget _buildStep1(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addMeterProvider);
    final notifier = ref.read(addMeterProvider.notifier);

    return Column(
      children: [
        _buildSectionHeader('CUSTOMER INFORMATION'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CustomTextField(
                  key: const ValueKey('customerNameField'),
                  label: 'Customer Name',
                  hint: 'Enter full name',
                  prefixIcon: Icons.person_outline,
                  initialValue: state.customerName,
                  onChanged: notifier.updateCustomerName,
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  key: const ValueKey('addressField'),
                  label: 'Address',
                  hint: 'House no, Street, Area',
                  prefixIcon: Icons.location_on_outlined,
                  initialValue: state.address,
                  onChanged: notifier.updateAddress,
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  key: const ValueKey('telephoneField'),
                  label: 'Telephone',
                  hint: '+1 (555) 000-0000',
                  prefixIcon: Icons.phone_outlined,
                  initialValue: state.telephone,
                  keyboardType: TextInputType.phone,
                  onChanged: notifier.updateTelephone,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('TARIFF & LOCATION'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildToggleField(
                  'Tariff Class',
                  ['E02', 'E01'],
                  state.tariffClass,
                  notifier.updateTariffClass,
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  label: 'GPS Coordinates',
                  hint: '0.0000, 0.0000',
                  prefixIcon: Icons.my_location,
                  suffixIcon: state.isLocationLoading ? null : Icons.gps_fixed,
                  controller: TextEditingController(text: state.gpsCoordinates),
                  onChanged: notifier.updateGpsCoordinates,
                  onSuffixTap: () => _handleLocationCapture(context, ref),
                  isLoading: state.isLocationLoading,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        'Tariff Activity',
                        ['Residential', 'Commercial', 'Industrial'],
                        state.tariffActivity,
                        notifier.updateTariffActivity,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Geocode',
                        hint: 'GEO-772',
                        initialValue: state.geocode,
                        onChanged: notifier.updateGeocode,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 2: Meter Details ---
  Widget _buildStep2(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addMeterProvider);
    final notifier = ref.read(addMeterProvider.notifier);

    return Column(
      children: [
        _buildSectionHeader('IDENTIFICATION'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CustomTextField(
                  key: const ValueKey('meterIdField'),
                  label: 'Meter ID',
                  hint: 'Enter Meter ID',
                  prefixIcon: Icons.qr_code_scanner,
                  suffixIcon: Icons.camera_alt_outlined,
                  controller: TextEditingController(text: state.meterId),
                  onSuffixTap: notifier.simulateQrScan,
                  isLoading: state.isLocationLoading,
                  onChanged: notifier.updateMeterId,
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  key: const ValueKey('spnNumberField'),
                  label: 'SPN Number',
                  hint: 'Enter SPN number',
                  prefixIcon: Icons.numbers,
                  initialValue: state.spnNumber,
                  onChanged: notifier.updateSpnNumber,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('TECHNICAL SPECIFICATIONS'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSelectionCard(
                        Icons.factory_outlined,
                        'METER BRAND',
                        state.meterBrand.isEmpty
                            ? 'Select Brand'
                            : state.meterBrand,
                        onTap: () => _showBrandPicker(context, notifier),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSelectionCard(
                        Icons.speed,
                        'READINGS',
                        state.initialReadings.isEmpty
                            ? 'Initial KWh'
                            : state.initialReadings,
                        onTap: () => _showReadingsInput(context, notifier),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildFindingsSelector(context, state.findings, notifier),
                const SizedBox(height: 12),
                _buildFullWidthSelectionCard(
                  Icons.electric_bolt_outlined,
                  'METER RATING',
                  state.meterRating.isEmpty
                      ? 'Choose Capacity (Amp)'
                      : state.meterRating,
                  onTap: () => _showRatingPicker(context, notifier),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildToggleField(
                        'Meter Phase',
                        ['1-Phase', '3-Phase'],
                        state.meterPhase,
                        notifier.updateMeterPhase,
                        small: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildToggleField(
                        'Metering Type',
                        ['Prepaid', 'Postpaid'],
                        state.meteringType,
                        notifier.updateMeteringType,
                        small: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('MEDIA DOCUMENTATION'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'METER PHOTOS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      '${state.capturedImagePaths.length} / 5',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: state.capturedImagePaths.length >= 5
                            ? AppTheme.accent
                            : AppTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: (state.capturedImagePaths.length < 5)
                        ? state.capturedImagePaths.length + 1
                        : state.capturedImagePaths.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      if (index < state.capturedImagePaths.length) {
                        return _buildImageThumbnail(
                          context,
                          state.capturedImagePaths[index],
                          index,
                          notifier,
                        );
                      } else {
                        return _buildAddPhotoButton(notifier);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _buildUploadCard(
                  context,
                  Icons.video_call_outlined,
                  'METER VIDEO',
                  path: state.capturedVideoPath,
                  onTap: notifier.captureVideo,
                  onRemove: notifier
                      .captureVideo, // Changed from removeVideo to captureVideo for "perfect" retake
                  isVideo: true,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: state.estimatedLoadWatts != null
                      ? 'Total Load: ${state.estimatedLoadWatts}W'
                      : 'Add Load Details',
                  icon: state.estimatedLoadWatts != null
                      ? Icons.check_circle
                      : Icons.add_circle_outline,
                  type: ButtonType.outlined,
                  onPressed: () async {
                    final result = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoadDetailsScreen(),
                      ),
                    );
                    if (result != null) {
                      notifier.updateEstimatedLoad(result);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(
    BuildContext context,
    String path,
    int index,
    AddMeterNotifier notifier,
  ) {
    return GestureDetector(
      onTap: () => _showImagePreview(context, path),
      child: Hero(
        tag: path,
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: FileImage(File(path)),
              fit: BoxFit.cover,
              opacity: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => notifier.removeImage(index),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 14,
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

  Widget _buildAddPhotoButton(AddMeterNotifier notifier) {
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () async {
          final success = await notifier.captureImage();
          if (!context.mounted) return;
          if (!success) {
            final scaffoldMessenger = ScaffoldMessenger.of(context);
            scaffoldMessenger.clearSnackBars();
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Maximum 5 images allowed'),
                  ],
                ),
                backgroundColor: AppTheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        child: Container(
          width: 100,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.primary.withValues(alpha: 0.2),
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                color: AppTheme.primary,
                size: 28,
              ),
              SizedBox(height: 8),
              Text(
                'Add Photo',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Step 3: Review / Confirmation ---
  Widget _buildStep3(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addMeterProvider);
    final notifier = ref.read(addMeterProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('FINAL REVIEW'),
        const Text(
          'Please verify the meter installation details.',
          style: TextStyle(fontSize: 14, color: AppTheme.textLight),
        ),
        const SizedBox(height: 24),
        _buildReviewCard(
          icon: Icons.location_on_outlined,
          title: 'Location Details',
          rows: [
            _buildReviewRow('House Address', state.address),
            _buildReviewRow('GPS Coordinates', state.gpsCoordinates),
          ],
        ),
        const SizedBox(height: 16),
        _buildReviewCard(
          icon: Icons.electric_meter_outlined,
          title: 'Meter Technical Info',
          rows: [
            _buildReviewRow('Meter ID', state.meterId),
            _buildReviewRow('Meter Brand', state.meterBrand),
            _buildReviewRow('Meter Rating', state.meterRating),
            _buildReviewRow('Initial Readings', state.initialReadings),
            _buildReviewRow('Tariff Class', state.tariffClass, isLabel: true),
            _buildReviewRow('Phase Type', state.meterPhase),
            if (state.findings.isNotEmpty)
              _buildReviewRow('Technical Finding', state.findings),
          ],
        ),
        const SizedBox(height: 16),
        _buildReviewCard(
          icon: Icons.contact_phone_outlined,
          title: 'Contact Person',
          rows: [
            _buildReviewRow('Phone Number', state.telephone),
            _buildReviewRow('Geocode', state.geocode),
          ],
        ),
        const SizedBox(height: 16),
        _buildReviewCard(
          icon: Icons.image_outlined,
          title: 'Captured Images',
          content: SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.capturedImagePaths.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final path = state.capturedImagePaths[index];
                return GestureDetector(
                  onTap: () => _showImagePreview(context, path),
                  child: Hero(
                    tag: path,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(path),
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (state.capturedVideoPath != null) ...[
          const SizedBox(height: 16),
          _buildUploadCard(
            context,
            Icons.video_call_outlined,
            'METER VIDEO',
            path: state.capturedVideoPath,
            onTap: notifier.captureVideo,
            onRemove: notifier.captureVideo,
            isVideo: true,
          ),
        ],
        if (state.estimatedLoadWatts != null) ...[
          const SizedBox(height: 16),
          _buildReviewCard(
            icon: Icons.electrical_services_outlined,
            title: 'Estimated Utility Load',
            content: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${state.estimatedLoadWatts}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Watts',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        _buildSectionHeader('MAP PREVIEW'),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Container(color: Colors.grey.shade100),
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        color: AppTheme.primary,
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Satellite View Preview',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textLight,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleField(
    String label,
    List<String> options,
    String selectedValue,
    Function(String) onSelected, {
    bool small = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: options.map((opt) {
              final isSelected = opt == selectedValue;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelected(opt),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: small ? 8 : 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      opt,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.textLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> items,
    String selectedValue,
    Function(String) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedValue,
              icon: const Icon(Icons.expand_more),
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) => onSelected(val!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionCard(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color:
                    subtitle.contains('Select') ||
                        subtitle.contains('Choose') ||
                        subtitle.contains('Initial')
                    ? AppTheme.primary.withValues(alpha: 0.5)
                    : AppTheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthSelectionCard(
    IconData icon,
    String title,
    String subtitle, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: subtitle.contains('Choose')
                        ? AppTheme.primary.withValues(alpha: 0.5)
                        : AppTheme.primary,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }

  Widget _buildFindingsSelector(
    BuildContext context,
    String currentFinding,
    AddMeterNotifier notifier,
  ) {
    return GestureDetector(
      onTap: () => _showFindingsPicker(context, notifier),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: currentFinding.isNotEmpty
                ? AppTheme.primary.withValues(alpha: 0.2)
                : AppTheme.borderLight,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.assignment_late_outlined,
                color: AppTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TECHNICAL FINDINGS',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.textLight,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    currentFinding.isEmpty
                        ? 'Select technical finding'
                        : currentFinding,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: currentFinding.isEmpty
                          ? AppTheme.textLight.withValues(alpha: 0.5)
                          : AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }

  void _showFindingsPicker(BuildContext context, AddMeterNotifier notifier) {
    final findings = [
      'Tampered Meter',
      'Meter By-pass',
      'Already Disconnected',
      'Relay Not Tripping',
      'Communication Error',
      'Direct Connection',
      'Unauthorized Service conn.',
      'Unit Recovery',
      'Others',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TECHNICAL FINDINGS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Select field observation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: findings.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = findings[index];
                  return ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      if (item == 'Others') {
                        _showCustomFindingInput(context, notifier);
                      } else {
                        notifier.updateFindings(item);
                      }
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: Colors.grey.shade50,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item == 'Others' ? Icons.edit_note : Icons.adjust,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      item,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppTheme.textLight,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomFindingInput(
    BuildContext context,
    AddMeterNotifier notifier,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Other Finding',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        content: CustomTextField(
          label: 'Describe Observation',
          hint: 'Type findings here...',
          controller: controller,
          maxLines: 3,
          prefixIcon: Icons.edit_note,
          autoFocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: AppTheme.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                notifier.updateFindings(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'ADD FINDING',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadCard(
    BuildContext context,
    IconData icon,
    String label, {
    String? path,
    VoidCallback? onTap,
    VoidCallback? onRemove,
    bool isVideo = false,
  }) {
    final hasCapture = path != null;

    return GestureDetector(
      onTap: hasCapture
          ? (isVideo ? () => _showVideoPlayer(context, path) : null)
          : onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: hasCapture ? Colors.black : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.borderLight,
            style: BorderStyle.solid,
          ),
          image: (hasCapture && !isVideo)
              ? DecorationImage(
                  image: FileImage(File(path)),
                  fit: BoxFit.cover,
                  opacity: 0.6,
                )
              : null,
        ),
        child: Stack(
          children: [
            if (hasCapture) ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isVideo ? Icons.play_circle_fill : Icons.check_circle,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isVideo ? 'VIDEO CAPTURED' : 'IMAGE CAPTURED',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.accent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh, color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'RETAKE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: AppTheme.primary, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isVideo ? 'Tap to record video' : 'Tap to capture',
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard({
    required IconData icon,
    required String title,
    List<Widget>? rows,
    Widget? content,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          if (rows != null) ...[const SizedBox(height: 16), ...rows],
          if (content != null) ...[const SizedBox(height: 16), content],
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value, {bool isLabel = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: isLabel
                ? UnconstrainedBox(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                  )
                : Text(
                    value.isEmpty ? 'N/A' : value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    WidgetRef ref,
    AddMeterState state,
    AddMeterNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: AppTheme.borderLight.withValues(alpha: 0.5)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -10),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: CustomButton(
              text: 'BACK',
              type: ButtonType.outlined,
              onPressed: () {
                if (state.currentStep > 0) {
                  notifier.prevStep();
                } else {
                  context.pop();
                }
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: state.currentStep == 2 ? 'CONFIRM & SUBMIT' : 'NEXT',
              key: const ValueKey('nextButton'),
              icon: state.currentStep == 2 ? Icons.send : Icons.arrow_forward,
              type: ButtonType.accent,
              isLoading: state.isUploading,
              onPressed: () async {
                bool isValid = true;
                if (state.currentStep == 0 && !state.isStep1Valid) {
                  isValid = false;
                }
                if (state.currentStep == 1 && !state.isStep2Valid) {
                  isValid = false;
                }

                if (!isValid) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Please fill all required fields and capture an image.',
                      ),
                    ),
                  );
                  return;
                }

                if (state.currentStep < 2) {
                  notifier.nextStep();
                } else {
                  // 1. Upload media to Google Drive first
                  try {
                    final mediaUrls = await notifier.uploadMediaToDrive();

                    if (mediaUrls == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to upload media to Google Drive. Please ensure you are signed in.',
                            ),
                          ),
                        );
                      }
                      return;
                    }

                    final imageUrls = List<String>.from(
                      mediaUrls['imageUrls'] as List,
                    );
                    final videoUrl = mediaUrls['videoUrl'] as String?;

                    // 2. Final submission logic with Drive URLs
                    final meter = Meter(
                      id: state.meterId,
                      customerName: state.customerName,
                      address: state.address,
                      telephone: state.telephone,
                      tariffClass: state.tariffClass,
                      gpsCoordinates: state.gpsCoordinates,
                      tariffActivity: state.tariffActivity == 'Residential'
                          ? TariffActivity.residential
                          : (state.tariffActivity == 'Commercial'
                                ? TariffActivity.commercial
                                : TariffActivity.industrial),
                      geocode: state.geocode,
                      spnNumber: state.spnNumber,
                      brand: state.meterBrand,
                      rating: state.meterRating,
                      phase: state.meterPhase == '1-Phase'
                          ? MeterPhase.single
                          : MeterPhase.three,
                      type: state.meteringType == 'Prepaid'
                          ? MeteringType.prepaid
                          : MeteringType.postpaid,
                      status: MeterStatus.pending,
                      installationDate: DateTime.now(),
                      findings: state.findings,
                      initialReadings: state.initialReadings,
                      capturedImagePaths: imageUrls,
                      capturedVideoPath: videoUrl,
                      isSynced: false,
                    );

                    ref.read(meterRepositoryProvider).addMeter(meter).then((_) {
                      if (context.mounted) {
                        ref.read(syncProvider.notifier).notifyNewMeterAdded();
                        notifier.reset();
                        ref.invalidate(metersProvider);
                        ref.invalidate(searchedMetersProvider);
                        context.go('/success');
                      }
                    });
                  } catch (e) {
                    if (context.mounted) {
                      String message =
                          'Failed to upload media to Google Drive.';
                      if (e.toString().contains('QUOTA_ERROR')) {
                        message =
                            'Google Drive storage quota exceeded. Please clear some space in your Google Drive or use a different account.';
                      } else if (e.toString().contains('NOT_SIGNED_IN')) {
                        message =
                            'Google Sign-In is required to upload media. Please try again and complete the sign-in process.';
                      } else {
                        message = 'An error occurred during upload: $e';
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(message),
                          backgroundColor: AppTheme.accent,
                          duration: const Duration(seconds: 10),
                          action: SnackBarAction(
                            label: 'DISMISS',
                            textColor: Colors.white,
                            onPressed: () {},
                          ),
                        ),
                      );
                    }
                    return;
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLocationCapture(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final service = ref.read(deviceServiceProvider);
    final notifier = ref.read(addMeterProvider.notifier);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // 1. Check if service is enabled
    final enabled = await service.isLocationServiceEnabled();
    if (!enabled) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Please enable location services in your device settings.',
          ),
        ),
      );
      return;
    }

    // 2. Check current permission status
    var permission = await service.checkLocationPermission();

    if (permission == LocationPermission.denied) {
      // Show custom explanation before triggering system prompt
      if (!context.mounted) return;
      final proceed = await _showPermissionExplanationDialog(context);
      if (proceed == true) {
        await notifier.fetchLocation();
      }
    } else if (permission == LocationPermission.deniedForever) {
      // Permanently denied, needs settings redirect
      if (!context.mounted) return;
      await _showSettingsRedirectDialog(context, ref);
    } else {
      // Already allowed (whileInUse or always)
      await notifier.fetchLocation();
    }
  }

  Future<bool?> _showPermissionExplanationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: AppTheme.primary),
            SizedBox(width: 8),
            Text('Location Access'),
          ],
        ),
        content: const Text(
          'To accurately record the meter installation site, we need to capture your GPS coordinates. '
          'This ensures the meter is correctly mapped in our system.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('ALLOW'),
          ),
        ],
      ),
    );
  }

  Future<void> _showSettingsRedirectDialog(
    BuildContext context,
    WidgetRef ref,
  ) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Permissions Needed'),
          ],
        ),
        content: const Text(
          'Location permissions are permanently denied. Please enable them in the app settings to use this feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(deviceServiceProvider).openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('OPEN SETTINGS'),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(BuildContext context, String imagePath) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Hero(
                    tag: imagePath,
                    child: Image.file(File(imagePath), fit: BoxFit.contain),
                  ),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 20,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: MediaQuery.of(context).padding.bottom + 40,
                left: 0,
                right: 0,
                child: const Center(
                  child: Text(
                    'Pinch to zoom',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showVideoPlayer(BuildContext context, String videoPath) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return VideoPlayerOverlay(videoPath: videoPath);
      },
    );
  }

  void _showBrandPicker(BuildContext context, AddMeterNotifier notifier) {
    final brands = [
      'Landis+Gyr',
      'Itron',
      'Holley',
      'Hexing',
      'Clou',
      'Wasion',
      'Nuri',
      'Others',
    ];

    _showGenericPicker(
      context,
      title: 'METER BRAND',
      subtitle: 'Select manufacturer',
      items: brands,
      onSelected: (item) {
        if (item == 'Others') {
          _showCustomInput(
            context,
            'Other Brand',
            'Enter meter brand',
            (val) => notifier.updateMeterBrand(val),
          );
        } else {
          notifier.updateMeterBrand(item);
        }
      },
    );
  }

  void _showRatingPicker(BuildContext context, AddMeterNotifier notifier) {
    final ratings = ['5 (60)A', '10 (100)A', '20 (80)A', '40 (100)A', 'Others'];

    _showGenericPicker(
      context,
      title: 'METER RATING',
      subtitle: 'Select capacity',
      items: ratings,
      onSelected: (item) {
        if (item == 'Others') {
          _showCustomInput(
            context,
            'Other Rating',
            'Enter meter rating (e.g. 30A)',
            (val) => notifier.updateMeterRating(val),
          );
        } else {
          notifier.updateMeterRating(item);
        }
      },
    );
  }

  void _showReadingsInput(BuildContext context, AddMeterNotifier notifier) {
    _showCustomInput(
      context,
      'Current Readings',
      'Enter Initial KWh',
      (val) => notifier.updateInitialReadings(val),
      keyboardType: TextInputType.number,
      icon: Icons.speed,
    );
  }

  void _showGenericPicker(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<String> items,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: AppTheme.textLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(item);
                    },
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    tileColor: Colors.grey.shade50,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item == 'Others' ? Icons.edit_note : Icons.adjust,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      item,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppTheme.textLight,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomInput(
    BuildContext context,
    String title,
    String hint,
    Function(String) onSubmitted, {
    TextInputType keyboardType = TextInputType.text,
    IconData icon = Icons.edit_note,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              label: title,
              hint: hint,
              controller: controller,
              maxLines: 1,
              prefixIcon: icon,
              autoFocus: true,
              keyboardType: keyboardType,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: AppTheme.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                onSubmitted(controller.text);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'SAVE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
