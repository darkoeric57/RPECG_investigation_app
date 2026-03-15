import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/appliance.dart';
import 'load_details_provider.dart';

class CustomLoadScreen extends ConsumerStatefulWidget {
  const CustomLoadScreen({super.key});

  @override
  ConsumerState<CustomLoadScreen> createState() => _CustomLoadScreenState();
}

class _CustomLoadScreenState extends ConsumerState<CustomLoadScreen> {
  final _nameController = TextEditingController();
  final _wattsController = TextEditingController();
  ApplianceCategory _selectedCategory = ApplianceCategory.residential;
  double _intensity = 0.5;

  @override
  void dispose() {
    _nameController.dispose();
    _wattsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'SYSTEM CONFIGURATION',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Define Your\nCustom Load',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Precisely track energy consumption by adding custom electrical profiles to your investigation dashboard.',
                style: TextStyle(
                  color: AppTheme.textLight.withOpacity(0.8),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              
              // Appliance Name Card
              _buildInputCard(
                label: 'APPLIANCE NAME',
                child: Row(
                  children: [
                    const Icon(Icons.settings_input_component, color: AppTheme.primary, size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        textCapitalization: TextCapitalization.words,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        decoration: InputDecoration(
                          hintText: 'e.g., Industrial HVAC Unit',
                          hintStyle: TextStyle(color: AppTheme.textLight.withOpacity(0.4)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Category Selection Card
              _buildInputCard(
                label: 'CATEGORY',
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: ApplianceCategory.values.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? AppTheme.primary : AppTheme.borderLight,
                            width: 1,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ] : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCategoryIcon(cat),
                              size: 16,
                              color: isSelected ? Colors.white : AppTheme.textDark,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              cat.name[0].toUpperCase() + cat.name.substring(1),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isSelected ? Colors.white : AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 24),
              
              _buildInputCard(
                label: 'RATING',
                backgroundColor: AppTheme.accent,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 180,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            SizedBox(
                              width: 90,
                              child: TextField(
                                controller: _wattsController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                                decoration: InputDecoration(
                                  hintText: '0',
                                  hintStyle: TextStyle(color: Colors.black.withOpacity(0.2)),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            const Text(
                              'W',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'WATTAGE RATING',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.black54,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Slider Card
              _buildInputCard(
                label: '',
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.bolt, color: AppTheme.primary, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Load Intensity Adjustment',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'ACCURATE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _intensity,
                          backgroundColor: Colors.transparent,
                          valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('MINIMAL', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.textLight)),
                        Text('STANDARD OPERATION', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.textLight)),
                        Text('PEAK DEMAND', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: AppTheme.textLight)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Efficiency Card
              _buildEfficiencyCard(),
              
              const SizedBox(height: 32),
              
              // Add Button
              _buildAddButton(context),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard({required String label, required Widget child, Color? backgroundColor}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: backgroundColor == null ? Border.all(color: AppTheme.borderLight) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: backgroundColor != null ? Colors.black.withOpacity(0.6) : AppTheme.textLight,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  Widget _buildEfficiencyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
            child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EFFICIENCY ESTIMATE',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.textLight, letterSpacing: 1),
                ),
                Text(
                  'Calculating environmental impact...',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDark,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(color: AppTheme.accent, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        final name = _nameController.text;
        final watts = int.tryParse(_wattsController.text) ?? 0;
        
        if (name.isNotEmpty && watts > 0) {
          ref.read(loadDetailsProvider.notifier).addCustomLoad(name, watts);
          Navigator.pop(context);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 70),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
        elevation: 20,
        shadowColor: AppTheme.primary.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_circle, size: 24),
          SizedBox(width: 12),
          Text(
            'Add to List',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(ApplianceCategory cat) {
    switch (cat) {
      case ApplianceCategory.residential:
        return Icons.home_filled;
      case ApplianceCategory.commercial:
        return Icons.business_center;
      case ApplianceCategory.industrial:
        return Icons.factory;
    }
  }
}
