import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../../../core/theme/app_theme.dart';
import '../domain/appliance.dart';
import 'load_details_provider.dart';
import 'custom_load_screen.dart';
import 'load_summary_screen.dart';

class LoadDetailsScreen extends ConsumerWidget {
  const LoadDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loadDetailsProvider);
    final notifier = ref.read(loadDetailsProvider.notifier);
    final allAppliances = ref.watch(appliancesProvider);
    
    final filteredAppliances = allAppliances.where((a) => a.category == state.selectedCategory).toList();
    final totalWatts = notifier.calculateTotalWattage(allAppliances);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context),
              _buildHeader(),
              _buildCategoryTabs(state, notifier),
              _buildApplianceGrid(filteredAppliances, state, notifier),
              _buildEfficiencyInsight(),
              _buildOtherAppliances(filteredAppliances, state, notifier),
              _buildCustomLoads(context, state, notifier),
              _buildAddCustomLoadButton(context, notifier),
              const SliverToBoxAdapter(child: SizedBox(height: 220)), // Space for bottom sheet
            ],
          ),
          _buildBottomSummary(context, totalWatts),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white.withOpacity(0.8),
      elevation: 0,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(color: Colors.transparent),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'Add Load Details',
        style: TextStyle(
          color: AppTheme.primary,
          fontWeight: FontWeight.w900,
          fontSize: 20,
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppTheme.textDark),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Text(
          'Select the category and appliances to calculate the total utility load.',
          style: TextStyle(
            color: AppTheme.textLight.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w500,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs(LoadDetailsState state, LoadDetailsNotifier notifier) {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: ApplianceCategory.values.map((cat) {
            final isSelected = state.selectedCategory == cat;
            return GestureDetector(
              onTap: () => notifier.setCategory(cat),
              child: Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accent : Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: isSelected 
                      ? [BoxShadow(color: AppTheme.accent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                      : null,
                  border: Border.all(color: isSelected ? AppTheme.accent : AppTheme.borderLight),
                ),
                child: Center(
                  child: Text(
                    cat.name[0].toUpperCase() + cat.name.substring(1),
                    style: TextStyle(
                      color: isSelected ? Colors.black : AppTheme.textLight,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildApplianceGrid(List<Appliance> filtered, LoadDetailsState state, LoadDetailsNotifier notifier) {
    final flagshipItems = filtered.take(4).toList();
    
    return SliverPadding(
      padding: const EdgeInsets.all(24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.9,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = flagshipItems[index];
            final qty = state.selections[item.id] ?? 0;
            final selectedVariant = state.selectedVariants[item.id];
            return _buildApplianceCard(item, qty, selectedVariant, notifier);
          },
          childCount: flagshipItems.length,
        ),
      ),
    );
  }

  Widget _buildApplianceCard(Appliance item, int qty, String? selectedVariant, LoadDetailsNotifier notifier) {
    final isSelected = qty > 0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      height: isSelected && item.variants != null ? 220 : 180, // Dynamic height for variants
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isSelected ? AppTheme.primary.withAlpha(50) : AppTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: isSelected ? AppTheme.primary.withOpacity(0.08) : Colors.black.withOpacity(0.03),
            blurRadius: isSelected ? 20 : 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (item.isHeavyLoad ? AppTheme.primary : AppTheme.secondary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: item.isHeavyLoad ? AppTheme.primary : AppTheme.textDark, size: 24),
              ),
              if (isSelected)
                _buildQuantityPicker(item.id, qty, notifier)
              else
                _buildAddButton(item.id, notifier),
            ],
          ),
          const Spacer(),
          Text(
            item.name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppTheme.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            item.variants != null && selectedVariant != null 
                ? '${item.variants![selectedVariant]} Watts ($selectedVariant)'
                : item.wattageDisplay,
            style: TextStyle(
              fontSize: 10, 
              color: isSelected ? AppTheme.primary : AppTheme.textLight.withOpacity(0.7), 
              fontWeight: FontWeight.bold
            ),
          ),
          if (isSelected && item.variants != null) ...[
            const SizedBox(height: 16),
            _buildVariantSelector(item, selectedVariant!, notifier),
          ],
          if (item.isHeavyLoad && (item.variants == null || !isSelected)) ...[
            const SizedBox(height: 12),
            _buildLoadIndicator(),
          ],
        ],
      ),
    );
  }

  Widget _buildVariantSelector(Appliance item, String selected, LoadDetailsNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: item.variants!.keys.map((variant) {
          final isSelected = variant == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => notifier.setApplianceVariant(item.id, variant),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                  ] : null,
                ),
                child: Center(
                  child: Text(
                    variant,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                      color: isSelected ? AppTheme.primary : AppTheme.textLight,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildQuantityPicker(String id, int qty, LoadDetailsNotifier notifier) {
    return _buildGenericQuantityPicker(
      qty: qty,
      onDecrement: () => notifier.decrementAppliance(id),
      onIncrement: () => notifier.incrementAppliance(id),
    );
  }

  Widget _buildCustomQuantityPicker(int index, int qty, LoadDetailsNotifier notifier) {
    return _buildGenericQuantityPicker(
      qty: qty,
      onDecrement: () => notifier.decrementCustomLoad(index),
      onIncrement: () => notifier.incrementCustomLoad(index),
    );
  }

  Widget _buildGenericQuantityPicker({
    required int qty,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onDecrement,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              child: Icon(Icons.remove, size: 14, color: AppTheme.textDark),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('$qty', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
          ),
          GestureDetector(
            onTap: onIncrement,
            child: const CircleAvatar(
              radius: 12,
              backgroundColor: AppTheme.primary,
              child: Icon(Icons.add, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String id, LoadDetailsNotifier notifier) {
    return GestureDetector(
      onTap: () => notifier.incrementAppliance(id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.backgroundLight,
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Text('Add', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primary)),
      ),
    );
  }

  Widget _buildLoadIndicator() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.borderLight,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: 0.7,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text('HEAVY', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.accent, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildEfficiencyInsight() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10))
            ],
          ),
          child: const Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Efficiency Insight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                  SizedBox(height: 8),
                  Text(
                    'Switching to LED Bulbs (7W-15W) can reduce your lighting load by up to 80% compared to traditional bulbs.',
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                  ),
                ],
              ),
              Positioned(
                right: -10,
                bottom: -10,
                child: Opacity(
                  opacity: 0.1,
                  child: Icon(Icons.lightbulb, size: 80, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherAppliances(List<Appliance> filtered, LoadDetailsState state, LoadDetailsNotifier notifier) {
    final others = filtered.skip(4).toList();
    if (others.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const Padding(
            padding: EdgeInsets.only(top: 16, bottom: 16),
            child: Text(
              'PREDEFINED LOADS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppTheme.textLight,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...others.map((item) {
            final qty = state.selections[item.id] ?? 0;
            final selectedVariant = state.selectedVariants[item.id];
            return _buildOtherItemCard(item, qty, selectedVariant, notifier);
          }),
        ]),
      ),
    );
  }

  Widget _buildOtherItemCard(Appliance item, int qty, String? selectedVariant, LoadDetailsNotifier notifier) {
    final isSelected = qty > 0;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? AppTheme.primary.withAlpha(50) : AppTheme.borderLight),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(item.icon, color: isSelected ? AppTheme.primary : AppTheme.textLight, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    Text(
                      item.variants != null && selectedVariant != null 
                        ? '${item.variants![selectedVariant]} Watts ($selectedVariant)'
                        : item.wattageDisplay, 
                      style: TextStyle(fontSize: 10, color: isSelected ? AppTheme.primary : AppTheme.textLight)
                    ),
                  ],
                ),
              ),
              if (qty > 0)
                _buildQuantityPicker(item.id, qty, notifier)
              else
                IconButton(
                  onPressed: () => notifier.incrementAppliance(item.id),
                  icon: const Icon(Icons.add_circle, color: AppTheme.primary),
                ),
            ],
          ),
          if (isSelected && item.variants != null) ...[
            const SizedBox(height: 16),
            _buildVariantSelector(item, selectedVariant!, notifier),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomLoads(BuildContext context, LoadDetailsState state, LoadDetailsNotifier notifier) {
    if (state.customSelections.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Text(
              'CUSTOM LOADS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: AppTheme.textLight,
                letterSpacing: 1.2,
              ),
            ),
          ),
          ...state.customSelections.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.electrical_services, color: AppTheme.primary, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        Text('${item.wattage} Watts', style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
                      ],
                    ),
                  ),
                  _buildCustomQuantityPicker(index, item.quantity, notifier),
                ],
              ),
            );
          }),
        ]),
      ),
    );
  }

  Widget _buildAddCustomLoadButton(BuildContext context, LoadDetailsNotifier notifier) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CustomLoadScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.secondary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppTheme.secondary.withOpacity(0.3),
                width: 2,
                style: BorderStyle.none, // We'll use a custom painter if we want real dashes
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: AppTheme.secondary, shape: BoxShape.circle),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 16),
                const Text(
                  'ADD CUSTOM LOAD',
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildBottomSummary(BuildContext context, int totalWatts) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL ESTIMATED LOAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.textLight, letterSpacing: 1)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('$totalWatts', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.primary)),
                        const SizedBox(width: 4),
                        const Text('Watts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('REAL-TIME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoadSummaryScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: const Text('SAVE LOAD DETAILS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
