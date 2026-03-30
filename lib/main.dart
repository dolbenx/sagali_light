import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/dashboard/dashboard_screen.dart'; // Ensure this path is correct
import 'services/wallet_service.dart';
import 'services/ldk_service.dart';

import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterBreezLiquid.init();

  final walletService = WalletService();
  final ldkService = LdkService();

  // 1. Check if a wallet exists and initialize BDK
  bool isLoggedIn = await walletService.tryAutoLogin();

  if (isLoggedIn) {
    try {
      // 2. Fetch the phrase from our new method
      final mnemonicString = await walletService.getMnemonic();
      
      if (mnemonicString != null) {
        // 3. Initialize LDK using the same seed
        await ldkService.initWallet(mnemonic: mnemonicString);
        debugPrint("LDK Node started successfully using BDK seed!");
      }
    } catch (e, stack) {
      debugPrint("Failed to start LDK: $e");
      debugPrint(stack.toString());
    }
  }

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