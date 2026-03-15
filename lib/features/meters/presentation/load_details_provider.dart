import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/appliance.dart';
import 'package:flutter/material.dart';

class LoadDetailsState {
  final ApplianceCategory selectedCategory;
  final Map<String, int> selections; // Appliance ID -> Quantity
  final List<CustomLoad> customSelections;
  final Map<String, String> selectedVariants; // Appliance ID -> Variant Name

  LoadDetailsState({
    this.selectedCategory = ApplianceCategory.residential,
    this.selections = const {},
    this.customSelections = const [],
    this.selectedVariants = const {},
  });

  LoadDetailsState copyWith({
    ApplianceCategory? selectedCategory,
    Map<String, int>? selections,
    List<CustomLoad>? customSelections,
    Map<String, String>? selectedVariants,
  }) {
    return LoadDetailsState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selections: selections ?? this.selections,
      customSelections: customSelections ?? this.customSelections,
      selectedVariants: selectedVariants ?? this.selectedVariants,
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

  void incrementAppliance(String id) {
    final currentQty = state.selections[id] ?? 0;
    
    // If first time adding, and it has variants, pick the first one
    Map<String, String> newVariants = Map.from(state.selectedVariants);
    if (currentQty == 0) {
      final allApps = ref.read(appliancesProvider);
      final appliance = allApps.firstWhere((a) => a.id == id);
      if (appliance.variants != null && appliance.variants!.isNotEmpty) {
        newVariants[id] = appliance.variants!.keys.first;
      }
    }

    state = state.copyWith(
      selections: {
        ...state.selections,
        id: currentQty + 1,
      },
      selectedVariants: newVariants,
    );
  }

  void setApplianceVariant(String id, String variant) {
    state = state.copyWith(
      selectedVariants: {
        ...state.selectedVariants,
        id: variant,
      },
    );
  }

  void decrementAppliance(String id) {
    final currentQty = state.selections[id] ?? 0;
    if (currentQty <= 0) return;
    
    final newSelections = Map<String, int>.from(state.selections);
    if (currentQty == 1) {
      newSelections.remove(id);
    } else {
      newSelections[id] = currentQty - 1;
    }
    
    state = state.copyWith(selections: newSelections);
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
    state.selections.forEach((id, qty) {
      final appliance = allAppliances.firstWhere((a) => a.id == id);
      
      // Check if a variant is selected and has wattage
      int wattage = appliance.averageWattage;
      final selectedVariant = state.selectedVariants[id];
      if (selectedVariant != null && appliance.variants != null) {
        wattage = appliance.variants![selectedVariant] ?? wattage;
      }
      
      total += wattage * qty;
    });
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
