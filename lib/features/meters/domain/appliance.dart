import 'package:flutter/material.dart';

enum ApplianceCategory { residential, commercial, industrial }

class Appliance {
  final String id;
  final String name;
  final String wattageDisplay;
  final int averageWattage;
  final ApplianceCategory category;
  final IconData icon;
  final bool isHeavyLoad;

  const Appliance({
    required this.id,
    required this.name,
    required this.wattageDisplay,
    required this.averageWattage,
    required this.category,
    required this.icon,
    this.isHeavyLoad = false,
  });
}

class LoadItem {
  final Appliance appliance;
  final int quantity;

  const LoadItem({
    required this.appliance,
    required this.quantity,
  });

  int get totalWattage => appliance.averageWattage * quantity;
}
