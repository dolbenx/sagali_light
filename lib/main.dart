import 'screens/splash/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/wallets/wallets_screen.dart';
import 'screens/transactions/transactions_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'package:sagali_light/services/breez_service.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  // Initialize library
  const String mnemonic = 'your-24-word-mnemonic-here'; // IMPORTANT: Use a real mnemonic or generate one
  const String API_KEY = 'MIIBbzCCASGgAwIBAgIHPgc3izOVkzAFBgMrZXAwEDEOMAwGA1UEAxMFQnJlZXowHhcNMjUwNDI5MTQ0NjMyWhcNMzUwNDI3MTQ0NjMyWjApMRYwFAYDVQQKEw1TZWxmIEVtcGxveWVkMQ8wDQYDVQQDEwZEYXZpZXMwKjAFBgMrZXADIQDQg/XL3yA8HKIgyimHU/Qbpxy0tvzris1fDUtEs6ldd6OBgDB+MA4GA1UdDwEB/wQEAwIFoDAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTaOaPuXmtLDTJVv++VYBiQr9gHCTAfBgNVHSMEGDAWgBTeqtaSVvON53SSFvxMtiCyayiYazAeBgNVHREEFzAVgRNkb2xiZW44MDBAZ21haWwuY29tMAUGAytlcANBAEqOtvtp1I4Rx/QgM7uI/et7GcSxRpYJ3UIpkzAxfMes4ffL5crjmgC3KK0ScolI7kx7u4Frb85DYfE3zgw8CQY=';
  final appDocumentDir = await getApplicationDocumentsDirectory();
  final workingDir = "${appDocumentDir.path}/breez_liquid_sdk";

  try {
    // Corrected call to initBreezSDK with required parameters
    await BreezService().initBreezSDK(
      mnemonic: mnemonic,
      breezApiKey: API_KEY,
      workingDir: workingDir,
      isMainnet: false, // Set to true for mainnet, false for testnet
    );
    print("Breez Service initialized successfully!");
  } catch (e) {
    print("Error initializing Breez Service: $e");
    // Handle the error (e.g., show an error message to the user)
  }
  runApp(const MyApp());
}

const Color primaryColor = Color(0xFF055C7A);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Sagali Wallet',
        theme: ThemeData(
          primaryColor: primaryColor,
          colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
          useMaterial3: true,
        ),
        // home: const MainNavigation(),
        home: const SplashScreen(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {

}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    WalletsScreen(),
    TransactionsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
      ),
    );
  }
}
