import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/meters/domain/meter.dart';
import '../../features/dashboard/domain/investigator.dart';
import '../../features/backoffice/domain/billing_account.dart';

class FirestoreDataService {
  static final FirestoreDataService _instance = FirestoreDataService._internal();
  factory FirestoreDataService() => _instance;
  FirestoreDataService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const String metersCollection = 'Meters';
  static const String investigatorsCollection = 'Investigators';
  static const String billingCollection = 'BillingAccounts';

  Future<void> deleteMeter(String id) async {
    try {
      if (id.isEmpty) return;
      await _db.collection(metersCollection).doc(id).delete();
    } catch (e) {
      print('DEBUG: Firestore error deleting Meter $id: $e');
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
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _db.collection(metersCollection).doc(meter.id).set(data, SetOptions(merge: true));
    } catch (e) {
      print('DEBUG: Firestore error saving Meter ${meter.id}: $e');
      rethrow;
    }
  }

  Future<List<Meter>> getRemoteMeters() async {
    try {
      final querySnapshot = await _db.collection(metersCollection)
        .orderBy('installationDate', descending: true)
        .limit(100)
        .get();
        
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        // Backendless uses objectId, Firestore uses doc.id or we can stick to meterId
        return Meter.fromMap(data);
      }).toList();
    } catch (e) {
      print('DEBUG: Firestore error fetching Meters: $e');
      return [];
    }
  }

  Future<List<Investigator>> getInvestigators() async {
    try {
      final querySnapshot = await _db.collection(investigatorsCollection).get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Investigator.fromMap(data);
      }).toList();
    } catch (e) {
      print('DEBUG: Firestore error fetching Investigators: $e');
      return [];
    }
  }

  // ─── Billing Accounts ──────────────────────────────────────────────────────

  Future<void> saveBillingAccountsBatch(List<Map<String, String>> accounts) async {
    try {
      final batch = _db.batch();
      final now = DateTime.now();

      for (var accountMap in accounts) {
        final docRef = _db.collection(billingCollection).doc();
        // Add imported_at if not present
        if (!accountMap.containsKey('imported_at')) {
          accountMap['imported_at'] = now.toIso8601String();
        }
        
        final account = BillingAccount.fromMap(accountMap);
        batch.set(docRef, account.toMap());
      }

      await batch.commit();
    } catch (e) {
      print('DEBUG: Firestore error saving Billing Accounts batch: $e');
      rethrow;
    }
  }

  Future<List<BillingAccount>> getBillingAccounts() async {
    try {
      final querySnapshot = await _db.collection(billingCollection)
          .orderBy('imported_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return BillingAccount.fromMap(doc.data(), id: doc.id);
      }).toList();
    } catch (e) {
      print('DEBUG: Firestore error fetching Billing Accounts: $e');
      return [];
    }
  }

  Future<void> deleteBillingAccount(String id) async {
    try {
      await _db.collection(billingCollection).doc(id).delete();
    } catch (e) {
      print('DEBUG: Firestore error deleting Billing Account $id: $e');
      rethrow;
    }
  }

  Future<void> updateBillingAccount(BillingAccount account) async {
    try {
      if (account.id == null) throw Exception("Account ID is required for update");
      await _db.collection(billingCollection).doc(account.id!).update(account.toMap());
    } catch (e) {
      print('DEBUG: Firestore error updating Billing Account ${account.id}: $e');
      rethrow;
    }
  }

  Future<List<BillingAccount>> getBillingHistory(String accountNumber) async {
    try {
      final querySnapshot = await _db.collection(billingCollection)
          .where('account', isEqualTo: accountNumber)
          .orderBy('imported_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        return BillingAccount.fromMap(doc.data(), id: doc.id);
      }).toList();
    } catch (e) {
      print('DEBUG: Firestore error fetching history for $accountNumber: $e');
      return [];
    }
  }
}
