import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class FirebaseAuthService {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signUp({
    required String email,
    required String password,
    required String name,
    required String staffId,
    required String region,
    required String accountType,
    String? groupNo,
    String? phone,
    String? gender,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (credential.user != null) {
        // Store additional user profile data in Firestore
        await _db.collection('Users').doc(credential.user!.uid).set({
          'email': email,
          'name': name,
          'staffId': staffId,
          'region': region,
          'accountType': accountType,
          'groupNo': groupNo,
          'phone': phone,
          'gender': gender ?? 'Male',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        await credential.user!.updateDisplayName(name);
      }
      return credential.user;
    } catch (e) {
      debugPrint('FIREBASE_AUTH: SignUp error: $e');
      rethrow;
    }
  }

  Future<User?> login(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      debugPrint('FIREBASE_AUTH: Login error: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('FIREBASE_AUTH: Logout error: $e');
    }
  }

  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  Future<bool> isValidLogin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      return _auth.currentUser != null;
    } catch (e) {
      return false;
    }
  }

  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }
  
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('Users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('FIREBASE_AUTH: Error fetching profile: $e');
      return null;
    }
  }
  
  // Biometric / Offline login stubs (for mobile functionality)
  Future<bool> hasOfflineCredentials() async => false;
  Future<bool> isBiometricEnabled() async => false;
  Future<void> setBiometricEnabled(bool enabled) async {}
  Future<User?> updateProfilePicture(String url) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.updatePhotoURL(url);
        await _db.collection('Users').doc(user.uid).update({
          'photoUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await user.reload();
        return _auth.currentUser;
      }
      return null;
    } catch (e) {
      debugPrint('FIREBASE_AUTH: Update profile picture error: $e');
      rethrow;
    }
  }

  Future<User?> loginWithBiometrics() async => null;
}
