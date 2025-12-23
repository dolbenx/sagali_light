import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/dashboard/dashboard_screen.dart'; // Ensure this path is correct
import 'services/wallet_service.dart';

void main() async {
  // Required for async calls before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Try to auto-login if a mnemonic is already saved
  final walletService = WalletService();
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
      home: isLoggedIn ? const DashboardScreen() : const SplashScreen(),
    );
  }
}