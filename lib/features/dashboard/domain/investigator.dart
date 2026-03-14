import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

part 'investigator.g.dart';

@HiveType(typeId: 5)
enum InvestigatorStatus { 
  @HiveField(0) online, 
  @HiveField(1) offline 
}

@HiveType(typeId: 6)
class Investigator {
  @HiveField(0) final String id;
  @HiveField(1) final String name;
  @HiveField(2) final String location;
  @HiveField(3) final String imageUrl;
  @HiveField(4) final InvestigatorStatus status;

  Investigator({
    required this.id,
    required this.name,
    required this.location,
    required this.imageUrl,
    required this.status,
  });
}
