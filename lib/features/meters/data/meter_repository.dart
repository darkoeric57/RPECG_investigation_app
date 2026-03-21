import 'package:hive/hive.dart';
import '../domain/meter.dart';
import '../../../core/services/backendless_data_service.dart';

abstract class MeterRepository {
  Future<List<Meter>> getMeters();
  Future<Meter?> getMeterById(String id);
  Future<void> addMeter(Meter meter);
  Future<List<Meter>> searchMeters(String query);
  Future<void> syncMeters();
  Future<void> pullMeters();
  Future<String> generateCsvReport();
  Future<void> clearAll();
}

class HiveMeterRepository implements MeterRepository {
  static const String boxName = 'meters_box';

  Future<Box<Meter>> _getBox() async {
    return await Hive.openBox<Meter>(boxName);
  }

  final List<Meter> _mockMeters = [
    Meter(
      id: 'MET-44295-X',
      customerName: 'Benjamin Anderson',
      address: 'Victoria Island, Lagos',
      telephone: '+234 801 123 4567',
      tariffClass: 'E02',
      gpsCoordinates: '6.4281, 3.4215',
      tariffActivity: TariffActivity.residential,
      geocode: 'GEO-001',
      spnNumber: 'SPN-991',
      brand: 'EDMI',
      rating: '100A',
      phase: MeterPhase.single,
      type: MeteringType.prepaid,
      status: MeterStatus.active,
      installationDate: DateTime.now().subtract(const Duration(days: 2)),
      isSynced: true,
    ),
    Meter(
      id: 'MET-44301-A',
      customerName: 'Catherine Phillips',
      address: 'Ikoyi, Lagos',
      telephone: '+234 802 234 5678',
      tariffClass: 'E01',
      gpsCoordinates: '6.4549, 3.4246',
      tariffActivity: TariffActivity.commercial,
      geocode: 'GEO-002',
      spnNumber: 'SPN-992',
      brand: 'MOJEC',
      rating: '200A',
      phase: MeterPhase.three,
      type: MeteringType.postpaid,
      status: MeterStatus.pending,
      installationDate: DateTime.now().subtract(const Duration(days: 5)),
      isSynced: true,
    ),
  ];

  @override
  Future<List<Meter>> getMeters() async {
    final box = await _getBox();
    if (box.isEmpty) {
      await box.addAll(_mockMeters);
    }
    return box.values.toList();
  }

  @override
  Future<Meter?> getMeterById(String id) async {
    final box = await _getBox();
    return box.values.where((m) => m.id == id).firstOrNull;
  }

  @override
  Future<void> addMeter(Meter meter) async {
    final box = await _getBox();
    await box.add(meter);
  }

  @override
  Future<void> syncMeters() async {
    final box = await _getBox();
    final unsynced = box.values.where((m) => !m.isSynced).toList();
    final dataService = BackendlessDataService();

    for (var meter in unsynced) {
      try {
        await dataService.saveMeter(meter);
        final key = box.keys.firstWhere((k) => box.get(k)?.id == meter.id);
        await box.put(key, meter.copyWith(isSynced: true));
      } catch (e) {
        // If sync fails for one meter, continue to next but don't mark as synced
        continue;
      }
    }
  }
  
  @override
  Future<void> pullMeters() async {
    final box = await _getBox();
    final dataService = BackendlessDataService();
    
    try {
      final remoteMeters = await dataService.getRemoteMeters();
      final localIds = box.values.map((m) => m.id).toSet();
      
      for (var remote in remoteMeters) {
        if (!localIds.contains(remote.id)) {
          // If we have a local mock version with the same ID, Hive might have it. 
          // But our check covers it already.
          await box.add(remote.copyWith(isSynced: true));
        }
      }
    } catch (e) {
      // Pull failed, possibly offline
    }
  }

  @override
  Future<String> generateCsvReport() async {
    final meters = await getMeters();
    final buffer = StringBuffer();
    
    // Header
    buffer.writeln('Meter ID,Customer Name,Address,Telephone,Tariff Class,GPS,Activity,Geocode,SPN,Brand,Rating,Phase,Type,Status,Date,Synced');
    
    for (var m in meters) {
      buffer.writeln('${m.id},"${m.customerName}","${m.address}",${m.telephone},${m.tariffClass},${m.gpsCoordinates},${m.tariffActivity.name},${m.geocode},${m.spnNumber},${m.brand},${m.rating},${m.phase.name},${m.type.name},${m.status.name},${m.installationDate},${m.isSynced}');
    }
    
    return buffer.toString();
  }

  @override
  Future<List<Meter>> searchMeters(String query) async {
    final meters = await getMeters();
    if (query.isEmpty) return meters;
    return meters.where((m) => 
      m.id.toLowerCase().contains(query.toLowerCase()) || 
      m.customerName.toLowerCase().contains(query.toLowerCase())
    ).toList();
  }

  @override
  Future<void> clearAll() async {
    final box = await _getBox();
    await box.clear();
  }
}
