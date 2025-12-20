import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';

class PinScreen extends StatefulWidget {
  const PinScreen({super.key});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _currentPin = "";
  final int _pinLength = 4;

  void _handleKeyPress(String value) {
    if (_currentPin.length < _pinLength) {
      setState(() {
        _currentPin += value;
      });
      
      // Auto-unlock when 4 digits are reached
      if (_currentPin.length == _pinLength) {
        Future.delayed(const Duration(milliseconds: 200), () => _unlock());
      }
    }
  }

  void _handleDelete() {
    if (_currentPin.isNotEmpty) {
      setState(() {
        _currentPin = _currentPin.substring(0, _currentPin.length - 1);
      });
    }
  }

  void _unlock() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      body: Stack(
        children: [
          /// 1. BACKGROUND
          Positioned.fill(
            child: Opacity(
              opacity: 0.02,
              child: Image.asset('assets/images/bg_pattern.png', fit: BoxFit.cover),
            ),
          ),

          /// 2. CONTENT
          SafeArea(
            child: Column(
              children: [
                const Spacer(),
                // Image.asset('assets/images/logo.png', width: 70),
                const SizedBox(height: 30),
                const Text(
                  "Enter PIN",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                /// PIN INDICATORS (Circles)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (index) {
                    bool isFilled = _currentPin.length > index;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? const Color(0xFFBE8345) : Colors.transparent,
                        border: Border.all(
                          color: isFilled ? const Color(0xFFBE8345) : Colors.white24,
                          width: 2,
                        ),
                      ),
                    );
                  }),
                ),

                const Spacer(),

                /// NUMERIC KEYPAD
                _buildKeypad(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3']),
        _buildKeypadRow(['4', '5', '6']),
        _buildKeypadRow(['7', '8', '9']),
        _buildKeypadRow([null, '0', 'delete']),
      ],
    );
  }

  Widget _buildKeypadRow(List<String?> labels) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: labels.map((label) {
          if (label == null) return const SizedBox(width: 70);
          
          return InkWell(
            onTap: () => label == 'delete' ? _handleDelete() : _handleKeyPress(label),
            borderRadius: BorderRadius.circular(40),
            child: Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
              child: Center(
                child: label == 'delete'
                    ? const Icon(Icons.backspace_outlined, color: Colors.white70)
                    : Text(
                        label,
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w400),
                      ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}