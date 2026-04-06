import 'package:flutter/material.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/dashboard/dashboard_screen.dart'; // Ensure this path is correct
import 'screens/auth/pin_screen.dart';
import 'services/wallet_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the flutter_rust_bridge wrapper for Breez Liquid
  await FlutterBreezLiquid.init();

  final walletService = WalletService();

  // 1. Check if a wallet exists and initialize Breez Liquid
  bool isLoggedIn = await walletService.tryAutoLogin();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sagali Wallet',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF055C7A),
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFF0E1A2B),
      ),
      // If logged in, skip splash/welcome and go to Dashboard
      home: isLoggedIn ? const PinScreen() : const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/pin': (context) => const PinScreen(),
      },
    );
  }
}