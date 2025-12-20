import 'package:flutter/material.dart';
import '../dashboard/dashboard_screen.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text("Withdrawal Successful", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Your funds are on the way!", style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 50),
            TextButton(
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen())), // Goes back to Dashboard via pop
              child: const Text("BACK TO HOME", style: TextStyle(color: Color(0xFFBE8345))),
              
            )
          ],
        ),
      ),
    );
  }
}