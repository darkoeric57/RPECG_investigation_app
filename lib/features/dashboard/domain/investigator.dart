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

  factory Investigator.fromMap(Map<dynamic, dynamic> map) {
    return Investigator(
      id: map['objectId'] as String,
      name: map['name'] as String,
      location: map['location'] as String? ?? 'Unknown',
      imageUrl: map['imageUrl'] as String? ?? '',
      status: InvestigatorStatus.values.byName(map['status'] as String? ?? 'offline'),
    );
  }
}
