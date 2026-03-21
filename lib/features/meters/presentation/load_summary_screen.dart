import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/appliance.dart';
import 'load_details_provider.dart';
import 'add_meter_provider.dart';

class LoadSummaryScreen extends ConsumerWidget {
  const LoadSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loadDetailsProvider);
    final allAppliances = ref.watch(appliancesProvider);
    final totalWatts = ref.read(loadDetailsProvider.notifier).calculateTotalWattage(allAppliances);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              _buildHeroSection(),
              _buildCategoryHeader(context, state),
              _buildBentoGrid(context, state, allAppliances),
              _buildDistributionChart(context, state, allAppliances),
              const SliverToBoxAdapter(child: SizedBox(height: 180)), // Space for sticky panel
            ],
          ),
          _buildStickyPanel(context, ref, totalWatts),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.8),
      floating: true,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Add Load Details',
        style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppTheme.textDark),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeroSection() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'CALCULATION OVERVIEW',
              style: TextStyle(
                color: Color(0xFF00236F),
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Load Summary',
              style: TextStyle(
                color: AppTheme.textDark,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Review the technical distribution of electrical loads for the selected residential unit before finalizing the report.',
              style: TextStyle(
                color: AppTheme.textLight.withValues(alpha: 0.8),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, LoadDetailsState state) {
    final itemCount = state.applianceSelections.length + state.customSelections.length;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.home_work, color: Color(0xFF6D5E00), size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Residential',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.textDark),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFCDF46),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$itemCount ITEMS',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: Color(0xFF726200)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoGrid(BuildContext context, LoadDetailsState state, List<Appliance> allAppliances) {
    final selectedItems = <Widget>[];

    // Standard Appliances
    for (var selection in state.applianceSelections) {
      final appliance = allAppliances.firstWhere((a) => a.id == selection.applianceId);
      
      int wattage;
      if (selection.overriddenWattage != null) {
        wattage = selection.overriddenWattage!;
      } else {
        wattage = appliance.averageWattage;
        if (selection.variant != null && appliance.variants != null) {
          wattage = appliance.variants![selection.variant] ?? wattage;
        }
      }
      
      final displayName = selection.variant != null 
          ? '${appliance.name} (${selection.variant})' 
          : appliance.name;
      
      selectedItems.add(_buildApplianceCard(displayName, appliance.icon, selection.quantity, wattage * selection.quantity));
    }

    // Custom Loads
    for (var custom in state.customSelections) {
      selectedItems.add(_buildApplianceCard(custom.name, Icons.bolt, custom.quantity, custom.wattage * custom.quantity));
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.95,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
             return selectedItems[index];
          },
          childCount: selectedItems.length,
        ),
      ),
    );
  }

  Widget _buildApplianceCard(String name, IconData icon, int qty, int watts) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.06),
            blurRadius: 32,
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 24),
              ),
              const Icon(Icons.more_horiz, color: AppTheme.textLight, size: 16),
            ],
          ),
          const Spacer(),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Qty: x$qty',
                style: const TextStyle(fontSize: 9, color: AppTheme.textLight, fontWeight: FontWeight.w600),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _formatNumber(watts),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primary),
                  ),
                  const Text('W', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 9, color: AppTheme.primary)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionChart(BuildContext context, LoadDetailsState state, List<Appliance> allAppliances) {
    double hvac = 0;
    double appliances = 0;
    double lighting = 0;
    double others = 0;

    for (var selection in state.applianceSelections) {
      final app = allAppliances.firstWhere((a) => a.id == selection.applianceId);
      
      int wattage;
      if (selection.overriddenWattage != null) {
        wattage = selection.overriddenWattage!;
      } else {
        wattage = app.averageWattage;
        if (selection.variant != null && app.variants != null) {
          wattage = app.variants![selection.variant] ?? wattage;
        }
      }
      final value = wattage * selection.quantity;
      
      if (app.name.toLowerCase().contains('ac') || app.name.toLowerCase().contains('heater')) {
        hvac += value;
      } else if (app.name.toLowerCase().contains('light')) {
        lighting += value;
      } else {
        appliances += value;
      }
    }

    for (var custom in state.customSelections) {
      others += custom.wattage * custom.quantity;
    }

    double total = hvac + appliances + lighting + others;
    if (total == 0) total = 1;

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
      sliver: SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Estimated Load Distribution',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildChartBar(hvac / total, const Color(0xFFFFE24C)),
                  const SizedBox(width: 4),
                  _buildChartBar(appliances / total, const Color(0xFFFFE24C).withValues(alpha: 0.4)),
                  const SizedBox(width: 4),
                  _buildChartBar(lighting / total, const Color(0xFFFFE24C).withValues(alpha: 0.2)),
                  const SizedBox(width: 4),
                  _buildChartBar(others / total, const Color(0xFFFFE24C).withValues(alpha: 0.1)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _ChartLabel(label: 'HVAC'),
                  _ChartLabel(label: 'APPLIANCES'),
                  _ChartLabel(label: 'LIGHTING'),
                  _ChartLabel(label: 'OTHERS'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartBar(double factor, Color color) {
    return Expanded(
      child: Container(
        height: 60 * (factor < 0.1 ? 0.1 : factor), // Min height for vis
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildStickyPanel(BuildContext context, WidgetRef ref, int totalWatts) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 32,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL ESTIMATED LOAD',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.textLight,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatNumber(totalWatts),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textDark),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Watts',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textLight),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PEAK LOAD',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF410003)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Update the main stepper state
                ref.read(addMeterProvider.notifier).updateEstimatedLoad(totalWatts);
                // Final confirm and save - pop twice to get back to the stepper
                Navigator.of(context).pop(); // Pop Summary
                Navigator.of(context).pop(); // Pop Details
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBA1A1A),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.verified, size: 20),
                  SizedBox(width: 12),
                  Text(
                    'Confirm & Save Load',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

class _ChartLabel extends StatelessWidget {
  final String label;
  const _ChartLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF90A8FF),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
