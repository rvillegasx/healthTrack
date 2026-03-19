import 'package:local_auth/local_auth.dart';

class AuthService {
  final _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock HealthTrack',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allows passcode fallback
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
