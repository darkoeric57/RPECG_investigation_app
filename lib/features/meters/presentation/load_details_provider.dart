import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/appliance.dart';
import 'package:flutter/material.dart';

class ApplianceSelection {
  final String applianceId;
  final String? variant;
  final int quantity;

  const ApplianceSelection({
    required this.applianceId,
    this.variant,
    this.quantity = 1,
  });

  ApplianceSelection copyWith({String? applianceId, String? variant, int? quantity}) {
    return ApplianceSelection(
      applianceId: applianceId ?? this.applianceId,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
    );
  }
}

class LoadDetailsState {
  final ApplianceCategory selectedCategory;
  final List<ApplianceSelection> applianceSelections;
  final List<CustomLoad> customSelections;
  final Map<String, String> activeVariants; // Appliance ID -> Last UI-selected variant

  LoadDetailsState({
    this.selectedCategory = ApplianceCategory.residential,
    this.applianceSelections = const [],
    this.customSelections = const [],
    this.activeVariants = const {},
  });

  LoadDetailsState copyWith({
    ApplianceCategory? selectedCategory,
    List<ApplianceSelection>? applianceSelections,
    List<CustomLoad>? customSelections,
    Map<String, String>? activeVariants,
  }) {
    return LoadDetailsState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      applianceSelections: applianceSelections ?? this.applianceSelections,
      customSelections: customSelections ?? this.customSelections,
      activeVariants: activeVariants ?? this.activeVariants,
    );
  }
}

class CustomLoad {
  final String name;
  final int wattage;
  final int quantity;

  const CustomLoad({
    required this.name,
    required this.wattage,
    this.quantity = 1,
  });

  CustomLoad copyWith({String? name, int? wattage, int? quantity}) {
    return CustomLoad(
      name: name ?? this.name,
      wattage: wattage ?? this.wattage,
      quantity: quantity ?? this.quantity,
    );
  }
}

class LoadDetailsNotifier extends Notifier<LoadDetailsState> {
  @override
  LoadDetailsState build() => LoadDetailsState();

