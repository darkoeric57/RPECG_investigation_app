import 'dart:io';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:shared_preferences/shared_preferences.dart';

class BackendlessAuthService {
  static final BackendlessAuthService _instance = BackendlessAuthService._internal();
  factory BackendlessAuthService() => _instance;
  BackendlessAuthService._internal();

  static bool useMock = false;
  static const String _mockUsersKey = 'mock_users';
  static const String _offlineEmailKey = 'offline_email';
  static const String _offlinePasswordKey = 'offline_password';
  static const String _offlineUserPropsKey = 'offline_user_props';
  static const String _sessionActiveKey = 'session_active';
  static const String _biometricEnabledKey = 'biometric_enabled';

  Future<dynamic> get _authFile async {
    if (kIsWeb) return null;
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/auth_secure_v2.json');
  }

  Future<Map<String, dynamic>> _loadData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final content = prefs.getString('auth_secure_web');
      if (content != null) {
        try {
          return jsonDecode(content);
        } catch (_) {}
      }
      return {};
    }
    try {
      final file = await _authFile;
      if (file != null && await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content);
      }
    } catch (e) {
      debugPrint('AUTH_STORAGE_ERROR: $e');
    }
    return {};
  }

  Future<void> _saveData(Map<String, dynamic> data) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_secure_web', jsonEncode(data));
      return;
    }
    try {
      final file = await _authFile;
      if (file != null) {
        await file.writeAsString(jsonEncode(data), flush: true);
      }
    } catch (e) {
      debugPrint('AUTH_STORAGE_ERROR: $e');
    }
  }

  Future<void> _saveOfflineCredentials(String email, String password, BackendlessUser user) async {
    final data = await _loadData();
    data[_offlineEmailKey] = email;
    data[_offlinePasswordKey] = password;
    data[_sessionActiveKey] = 'true';
    
    final propsString = jsonEncode(user.properties, toEncodable: (nonEncodable) {
      if (nonEncodable is DateTime) return nonEncodable.toIso8601String();
      return nonEncodable.toString();
    });
    data[_offlineUserPropsKey] = propsString;
    
    await _saveData(data);
    debugPrint('BACKENDLESS_AUTH: Saved credentials for $email (Session Active: true)');
  }


  Future<BackendlessUser?> getOfflineUser() async {
    final data = await _loadData();
    final email = data[_offlineEmailKey];
    if (email == null) return null;
    
    final propsString = data[_offlineUserPropsKey];
    final user = BackendlessUser()..email = email;
    
    if (propsString != null) {
      try {
        final Map<String, dynamic> props = jsonDecode(propsString);
        user.putProperties(props);
      } catch (_) {}
    }
    return user;
  }

  Future<bool> hasOfflineCredentials() async {
    final data = await _loadData();
    final email = data[_offlineEmailKey];
    return email != null && email.toString().isNotEmpty;
  }

  Future<bool> isBiometricEnabled() async {
    final data = await _loadData();
    final val = data[_biometricEnabledKey];
    return val == 'true';
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final data = await _loadData();
    data[_biometricEnabledKey] = enabled.toString();
    await _saveData(data);
  }

  Future<BackendlessUser?> loginWithBiometrics() async {
    final data = await _loadData();
    final email = data[_offlineEmailKey];
    final password = data[_offlinePasswordKey];
    
    if (email != null && password != null) {
      return await login(email.toString(), password.toString());
    }
    return null;
  }

  Future<BackendlessUser?> signUp({
    required String email,
    required String password,
    required String name,
    required String staffId,
    required String region,
    required String accountType,
    String? groupNo,
    String? phone,
  }) async {
    if (useMock) {
      debugPrint('BACKENDLESS_AUTH: Mock SignUp for $email');
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_mockUsersKey) ?? '[]';
      final List<dynamic> users = jsonDecode(usersJson);
      
      if (users.any((u) => u['email'] == email)) {
        throw Exception('User with this email already exists (Mock)');
      }

      final userData = {
        'email': email,
        'password': password,
        'name': name,
        'staffId': staffId,
        'region': region,
        'accountType': accountType,
        'groupNo': groupNo,
        'phone': phone,
      };
      
      users.add(userData);
      await prefs.setString(_mockUsersKey, jsonEncode(users));
      
      final user = BackendlessUser()..email = email;
      user.putProperties(userData);
      return user;
    }

    try {
      final user = BackendlessUser()
        ..email = email
        ..password = password;
      
      user.putProperties({
        'name': name,
        'staffId': staffId,
        'region': region,
        'accountType': accountType,
        if (groupNo != null) 'groupNo': groupNo,
        if (phone != null) 'phone': phone,
      });

      return await Backendless.userService.register(user);
    } catch (e) {
      if (_isBackendlessAvailabilityError(e)) {
        useMock = true;
        return signUp(
          email: email,
          password: password,
          name: name,
          staffId: staffId,
          region: region,
          accountType: accountType,
          groupNo: groupNo,
          phone: phone,
        );
      }
      rethrow;
    }
  }

  Future<BackendlessUser?> login(String email, String password) async {
    if (useMock) {
      debugPrint('BACKENDLESS_AUTH: Mock Login for $email');
      final prefs = await SharedPreferences.getInstance();
      final usersJson = prefs.getString(_mockUsersKey) ?? '[]';
      final List<dynamic> users = jsonDecode(usersJson);
      
      final userMatch = users.firstWhere(
        (u) => u['email'].toString().toLowerCase() == email.toLowerCase() && u['password'] == password,
        orElse: () => null,
      );
      
      if (userMatch != null) {
        final user = BackendlessUser()..email = email;
        user.putProperties(Map<String, dynamic>.from(userMatch));
        await _saveOfflineCredentials(email, password, user);
        return user;
      }
      throw Exception('Invalid email or password (Mock)');
    }

    try {
      try { await Backendless.userService.logout(); } catch (_) {}
      
      final user = await Backendless.userService.login(email, password, true);
      if (user != null) {
        await _saveOfflineCredentials(email, password, user);
      }
      return user;
    } catch (e) {
      if (_isBackendlessAvailabilityError(e)) {
        useMock = true;
        return login(email, password);
      }
      
      // Offline fallback
      if (!kIsWeb) {
        final data = await _loadData();
        final savedEmail = data[_offlineEmailKey];
        final savedPassword = data[_offlinePasswordKey];
        if (savedEmail?.toString().toLowerCase() == email.toLowerCase() && savedPassword == password) {
          return await getOfflineUser();
        }
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    final data = await _loadData();
    data[_sessionActiveKey] = 'false';
    await _saveData(data);
    
    if (useMock) {
      return;
    }

    try {
      await Backendless.userService.logout();
    } catch (_) {}
  }

  Future<bool> isLoggedIn() async {
    final data = await _loadData();
    final sessionActive = data[_sessionActiveKey] == 'true';
    if (!sessionActive) return false;

    if (useMock || kIsWeb) return true;

    try {
      return await Backendless.userService.isValidLogin().timeout(
        const Duration(seconds: 3),
        onTimeout: () => true, // Default to true if timeout but session was active
      ) ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> isValidLogin() => isLoggedIn();

  Future<BackendlessUser?> getCurrentUser() async {
    if (useMock) {
      return await getOfflineUser();
    }
    try {
      final user = await Backendless.userService.getCurrentUser();
      if (user != null) return user;
    } catch (_) {}
    return await getOfflineUser();
  }

  Future<BackendlessUser?> updateProfilePicture(String localPath) async {
    if (kIsWeb) return await getCurrentUser();
    try {
      final user = await getCurrentUser();
      if (user == null) return null;

      // This would normally upload to Backendless
      // Since we are mostly in mock/stub mode, we'll just return the user
      return user;
    } catch (e) {
      rethrow;
    }
  }

  bool _isBackendlessAvailabilityError(dynamic e) {
    final s = e.toString();
    return s.contains('3F60D88F-F23C-4C87-B2A8-0E78368940D3') || 
           s.contains('does not exist') || 
           s.contains('3064');
  }
}
