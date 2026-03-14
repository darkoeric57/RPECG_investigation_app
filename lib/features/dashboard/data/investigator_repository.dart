import 'package:hive/hive.dart';
import '../domain/investigator.dart';

abstract class InvestigatorRepository {
  Future<List<Investigator>> getInvestigators();
  Future<void> saveInvestigators(List<Investigator> investigators);
  Future<void> clearAll();
}

class HiveInvestigatorRepository implements InvestigatorRepository {
  static const String boxName = 'investigators_box';

  Future<Box<Investigator>> _getBox() async {
    return await Hive.openBox<Investigator>(boxName);
  }

  @override
  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }

  final List<Investigator> _mockInvestigators = [
    Investigator(
      id: 'P124956325',
      name: 'Alexander Pierce',
      location: 'Chicago, IL',
      imageUrl: 'https://i.pravatar.cc/150?img=1',
      status: InvestigatorStatus.online,
    ),
    Investigator(
      id: 'P124956388',
      name: 'Sarah Jenkins',
      location: 'New York, NY',
      imageUrl: 'https://i.pravatar.cc/150?img=5',
      status: InvestigatorStatus.offline,
    ),
    Investigator(
      id: 'P124956402',
      name: 'Marcus Thorne',
      location: 'Austin, TX',
      imageUrl: 'https://i.pravatar.cc/150?img=8',
      status: InvestigatorStatus.online,
    ),
  ];

  @override
  Future<List<Investigator>> getInvestigators() async {
    final box = await _getBox();
    if (box.isEmpty) {
      await box.addAll(_mockInvestigators);
    }
    return box.values.toList();
  }

  @override
  Future<void> saveInvestigators(List<Investigator> investigators) async {
    final box = await _getBox();
    await box.clear();
    await box.addAll(investigators);
  }
}