  void setCategory(ApplianceCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  void incrementAppliance(String id, {String? variant}) {
    // If no variant provided, use the last active variant or default to first
    String? targetVariant = variant;
    if (targetVariant == null) {
      final allApps = ref.read(appliancesProvider);
      final appliance = allApps.firstWhere((a) => a.id == id);
      if (appliance.variants != null && appliance.variants!.isNotEmpty) {
        targetVariant = state.activeVariants[id] ?? appliance.variants!.keys.first;
      }
    }

    final existingIndex = state.applianceSelections.indexWhere(
      (s) => s.applianceId == id && s.variant == targetVariant
    );

    List<ApplianceSelection> newList = List.from(state.applianceSelections);
    Map<String, String> newActiveVariants = Map.from(state.activeVariants);
    if (targetVariant != null) {
      newActiveVariants[id] = targetVariant;
    }

    if (existingIndex != -1) {
      newList[existingIndex] = newList[existingIndex].copyWith(
        quantity: newList[existingIndex].quantity + 1
      );
    } else {
      newList.add(ApplianceSelection(
        applianceId: id,
        variant: targetVariant,
        quantity: 1
      ));
    }

    state = state.copyWith(
      applianceSelections: newList,
      activeVariants: newActiveVariants,
    );
  }

  void decrementAppliance(String id, {String? variant}) {
    String? targetVariant = variant;
    if (targetVariant == null) {
      targetVariant = state.activeVariants[id];
    }

    final existingIndex = state.applianceSelections.indexWhere(
      (s) => s.applianceId == id && s.variant == targetVariant
    );

    if (existingIndex == -1) return;

    List<ApplianceSelection> newList = List.from(state.applianceSelections);
    if (newList[existingIndex].quantity <= 1) {
      newList.removeAt(existingIndex);
    } else {
      newList[existingIndex] = newList[existingIndex].copyWith(
        quantity: newList[existingIndex].quantity - 1
      );
    }

    state = state.copyWith(applianceSelections: newList);
  }

  void setApplianceVariant(String id, String variant) {
    Map<String, String> newActiveVariants = Map.from(state.activeVariants);
    newActiveVariants[id] = variant;
    state = state.copyWith(activeVariants: newActiveVariants);
  }

  void addCustomLoad(String name, int wattage) {
    state = state.copyWith(
      customSelections: [
        ...state.customSelections,
        CustomLoad(name: name, wattage: wattage),
      ],
    );
  }

  void incrementCustomLoad(int index) {
    final newList = List<CustomLoad>.from(state.customSelections);
    newList[index] = newList[index].copyWith(quantity: newList[index].quantity + 1);
    state = state.copyWith(customSelections: newList);
  }

  void decrementCustomLoad(int index) {
    final newList = List<CustomLoad>.from(state.customSelections);
    final currentQty = newList[index].quantity;
    
    if (currentQty <= 1) {
      newList.removeAt(index);
    } else {
      newList[index] = newList[index].copyWith(quantity: currentQty - 1);
    }
    state = state.copyWith(customSelections: newList);
  }

  void removeCustomLoad(int index) {
    final newList = List<CustomLoad>.from(state.customSelections);
    newList.removeAt(index);
    state = state.copyWith(customSelections: newList);
  }

  void reset() {
    state = LoadDetailsState();
  }

  int calculateTotalWattage(List<Appliance> allAppliances) {
    int total = 0;
    for (var selection in state.applianceSelections) {
      final appliance = allAppliances.firstWhere((a) => a.id == selection.applianceId);
      
      int wattage = appliance.averageWattage;
      if (selection.variant != null && appliance.variants != null) {
        wattage = appliance.variants![selection.variant] ?? wattage;
      }
      
      total += wattage * selection.quantity;
    }
    for (var custom in state.customSelections) {
      total += custom.wattage * custom.quantity;
    }
    return total;
  }
}

final loadDetailsProvider = NotifierProvider<LoadDetailsNotifier, LoadDetailsState>(LoadDetailsNotifier.new);

// Static data for appliances
final appliancesProvider = Provider<List<Appliance>>((ref) {
  return [
    // Residential
    const Appliance(
      id: 'res_ac',
      name: 'Air Conditioner',
      wattageDisplay: '1,200W - 2,800W',
      averageWattage: 1200,
      category: ApplianceCategory.residential,
      icon: Icons.ac_unit,
      isHeavyLoad: true,
      variants: {
        '1.5 HP': 1200,
        '2.5 HP': 2000,
        '3.5 HP': 2800,
      },
    ),
    const Appliance(
      id: 'res_fridge',
      name: 'Fridge-Freezer',
      wattageDisplay: '150W - 400W',
      averageWattage: 275,
      category: ApplianceCategory.residential,
      icon: Icons.kitchen,
    ),
    const Appliance(
      id: 'res_wash',
      name: 'Washing Machine',
      wattageDisplay: '500W - 2,000W',
      averageWattage: 1250,
      category: ApplianceCategory.residential,
      icon: Icons.local_laundry_service,
    ),
    const Appliance(
      id: 'res_tv',
      name: 'Smart TV',
      wattageDisplay: '60W - 150W',
      averageWattage: 105,
      category: ApplianceCategory.residential,
      icon: Icons.tv,
    ),
    const Appliance(
      id: 'res_iron',
      name: 'Electric Iron',
      wattageDisplay: '1,000W - 2,000W',
      averageWattage: 1500,
      category: ApplianceCategory.residential,
      icon: Icons.iron,
    ),
    const Appliance(
      id: 'res_micro',
      name: 'Microwave',
      wattageDisplay: '600W - 1,200W',
      averageWattage: 900,
      category: ApplianceCategory.residential,
      icon: Icons.microwave,
    ),
    const Appliance(
      id: 'res_fan',
      name: 'Fan',
      wattageDisplay: '65W - 100W',
      averageWattage: 80,
      category: ApplianceCategory.residential,
      icon: Icons.mode_fan_off,
    ),
    const Appliance(
      id: 'res_kettle',
      name: 'Electric Kettle',
      wattageDisplay: '2,000W - 3,000W',
      averageWattage: 2500,
      category: ApplianceCategory.residential,
      icon: Icons.bolt,
    ),
    const Appliance(
      id: 'res_freezer',
      name: 'Chest Freezer',
      wattageDisplay: '200W - 350W',
      averageWattage: 275,
      category: ApplianceCategory.residential,
      icon: Icons.kitchen_outlined,
    ),
    const Appliance(
      id: 'res_led',
      name: 'LED Bulb (Single)',
      wattageDisplay: '7W - 15W',
      averageWattage: 11,
      category: ApplianceCategory.residential,
      icon: Icons.lightbulb_outline,
    ),
    const Appliance(
      id: 'res_charger',
      name: 'Phone Chargers',
      wattageDisplay: '8W - 20W',
      averageWattage: 15,
      category: ApplianceCategory.residential,
      icon: Icons.smartphone,
    ),

    // Commercial
    const Appliance(
      id: 'com_sign',
      name: 'Outdoor Signage',
      wattageDisplay: '300W - 800W',
      averageWattage: 550,
      category: ApplianceCategory.commercial,
      icon: Icons.featured_video,
    ),
    const Appliance(
      id: 'com_chiller',
      name: 'Display Chiller',
      wattageDisplay: '800W - 1,500W',
      averageWattage: 1150,
      category: ApplianceCategory.commercial,
      icon: Icons.kitchen,
      isHeavyLoad: true,
    ),
    const Appliance(
      id: 'com_comp',
      name: 'Office Computers (x10)',
      wattageDisplay: '1,000W - 2,500W',
      averageWattage: 1750,
      category: ApplianceCategory.commercial,
      icon: Icons.computer,
    ),

    // Industrial
    const Appliance(
      id: 'ind_motor',
      name: '3-Phase Motor',
      wattageDisplay: '5,000W - 15,000W',
      averageWattage: 10000,
      category: ApplianceCategory.industrial,
      icon: Icons.settings_input_component,
      isHeavyLoad: true,
    ),
    const Appliance(
      id: 'ind_welder',
      name: 'Arc Welder',
      wattageDisplay: '3,000W - 8,000W',
      averageWattage: 5500,
      category: ApplianceCategory.industrial,
      icon: Icons.bolt,
      isHeavyLoad: true,
    ),
  ];
});
