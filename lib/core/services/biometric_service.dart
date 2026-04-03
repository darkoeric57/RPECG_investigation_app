import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricService {
  // Only instantiate LocalAuthentication on non-web platforms.
  // On web, local_auth has no implementation and throws MissingPluginException.
  LocalAuthentication? get _auth => kIsWeb ? null : LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) return false;
    try {
      final auth = _auth!;
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();
      return canCheckBiometrics || isDeviceSupported;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return <BiometricType>[];
    try {
      return await _auth!.getAvailableBiometrics();
    } on PlatformException {
      return <BiometricType>[];
    } catch (_) {
      return <BiometricType>[];
    }
  }

  Future<bool> authenticate({required String reason}) async {
    if (kIsWeb) return false;
    try {
      return await _auth!.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[
          AndroidAuthMessages(
            signInTitle: 'Biometric login required',
            deviceCredentialsRequiredTitle: 'Biometric login required',
          ),
          IOSAuthMessages(
            cancelButton: 'No thanks',
          ),
        ],
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      if (e.code == 'NotAvailable') {
        // Handle no biometrics enrolled
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
