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

  // ─── Real-Time Chat ──────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _db.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['uid'] = doc.id;
        return data;
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getMessagesStream(String chatId) {
    return _db
        .collection('Chats')
        .doc(chatId)
        .collection('Messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> saveMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
    String type = 'text',
    String? filename,
    String? fileSize,
    String? status,
    int? voiceDuration,
    Map<String, dynamic>? extraData,
  }) async {
    try {
      final messageData = {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'type': type,
        if (filename != null) 'filename': filename,
        if (fileSize != null) 'fileSize': fileSize,
        if (status != null) 'status': status,
        if (voiceDuration != null) 'voiceDuration': voiceDuration,
        if (extraData != null) ...extraData,
      };

      final members = chatId.split('_');

      final chatData = {
        'members': members,
        'lastMessage': type == 'text' ? text : '[$type]',
        'lastMessageTime': FieldValue.serverTimestamp(),
      };

      final batch = _db.batch();
      final chatRef = _db.collection('Chats').doc(chatId);
      final messageRef = chatRef.collection('Messages').doc();

      batch.set(chatRef, chatData, SetOptions(merge: true));
      batch.set(messageRef, messageData);
      await batch.commit();
    } catch (e) {
      print('DEBUG: Firestore error saving message: $e');
      rethrow;
    }
  }

  Future<void> seedMockUsers(String currentUserUid) async {
    try {
      final querySnapshot = await _db.collection('Users').get();
      if (querySnapshot.docs.length <= 1) {
        final batch = _db.batch();
        final mockUsers = [
          {
            'name': 'Sarah Jenkins',
            'staffId': 'SU-204',
            'email': 'sarah@gmail.com',
            'region': 'Eastern',
            'accountType': 'Technical',
            'gender': 'Female',
            'createdAt': FieldValue.serverTimestamp(),
            'photoUrl': 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=100',
          },
          {
            'name': 'Marcus Chen',
            'staffId': 'SU-115',
            'email': 'marcus@gmail.com',
            'region': 'Northern',
            'accountType': 'Admin',
            'gender': 'Male',
            'createdAt': FieldValue.serverTimestamp(),
            'photoUrl': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=100',
          },
          {
            'name': 'Elena Rodriguez',
            'staffId': 'SU-308',
            'email': 'elena@gmail.com',
            'region': 'Greater Accra',
            'accountType': 'Technical',
            'gender': 'Female',
            'createdAt': FieldValue.serverTimestamp(),
            'photoUrl': 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?q=80&w=100',
          },
        ];

        for (var u in mockUsers) {
          final deterministicId = 'mock_${u['staffId']}';
          final docRef = _db.collection('Users').doc(deterministicId);
          batch.set(docRef, u);
        }

        await batch.commit();
        print('DEBUG: Successfully seeded mock users in Firestore.');
      }
    } catch (e) {
      print('DEBUG: Firestore error seeding mock users: $e');
    }
  }
}

