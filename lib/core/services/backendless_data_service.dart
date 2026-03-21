import 'package:backendless_sdk/backendless_sdk.dart';
import '../../features/meters/domain/meter.dart';

class BackendlessDataService {
  static final BackendlessDataService _instance = BackendlessDataService._internal();
  factory BackendlessDataService() => _instance;
  BackendlessDataService._internal();

  static const String metersTable = 'Meters';

  Future<void> saveMeter(Meter meter) async {
    try {
      final Map<dynamic, dynamic> data = {
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
      };

      await Backendless.data.of(metersTable).save(data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Meter>> getRemoteMeters() async {
    try {
      final result = await Backendless.data.of(metersTable).find();
      if (result == null) return [];
      return result.map((m) => Meter.fromMap(m!)).toList();
    } catch (e) {
      return [];
    }
  }
}
