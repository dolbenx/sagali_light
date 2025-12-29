import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _storage = const FlutterSecureStorage();
  String _inputPin = "";
  String _oldPin = "";
  String _newPin = "";
  
  // Steps: 0 = Verify Old, 1 = Enter New, 2 = Confirm New
  int _currentStep = 0;
  String _message = "Enter your current PIN";

  void _onNumberPress(String number) {
    if (_inputPin.length < 4) {
      setState(() {
        _inputPin += number;
      });
    }

    if (_inputPin.length == 4) {
      _processStep();
    }
  }

  Future<void> _processStep() async {
    if (_currentStep == 0) {
      // Step 0: Verify Old PIN
      String? savedPin = await _storage.read(key: 'user_pin');
      if (_inputPin == savedPin) {
        setState(() {
          _oldPin = _inputPin;
          _inputPin = "";
          _currentStep = 1;
          _message = "Enter your new PIN";
        });
      } else {
        _handleError("Incorrect current PIN");
      }
    } else if (_currentStep == 1) {
      // Step 1: Store New PIN temporary
      setState(() {
        _newPin = _inputPin;
        _inputPin = "";
        _currentStep = 2;
        _message = "Confirm your new PIN";
      });
    } else if (_currentStep == 2) {
      // Step 2: Final Confirmation
      if (_inputPin == _newPin) {
        await _storage.write(key: 'user_pin', value: _newPin);
        _showSuccess();
      } else {
        _handleError("PINs do not match. Try again.");
        setState(() {
          _currentStep = 1;
          _message = "Enter your new PIN";
        });
      }
    }
  }

  void _handleError(String err) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err), backgroundColor: Colors.redAccent),
    );
    setState(() => _inputPin = "");
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E1A2B),
        title: const Text("Success", style: TextStyle(color: Colors.white)),
        content: const Text("Your PIN has been updated successfully.", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("DONE", style: TextStyle(color: Color(0xFFBE8345))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: Colors.white),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_message, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (index) => Container(
              margin: const EdgeInsets.all(8),
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index < _inputPin.length ? const Color(0xFFBE8345) : Colors.white24,
              ),
            )),
          ),
          const SizedBox(height: 50),
          _buildNumPad(),
        ],
      ),
    );
  }

  Widget _buildNumPad() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 3,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      children: [
        ...['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'].map((val) {
          if (val == '') return const SizedBox();
          return IconButton(
            onPressed: () {
              if (val == '⌫') {
                if (_inputPin.isNotEmpty) setState(() => _inputPin = _inputPin.substring(0, _inputPin.length - 1));
              } else {
                _onNumberPress(val);
              }
            },
            icon: Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          );
        }),
      ],
    );
  }
}