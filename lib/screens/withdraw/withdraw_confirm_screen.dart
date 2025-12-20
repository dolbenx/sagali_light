import 'package:flutter/material.dart';
import 'success_screen.dart';

class WithdrawConfirmScreen extends StatelessWidget {
  final String network;
  final String mobile;
  final double amountZMW;

  const WithdrawConfirmScreen({super.key, required this.network, required this.mobile, required this.amountZMW});

  @override
  Widget build(BuildContext context) {
    double fee = amountZMW * 0.01; // 1% fee example
    double total = amountZMW + fee;
    double btcValue = amountZMW / 1200000; // Dummy conversion rate

    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      body: Stack(
        children: [
          Positioned.fill(child: Opacity(opacity: 0.4, child: Image.asset('assets/images/bg_pattern.png', fit: BoxFit.cover))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text("Confirm Transfer", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 40),
                  _confirmRow("Network", network),
                  _confirmRow("Recipient", mobile),
                  _confirmRow("Amount", "${amountZMW.toStringAsFixed(2)} ZMW"),
                  _confirmRow("BTC Equivalent", "${btcValue.toStringAsFixed(8)} BTC"),
                  _confirmRow("Fee", "${fee.toStringAsFixed(2)} ZMW", isRed: true),
                  const Divider(color: Colors.white10, height: 40),
                  _confirmRow("Total to Deduct", "${total.toStringAsFixed(2)} ZMW", isGold: true),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      onPressed: () => _showSuccess(context),
                      child: const Text("PROCESS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value, {bool isRed = false, bool isGold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          Text(value, style: TextStyle(color: isRed ? Colors.red : (isGold ? const Color(0xFFBE8345) : Colors.white), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (_) => const SuccessScreen()), 
      (route) => false // Clear stack so they can't go "back" to the payment
    );
  }
}