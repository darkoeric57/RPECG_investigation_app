import 'package:backendless_sdk/backendless_sdk.dart';
import '../../features/meters/domain/meter.dart';
import '../../features/dashboard/domain/investigator.dart';

class BackendlessDataService {
  static final BackendlessDataService _instance = BackendlessDataService._internal();
  factory BackendlessDataService() => _instance;
  BackendlessDataService._internal();

  static const String metersTable = 'Meters';
  static const String investigatorsTable = 'Investigators';

  Future<void> deleteMeter(String objectId) async {
    try {
      if (objectId.isEmpty) return;
      await Backendless.data.of(metersTable).remove(entity: {'objectId': objectId});
    } catch (e) {
      print('DEBUG: Backendless error deleting Meter $objectId: $e');
      rethrow;
    }
  }

  Future<void> saveMeter(Meter meter) async {
    try {
      final Map<String, dynamic> data = {
        'meterId': meter.id,
        'customerName': meter.customerName,
        'address': meter.address,
        'telephone': meter.telephone,
        'tariffClass': meter.tariffClass,
        'gpsCoordinates': meter.gpsCoordinates,
        'tariffActivity': meter.tariffActivity.name,
        'geocode': meter.geocode,
        'spnNumber': meter.spnNumber,
        'brand': meter.brand,
        'rating': meter.rating,
        'phase': meter.phase.name,
        'type': meter.type.name,
        'status': meter.status.name,
        'installationDate': meter.installationDate.millisecondsSinceEpoch,
        'initialReadings': meter.initialReadings,
        'capturedImagePaths': meter.capturedImagePaths,
        'capturedVideoPath': meter.capturedVideoPath,
        'debtAmount': meter.debtAmount,
        'paidAmount': meter.paidAmount,
        'offenseType': meter.offenseType,
        'dateApprehended': meter.dateApprehended?.millisecondsSinceEpoch,
        'findings': meter.findings,
        if (meter.installments != null) 'installments': meter.installments!.map((i) => i.toMap()).toList(),
      };

      if (meter.objectId != null) {
        data['objectId'] = meter.objectId;
      }

      await Backendless.data.of(metersTable).save(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Meter>> getRemoteMeters() async {
    try {
      final queryBuilder = DataQueryBuilder()
        ..pageSize = 100
        ..sortBy = ['installationDate DESC'];
        
      final response = await Backendless.data.of(metersTable).find(queryBuilder);
      return (response as List).map((m) => Meter.fromMap(Map<String, dynamic>.from(m as Map))).toList();
    } catch (e) {
      print('DEBUG: Backendless error fetching Meters: $e');
      return [];
    }
  }

  Future<List<Investigator>> getInvestigators() async {
    try {
      final result = await Backendless.data.of(investigatorsTable).find();
      return result.map((i) => Investigator.fromMap(i)).toList();
    } catch (e) {
      print('DEBUG: Backendless error fetching Investigators: $e');
      return [];
    }
  }
}
