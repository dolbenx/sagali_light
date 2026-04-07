import 'package:flutter/material.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/main/main_screen.dart';
import 'screens/auth/pin_screen.dart';
import 'services/wallet_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the flutter_rust_bridge wrapper for Breez Spark SDK
  await BreezSdkSparkLib.init();

  final walletService = WalletService();

  // Check if a wallet exists and initialize Breez Spark
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
      home: isLoggedIn ? const PinScreen() : const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/dashboard': (context) => const MainScreen(),
        '/pin': (context) => const PinScreen(),
      },
    );
  }
}