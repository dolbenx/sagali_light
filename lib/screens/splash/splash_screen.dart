import 'dart:async';
import 'package:flutter/material.dart';
import '../../main.dart'; // for primaryColor
import '../dashboard/dashboard_screen.dart'; // or your DashboardScreen

const Color primaryColor = Color(0xFF055C7A);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to dashboard after 3.5 seconds
    Timer(const Duration(milliseconds: 4000), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset(
          'assets/images/logo-2.png', // Ensure this file exists
          width: 150,
        ),
      ),
    );
  }
}