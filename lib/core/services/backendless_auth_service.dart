import 'dart:io';
import 'package:backendless_sdk/backendless_sdk.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class BackendlessAuthService {
  static final BackendlessAuthService _instance = BackendlessAuthService._internal();
  factory BackendlessAuthService() => _instance;
  BackendlessAuthService._internal();

  Future<File> get _authFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/auth_secure_v2.json');
  }

  Future<Map<String, dynamic>> _loadData() async {
    try {
      final file = await _authFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        return jsonDecode(content);
      }
    } catch (e) {
      print('AUTH_STORAGE_ERROR: $e');
    }
    return {};
  }

  Future<void> _saveData(Map<String, dynamic> data) async {
    try {
      final file = await _authFile;
      await file.writeAsString(jsonEncode(data), flush: true);
    } catch (e) {
      print('AUTH_STORAGE_ERROR: $e');
    }
  }

  static const String _offlineEmailKey = 'offline_email';
  static const String _offlinePasswordKey = 'offline_password';
  static const String _offlineUserPropsKey = 'offline_user_props';
  static const String _sessionActiveKey = 'session_active';
  static const String _biometricEnabledKey = 'biometric_enabled';

  Future<void> _saveOfflineCredentials(String email, String password, BackendlessUser user) async {
    final data = await _loadData();
    data[_offlineEmailKey] = email;
    data[_offlinePasswordKey] = password;
    data[_sessionActiveKey] = 'true'; // Re-activate session on successful login
    
    final propsString = jsonEncode(user.properties, toEncodable: (nonEncodable) {
      if (nonEncodable is DateTime) return nonEncodable.toIso8601String();
      return nonEncodable.toString();
    });
    data[_offlineUserPropsKey] = propsString;
    
    await _saveData(data);
    print('BACKENDLESS_AUTH: Saved credentials to file for $email (Session Active: true)');
  }

  Future<void> _clearOfflineCredentials() async {
    final file = await _authFile;
    if (await file.exists()) await file.delete();
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
    print('BACKENDLESS_AUTH: isBiometricEnabled read: $val');
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
      final user = await login(email.toString(), password.toString());
      if (user != null) {
        final data = await _loadData();
        data[_sessionActiveKey] = 'true';
        await _saveData(data);
        return user;
      }
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
    try {
      final user = BackendlessUser()
        ..email = email
        ..password = password
        ..putProperties({
          'name': name,
          'staffId': staffId,
          'region': region,
          'accountType': accountType,
          'groupNo': groupNo,
          'phone': phone,
        });

      return await Backendless.userService.register(user);
    } catch (e) {
      rethrow;
    }
  }

  Future<BackendlessUser?> login(String email, String password) async {
    try {
      // Try to logout first to clear any local tokens/stale sessions
      try {
        await Backendless.userService.logout(); // Use backendless logout directly
      } catch (_) {}
      
      final user = await Backendless.userService.login(email, password, true);
      if (user != null) {
        await _saveOfflineCredentials(email, password, user);
      }
      return user;
    } catch (e) {
      final errorStr = e.toString();
      if (e is SocketException || errorStr.contains('Failed host lookup') || errorStr.contains('connection') || errorStr.contains('Unable to resolve host') || errorStr.contains('UnknownHostException')) {
        // Try offline login
        final data = await _loadData();
        final savedEmail = data[_offlineEmailKey];
        final savedPassword = data[_offlinePasswordKey];
        if (savedEmail != null && savedEmail.toString().toLowerCase() == email.toLowerCase() && savedPassword == password) {
          return await getOfflineUser();
        } else {
           throw Exception('Invalid offline credentials. Saved email: \'$savedEmail\', Input Email: \'$email\'. Please login online first.');
        }
      }
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      final data = await _loadData();
      data[_sessionActiveKey] = 'false';
      await _saveData(data);

      await Backendless.userService.logout();
    } catch (e) {
      if (e is! SocketException && !e.toString().contains('Failed host lookup') && !e.toString().contains('connection')) {
        rethrow;
      }
    }
  }

  /// Use this if you want to completely forget the user on this device
  Future<void> clearAccountData() async {
    await _clearOfflineCredentials();
  }

  Future<BackendlessUser?> getCurrentUser() async {
    try {
      var user = await Backendless.userService.getCurrentUser();
      if (user != null) return user;
    } catch (e) {
      if (e is SocketException || e.toString().contains('Failed host lookup') || e.toString().contains('connection')) {
        return await getOfflineUser();
      }
    }
    return await getOfflineUser();
  }

  Future<bool> isValidLogin() async {
    final data = await _loadData();
    final sessionActive = data[_sessionActiveKey] == 'true';
    
    if (!sessionActive) return false;

    try {
      final res = await Backendless.userService.isValidLogin() ?? false;
      if (res) return true;
      
      // If Backendless says NO but we have local creds AND session was active, stay logged in
      return await hasOfflineCredentials();
    } catch (e) {
      if (e is SocketException || e.toString().contains('Failed host lookup') || e.toString().contains('connection') || e.toString().contains('UnknownHostException')) {
         // If offline, trust the local credentials and the last known session state
         return await hasOfflineCredentials();
      }
      return false;
    }
  }

  Future<BackendlessUser?> updateProfilePicture(String localPath) async {
    try {
      final user = await getCurrentUser();
      if (user == null) return null;

      // Upload file

      final fileUrl = await Backendless.files.upload(
        File(localPath),
        '/profile_pics',
        // Backendless SDK for Flutter uses separate positional arguments or doesn't have fileName named parameter in some versions.
        // Checking the latest SDK, it's: upload(File file, String path, {bool overwrite})
        overwrite: true,
      );

      if (fileUrl != null) {
        user.putProperties({'user-pic': fileUrl});
        return await Backendless.userService.update(user);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }
}
