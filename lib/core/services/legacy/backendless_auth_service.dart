// Legacy stub — the app has migrated to Firebase Authentication.
// The Backendless SDK is no longer a dependency.
// This file is retained to avoid breaking any stale references;
// all methods are no-ops or return safe default values.
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class BackendlessAuthService {
  static final BackendlessAuthService _instance =
      BackendlessAuthService._internal();
  factory BackendlessAuthService() => _instance;
  BackendlessAuthService._internal();

  static bool useMock = false;
  static const String _sessionActiveKey = 'session_active';
  static const String _offlineEmailKey = 'offline_email';
  static const String _biometricEnabledKey = 'biometric_enabled';

  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, enabled);
  }

  Future<bool> hasOfflineCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_offlineEmailKey);
    return email != null && email.isNotEmpty;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_sessionActiveKey) ?? false;
  }

  Future<bool> isValidLogin() => isLoggedIn();

  /// Always returns null — auth is now handled by FirebaseAuthService.
  Future<dynamic> getCurrentUser() async => null;

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionActiveKey, false);
    debugPrint('BackendlessAuthService (stub): logout called — session cleared.');
  }
}
