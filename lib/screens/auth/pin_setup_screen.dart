import 'package:flutter/material.dart';
import '../../services/wallet_service.dart';
import '../dashboard/dashboard_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _firstPin = "";
  String _confirmPin = "";
  bool _isConfirming = false;

  void _handlePress(String char) {
    setState(() {
      if (!_isConfirming) {
        if (_firstPin.length < 4) _firstPin += char;
        if (_firstPin.length == 4) _isConfirming = true;
      } else {
        if (_confirmPin.length < 4) _confirmPin += char;
        if (_confirmPin.length == 4) _finalizePin();
      }
    });
  }

  void _finalizePin() async {
    if (_firstPin == _confirmPin) {
      await WalletService().setPin(_confirmPin);
      if (!mounted) return;
      
      // Move to Dashboard once secured
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } else {
      // Reset if they don't match
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("PINs do not match. Try again.")),
      );
      setState(() {
        _firstPin = "";
        _confirmPin = "";
        _isConfirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentDisplay = _isConfirming ? _confirmPin : _firstPin;

    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            Text(
              _isConfirming ? "Confirm your PIN" : "Create a 4-Digit PIN",
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("This adds an extra layer of security.", style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 40),
            
            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                width: 18, height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < currentDisplay.length ? const Color(0xFFBE8345) : Colors.white10,
                  border: Border.all(color: Colors.white24),
                ),
              )),
            ),
            
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        for (var row in [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]])
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: row.map((n) => _keyButton(n)).toList(),
          ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80), // Empty space
            _keyButton("0"),
            IconButton(
              icon: const Icon(Icons.backspace_outlined, color: Colors.white),
              onPressed: () {
                setState(() {
                  if (_isConfirming && _confirmPin.isNotEmpty) {
                    _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
                  } else if (!_isConfirming && _firstPin.isNotEmpty) {
                    _firstPin = _firstPin.substring(0, _firstPin.length - 1);
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _keyButton(String label) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(50),
        onTap: () => _handlePress(label),
        child: Container(
          width: 80, height: 80,
          alignment: Alignment.center,
          child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 28)),
        ),
      ),
    );
  }
}
