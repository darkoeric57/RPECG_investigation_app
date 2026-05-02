import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/backoffice_providers.dart';
import '../../../../features/meters/domain/meter.dart';

class PremiumFilterDrawer extends ConsumerWidget {
  const PremiumFilterDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      width: 450,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, ref),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('METER STATUS'),
                  const SizedBox(height: 16),
                  _buildStatusChips(ref),
                  const SizedBox(height: 40),
                  
                  _buildSectionTitle('METER BRANDS'),
                  const SizedBox(height: 16),
                  _buildMultiSelectSection(
                    ref: ref,
                    provider: meterBrandFilterSetProvider,
                    availableValues: ref.watch(availableFilterValuesProvider).brands,
                    emptyHint: 'No brands found in current data',
                  ),
                  const SizedBox(height: 40),

                  _buildSectionTitle('FIELD FINDINGS'),
                  const SizedBox(height: 16),
                  _buildMultiSelectSection(
                    ref: ref,
                    provider: meterFindingsFilterSetProvider,
                    availableValues: ref.watch(availableFilterValuesProvider).findingsKeywords,
                    emptyHint: 'No findings recorded in current data',
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          _buildFooter(context, ref),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 40, 32, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advanced Filters',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.primary),
              ),
              SizedBox(height: 4),
              Text(
                'Refine infrastructure visibility',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: AppTheme.primary),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFF1F5F9),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildStatusChips(WidgetRef ref) {
    final activeStatuses = ref.watch(meterStatusFilterSetProvider);
    final availableStatuses = ref.watch(availableFilterValuesProvider).statuses;
    
    final options = [
      {'label': 'Paid', 'value': MeterStatus.paid, 'color': const Color(0xFF10B981)},
      {'label': 'Pending', 'value': MeterStatus.pending, 'color': const Color(0xFFF59E0B)},
      {'label': 'Billed', 'value': MeterStatus.billed, 'color': const Color(0xFF6366F1)},
      {'label': 'Scheduled', 'value': MeterStatus.scheduled, 'color': const Color(0xFFA855F7)},
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.where((opt) => availableStatuses.contains(opt['value'])).map((opt) {
        final val = opt['value'] as MeterStatus;
        final isSelected = activeStatuses.contains(val);
        final color = opt['color'] as Color?;
        
        return ChoiceChip(
          label: Text(opt['label'] as String),
          selected: isSelected,
          onSelected: (selected) {
            final current = Set<MeterStatus>.from(activeStatuses);
            if (selected) {
              current.add(val);
            } else {
              current.remove(val);
            }
            ref.read(meterStatusFilterSetProvider.notifier).state = current;
          },
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          selectedColor: color ?? AppTheme.primary,
          backgroundColor: const Color(0xFFF8FAFC),
          side: BorderSide(
            color: isSelected ? (color ?? AppTheme.primary) : const Color(0xFFE2E8F0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildMultiSelectSection({
    required WidgetRef ref,
    required StateProvider<Set<String>> provider,
    required Set<String> availableValues,
    required String emptyHint,
  }) {
    final selectedValues = ref.watch(provider);
    
    if (availableValues.isEmpty) {
      return Text(emptyHint, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 13));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableValues.map((val) {
        final isSelected = selectedValues.contains(val);
        return FilterChip(
          label: Text(val),
          selected: isSelected,
          onSelected: (selected) {
            final current = Set<String>.from(selectedValues);
            if (selected) {
              current.add(val);
            } else {
              current.remove(val);
            }
            ref.read(provider.notifier).state = current;
          },
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
          selectedColor: AppTheme.primary,
          backgroundColor: Colors.white,
          checkmarkColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                ref.read(meterStatusFilterSetProvider.notifier).state = {};
                ref.read(meterBrandFilterSetProvider.notifier).state = {};
                ref.read(meterFindingsFilterSetProvider.notifier).state = {};
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: const Text('Reset All', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
