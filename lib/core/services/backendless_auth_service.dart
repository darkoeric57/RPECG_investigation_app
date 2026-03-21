import 'dart:io';
import 'package:backendless_sdk/backendless_sdk.dart';

class BackendlessAuthService {
  static final BackendlessAuthService _instance = BackendlessAuthService._internal();
  factory BackendlessAuthService() => _instance;
  BackendlessAuthService._internal();

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
        await logout();
      } catch (_) {
        // Ignore logout errors if no session existed
      }
      
      return await Backendless.userService.login(email, password, true);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await Backendless.userService.logout();
    } catch (e) {
      rethrow;
    }
  }

  Future<BackendlessUser?> getCurrentUser() async {
    try {
      return await Backendless.userService.getCurrentUser();
    } catch (e) {
      return null;
    }
  }

  Future<bool> isValidLogin() async {
    try {
      return await Backendless.userService.isValidLogin() ?? false;
    } catch (e) {
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
