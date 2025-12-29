import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../dashboard/dashboard_screen.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  final _storage = const FlutterSecureStorage();
  String _enteredPin = "";
  final String _correctPinKey = "user_pin"; // You should set this during setup

  @override
  void initState() {
    super.initState();
    _checkBiometrics(); // Auto-prompt biometrics on load
  }

  Future<void> _checkBiometrics() async {
    try {
      bool canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (canAuthenticate) {
        bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Unlock your Sagali Wallet',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
        );
        if (didAuthenticate) _navigateToDashboard();
      }
    } catch (e) {
      debugPrint("Biometric error: $e");
    }
  }

  void _onNumberPress(String number) {
    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += number);
      if (_enteredPin.length == 4) _verifyPin();
    }
  }

  void _verifyPin() async {
    String? storedPin = await _storage.read(key: _correctPinKey);
    // Note: On first run/setup, you'd save the PIN. For now, we assume '1234' for testing.
    if (_enteredPin == (storedPin ?? "1234")) {
      _navigateToDashboard();
    } else {
      setState(() => _enteredPin = "");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect PIN"), backgroundColor: Colors.red),
      );
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const DashboardScreen())
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Enter PIN", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          // PIN Dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) => Container(
              margin: const EdgeInsets.all(8),
              width: 16, height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _enteredPin.length ? const Color(0xFFBE8345) : Colors.white24,
              ),
            )),
          ),
          const SizedBox(height: 50),
          // Custom Number Pad
          _buildNumPad(),
        ],
      ),
    );
  }

  Widget _buildNumPad() {
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 1.5,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        if (index == 9) return IconButton(onPressed: _checkBiometrics, icon: const Icon(Icons.fingerprint, color: Colors.white, size: 32));
        if (index == 10) return _numButton("0");
        if (index == 11) return IconButton(onPressed: () => setState(() => _enteredPin = ""), icon: const Icon(Icons.backspace_outlined, color: Colors.white));
        return _numButton("${index + 1}");
      },
    );
  }

  Widget _numButton(String text) {
    return TextButton(
      onPressed: () => _onNumberPress(text),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 28)),
    );
  }
}