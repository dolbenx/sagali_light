import 'package:flutter/material.dart';
import 'dart:ui';
import '../dashboard/dashboard_screen.dart'; // Adjust path
import '../transactions/transactions_screen.dart'; // Adjust path
import '../auth/pin_screen.dart';
import '../auth/change_pin_screen.dart';
import '../../services/biometric_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:currency_picker/currency_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _version = "0.0.0";
  String _fiatCurrency = 'ZMW';
  String _bitcoinUnit = 'BTC';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final fiat = await const FlutterSecureStorage().read(key: 'fiat_currency');
    final btcUnit = await const FlutterSecureStorage().read(key: 'bitcoin_unit');
    if (mounted) {
      setState(() {
        if (fiat != null) _fiatCurrency = fiat;
        if (btcUnit != null) _bitcoinUnit = btcUnit;
      });
    }
  }

  Future<void> _savePreferences(String fiat, String btcUnit) async {
    await const FlutterSecureStorage().write(key: 'fiat_currency', value: fiat);
    await const FlutterSecureStorage().write(key: 'bitcoin_unit', value: btcUnit);
    if (mounted) {
      setState(() {
        _fiatCurrency = fiat;
        _bitcoinUnit = btcUnit;
      });
    }
  }

  Future<void> _initPackageInfo() async {
      // This is the call that fetches the data from the native side (Android/iOS)
      final info = await PackageInfo.fromPlatform();
      setState(() {
        _version = info.version;
    });
  }
  final Color primaryGold = const Color(0xFFBE8345);

  final Color bgColor = const Color(0xFF0E1A2B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          /// 1. BACKGROUND PATTERN
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/bg_pattern.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// 2. CONTENT
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(context),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const _SectionTitle(title: 'General'),
                      _buildSettingsGroup([
                        SettingsTile(
                          icon: Icons.currency_bitcoin,
                          title: 'Primary Currency',
                          subtitle: '$_fiatCurrency / $_bitcoinUnit',
                          onTap: _showCurrencyPicker,
                        ),
                        SettingsTile(
                          icon: Icons.show_chart,
                          title: 'Exchange Rates',
                          subtitle: 'Real-time prices',
                          onTap: _showExchangeRates,
                        ),
                      ]),
                      const _SectionTitle(title: 'Security'),
                      _buildSettingsGroup([
                        SettingsTile(
                          icon: Icons.security,
                          title: 'Account Security',
                          subtitle: 'Change PIN/Biometrics',
                          onTap: _showSecurityOptions,
                        ),
                      ]),
                      const _SectionTitle(title: 'Other'),
                      _buildSettingsGroup([
                        SettingsTile(
                          icon: Icons.info_outline,
                          title: 'About',
                          subtitle: _version,
                          onTap: () {
                            showAboutDialog(
                              context: context,
                              applicationName: "Sagali Wallet",
                              applicationVersion: _version,
                              applicationIcon: Image.asset('assets/images/logo-2.png', width: 50),
                              children: [
                                const Text("Secure Bitcoin Lightning wallet for Zambia."),
                              ],
                            );
                          },
                        ),
                        SettingsTile(
                          icon: Icons.logout,
                          title: 'Logout',
                          subtitle: 'Sign out safely',
                          iconColor: Colors.redAccent,
                          onTap: () {
                          // 1. Show a quick confirmation dialog (Optional but professional)
                          _showLogoutDialog(context);
  },
                        ),
                      ]),
                      const SizedBox(height: 120), // Bottom nav padding
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// 3. FLOATING BOTTOM NAV
          _floatingBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Settings',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> tiles) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(children: tiles),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162235),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("This will lock your wallet. You will need your PIN to enter again.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              // Navigate to PinScreen and clear all previous screens from the stack
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const PinScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showSecurityOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162235),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Account Security", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFBE8345).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.pin, color: Color(0xFFBE8345), size: 20),
                ),
                title: const Text("Change PIN", style: TextStyle(color: Colors.white, fontSize: 16)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ChangePinScreen()));
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFBE8345).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.fingerprint, color: Color(0xFFBE8345), size: 20),
                ),
                title: const Text("Setup Biometrics", style: TextStyle(color: Colors.white, fontSize: 16)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                onTap: () async {
                  Navigator.pop(context);
                  final bioService = BiometricService();
                  bool isSupported = await bioService.isDeviceSupported();

                  if (isSupported) {
                    bool success = await bioService.authenticate();
                    if (success) {
                      await const FlutterSecureStorage().write(key: 'use_biometrics', value: 'true');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Biometrics enabled successfully!")),
                        );
                      }
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Biometrics not supported on this device.")),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      }
    );
  }

  void _showExchangeRates() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162235),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return FutureBuilder<http.Response>(
          future: http.get(Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd,zmw')),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: Color(0xFFBE8345))),
              );
            } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.statusCode != 200) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text("Failed to load rates", style: TextStyle(color: Colors.white70))),
              );
            }

            final data = json.decode(snapshot.data!.body);
            final btc = data['bitcoin'];
            final usd = btc['usd'];
            final zmw = btc['zmw'];

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text("Live Exchange Rates", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 20),
                  _rateTile("US Dollar (USD)", usd != null ? "\$${usd.toStringAsFixed(2)}" : "N/A"),
                  const SizedBox(height: 10),
                  _rateTile("Zambian Kwacha (ZMW)", zmw != null ? "K${zmw.toStringAsFixed(2)}" : "N/A"),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        );
      }
    );
  }

  Widget _rateTile(String title, String rate) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(rate, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCurrencyPicker() {
    String tempFiat = _fiatCurrency;
    String tempBtc = _bitcoinUnit;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF162235),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: Text("Select Display Units", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 20),
                  const Text("Bitcoin Unit", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("BTC", style: TextStyle(color: Colors.white)),
                          value: "BTC",
                          groupValue: tempBtc,
                          activeColor: const Color(0xFFBE8345),
                          onChanged: (val) => setModalState(() => tempBtc = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text("Sats", style: TextStyle(color: Colors.white)),
                          value: "SATS",
                          groupValue: tempBtc,
                          activeColor: const Color(0xFFBE8345),
                          onChanged: (val) => setModalState(() => tempBtc = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Fiat Currency", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      showCurrencyPicker(
                        context: context,
                        theme: CurrencyPickerThemeData(
                          backgroundColor: const Color(0xFF162235),
                          titleTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
                          subtitleTextStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                          bottomSheetHeight: MediaQuery.of(context).size.height * 0.8,
                        ),
                        onSelect: (Currency currency) {
                          setModalState(() {
                            tempFiat = currency.code;
                          });
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(tempFiat, style: const TextStyle(color: Colors.white, fontSize: 16)),
                          const Icon(Icons.arrow_drop_down, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFBE8345),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        _savePreferences(tempFiat, tempBtc);
                        Navigator.pop(context);
                      },
                      child: const Text("Save", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _floatingBottomNav(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.account_balance_wallet,
                    label: "Wallet",
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen())),
                  ),
                  _NavItem(
                    icon: Icons.swap_horiz,
                    label: "Transactions",
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const TransactionsScreen())),
                  ),
                  _NavItem(
                    icon: Icons.settings,
                    label: "Settings",
                    isActive: true,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// --- Helper Components ---

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    );
  }
}

class SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFFBE8345)).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? const Color(0xFFBE8345), size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _NavItem({required this.icon, required this.label, required this.onTap, this.isActive = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? const Color(0xFFBE8345) : Colors.white54, size: 26),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF162235),
        title: const Text("Logout", style: TextStyle(color: Colors.white)),
        content: const Text("This will lock your wallet. You will need your PIN to enter again.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              // Navigate to PinScreen and clear all previous screens from the stack
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const PinScreen()),
                (route) => false,
              );
            },
            child: const Text("Logout", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}