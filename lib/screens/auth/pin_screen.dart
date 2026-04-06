import 'dart:async';
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

  int _failedAttempts = 0;
  DateTime? _lockoutEndTime;
  Timer? _lockoutTimer;

  @override
  void initState() {
    super.initState();
    _checkLockoutStatus().then((_) {
      if (_lockoutEndTime == null || DateTime.now().isAfter(_lockoutEndTime!)) {
        _checkBiometrics(); // Auto-prompt biometrics on load
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkLockoutStatus() async {
    String? attemptsStr = await _storage.read(key: 'failed_pin_attempts');
    String? lockoutTimeStr = await _storage.read(key: 'pin_lockout_time');

    if (attemptsStr != null) {
      _failedAttempts = int.tryParse(attemptsStr) ?? 0;
    }
    if (lockoutTimeStr != null) {
      _lockoutEndTime = DateTime.tryParse(lockoutTimeStr);
      if (_lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!)) {
        _startLockoutTimer();
      } else {
        await _storage.delete(key: 'pin_lockout_time');
        setState(() {
          _lockoutEndTime = null;
        });
      }
    }
  }

  void _startLockoutTimer() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_lockoutEndTime == null || DateTime.now().isAfter(_lockoutEndTime!)) {
        timer.cancel();
        _storage.delete(key: 'pin_lockout_time');
        if (mounted) {
          setState(() {
            _lockoutEndTime = null;
          });
        }
      } else {
        if (mounted) setState(() {}); // Trigger rebuild for timer display
      }
    });
  }

  Future<void> _checkBiometrics() async {
    if (_lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!)) return;
    try {
      bool canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (canAuthenticate) {
        bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Unlock your Sagali Wallet',
          options: const AuthenticationOptions(stickyAuth: true, biometricOnly: false),
        );
        if (didAuthenticate) {
          await _storage.delete(key: 'failed_pin_attempts');
          _navigateToDashboard();
        }
      }
    } catch (e) {
      debugPrint("Biometric error: $e");
    }
  }

  void _onNumberPress(String number) {
    if (_lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!)) return;

    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += number);
      if (_enteredPin.length == 4) _verifyPin();
    }
  }

  Duration _getLockoutDuration(int attempts) {
    if (attempts == 3) return const Duration(minutes: 1);
    if (attempts == 4) return const Duration(minutes: 5);
    if (attempts == 5) return const Duration(minutes: 10);
    if (attempts == 6) return const Duration(minutes: 20);
    if (attempts == 7) return const Duration(minutes: 40);
    if (attempts >= 8) return const Duration(minutes: 60);
    return Duration.zero;
  }

  void _verifyPin() async {
    if (_lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!)) {
      setState(() => _enteredPin = "");
      return;
    }

    String? storedPin = await _storage.read(key: _correctPinKey);
    // Note: On first run/setup, you'd save the PIN. For now, we assume '1234' for testing.
    if (_enteredPin == (storedPin ?? "1234")) {
      await _storage.delete(key: 'failed_pin_attempts');
      await _storage.delete(key: 'pin_lockout_time');
      _navigateToDashboard();
    } else {
      _failedAttempts++;
      await _storage.write(key: 'failed_pin_attempts', value: _failedAttempts.toString());
      setState(() => _enteredPin = "");

      if (_failedAttempts >= 3) {
        final duration = _getLockoutDuration(_failedAttempts);
        _lockoutEndTime = DateTime.now().add(duration);
        await _storage.write(key: 'pin_lockout_time', value: _lockoutEndTime!.toIso8601String());
        _startLockoutTimer();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Account locked for ${duration.inMinutes} minute(s) due to failed attempts."), backgroundColor: Colors.red),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Incorrect PIN. ${3 - _failedAttempts} attempts left."), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  void _navigateToDashboard() {
    Navigator.pushReplacementNamed(context, '/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Enter PIN", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          if (_lockoutEndTime != null && DateTime.now().isBefore(_lockoutEndTime!))
            Text(
              "Locked for ${(_lockoutEndTime!.difference(DateTime.now()).inMinutes).toString().padLeft(2, '0')}:${(_lockoutEndTime!.difference(DateTime.now()).inSeconds % 60).toString().padLeft(2, '0')}",
              style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)
            )
          else if (_failedAttempts >= 3)
            Text("Next failure will lock for ${_getLockoutDuration(_failedAttempts + 1).inMinutes} min", style: const TextStyle(color: Colors.orangeAccent, fontSize: 16))
          else if (_failedAttempts > 0)
            Text("${3 - _failedAttempts} attempts remaining", style: const TextStyle(color: Colors.orangeAccent, fontSize: 16)),
          const SizedBox(height: 10),
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