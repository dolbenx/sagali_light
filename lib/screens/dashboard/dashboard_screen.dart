import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../../services/wallet_service.dart'; // Ensure this path is correct
import '../send/send_screen.dart';
import '../receive/receive_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';
import '../withdraw/withdraw_screen.dart';
import '../../services/ldk_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  String _btcBalance = "0.00000000";
  String _zmwBalance = "0.00";
  bool _isLoading = true;
  

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshWallet();
    
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshWallet();
    });
  }

 @override
void dispose() {
  _refreshTimer?.cancel(); // Critical: Stop the timer when leaving the screen
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}

  // 4. Handle the state change
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // When the app goes to the background (minimized)
    if (state == AppLifecycleState.paused) {
      _lockApp();
    }
  }

  void _lockApp() {
    // Navigate back to the PinScreen and clear the navigation stack
    // This ensures they can't 'back' into the dashboard
    Navigator.of(context).pushNamedAndRemoveUntil('/pin', (route) => false);
  }

  /// Syncs with the blockchain and updates the balance
  Future<void> _refreshWallet() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

  try {
    final sdk = WalletService().sdk;

    if (sdk != null) {
      // 1. SYNC with the Liquid/Bitcoin network
      await sdk.sync();

      // 2. Get the updated wallet info (balance)
      final info = await sdk.getInfo();
      final BigInt balanceSat = info.walletInfo.balanceSat;
      final double btcValue = balanceSat.toDouble() / 100000000;

      // 3. Update the UI
      if (mounted) {
        setState(() {
          _btcBalance = btcValue.toStringAsFixed(8);
          // Mock conversion to ZMW
          _zmwBalance = (btcValue * 1500000).toStringAsFixed(2);
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  } catch (e) {
    debugPrint("Dashboard Sync Error: $e");
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      body: Stack(
        children: [
          /// 1. BACKGROUND PATTERN
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/bg_pattern.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(), // Fallback if image missing
              ),
            ),
          ),

          /// 2. SCROLLABLE CONTENT
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshWallet,
              color: const Color(0xFFBE8345),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          _isLoading 
                            ? const CircularProgressIndicator(color: Color(0xFFBE8345))
                            : _balanceSection(),
                            
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _actionButton(
                                    context: context,
                                    label: "Send",
                                    icon: Icons.call_made,
                                    background: Colors.white,
                                    textColor: const Color(0xFF0E1A2B),
                                    onTap: () async {
                                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const SendScreen()));
                                      _refreshWallet();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _actionButton(
                                    context: context,
                                    label: "Receive",
                                    icon: Icons.call_received,
                                    background: const Color(0xFFBE8345),
                                    textColor: Colors.white,
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiveScreen())),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Text("Funds Transfer", style: TextStyle(color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 16),
                          _withdrawButton(context),
                          const SizedBox(height: 100), 
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          /// 3. FIXED FLOATING BOTTOM NAV
          _floatingBottomNav(context),
        ],
      ),
    );
  }

  Widget _balanceSection() {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(text: "$_zmwBalance ", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              const TextSpan(text: "ZMW", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_btcBalance, style: const TextStyle(color: Colors.white70, fontSize: 23)),
            const Text(
              " BTC", 
              style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)
            ),
          ],
        ),
      ],
    );
  }

  Widget _withdrawButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WithdrawScreen())),
          child: const Text("Mobile Wallet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
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
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(icon: Icons.account_balance_wallet, label: "Wallet", isActive: true, onTap: () {}),
                  _NavItem(icon: Icons.swap_horiz, label: "Transactions", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionsScreen()))),
                  _NavItem(icon: Icons.settings, label: "Settings", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _actionButton({required BuildContext context, required String label, required IconData icon, required Color background, required Color textColor, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: background, 
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper class for Nav Items remains the same as your original snippet
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
}