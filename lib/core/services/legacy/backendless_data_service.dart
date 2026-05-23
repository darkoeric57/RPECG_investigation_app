// This is a legacy stub — the app has migrated to Firebase/Firestore.
// The Backendless SDK is no longer a dependency; these methods return empty
// results so that references in backoffice_providers.dart still compile.
import '../../../features/meters/domain/meter.dart';
import '../../../features/dashboard/domain/investigator.dart';

class BackendlessDataService {
  static final BackendlessDataService _instance =
      BackendlessDataService._internal();
  factory BackendlessDataService() => _instance;
  BackendlessDataService._internal();

  Future<void> deleteMeter(String objectId) async {
    // No-op: data is now managed via Firestore.
  }

  Future<void> saveMeter(Meter meter) async {
    // No-op: data is now managed via Firestore.
  }

  Future<List<Meter>> getRemoteMeters() async {
    // Returns empty list — Firestore-backed provider supersedes this.
    return [];
  }

  Future<List<Investigator>> getInvestigators() async {
    // Returns empty list — Firestore-backed provider supersedes this.
    return [];
  }
}
