import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  // 1. Check if the device hardware supports biometrics
  Future<bool> isDeviceSupported() async {
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();
    return canAuthenticate;
  }

  // 2. Perform the actual authentication
  Future<bool> authenticate() async {
    try {
      return await auth.authenticate(
        localizedReason: 'Please authenticate to access your wallet',
        options: const AuthenticationOptions(
          stickyAuth: true, // Keeps auth alive if app goes to background
          biometricOnly: true, // Prevents falling back to PIN/Passcode
        ),
      );
    } on PlatformException catch (e) {
      print("Biometric Error: $e");
      return false;
    }
  }
}