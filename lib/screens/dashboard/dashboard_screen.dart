import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/wallet_service.dart'; // Ensure this path is correct
import '../send/send_screen.dart';
import '../receive/receive_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';
import '../withdraw/withdraw_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _btcBalance = "0.00000000";
  String _zmwBalance = "0.00";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _refreshWallet();
  }

  /// Syncs with the blockchain and updates the balance
  Future<void> _refreshWallet() async {
    setState(() => _isLoading = true);
    try {
      final wallet = WalletService().wallet;
      if (wallet != null) {
        // 1. In a real app, you'd call wallet.sync() here with a Blockchain client
        // For now, we get the cached balance from the local database
        final balance = await wallet.getBalance();
        
        // 2. Convert Satoshis to BTC
        final btcValue = balance.total / 100000000;
        
        // 3. Simple Mock Conversion (e.g., 1 BTC = 1,500,000 ZMW)
        // In production, you'd fetch this from an API like CoinGecko
        final zmwValue = btcValue * 1500000; 

        setState(() {
          _btcBalance = btcValue.toStringAsFixed(8);
          _zmwBalance = zmwValue.toStringAsFixed(2);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error refreshing wallet: $e");
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
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    Image.asset('assets/images/bolt.png', width: 45, fit: BoxFit.contain, 
                      errorBuilder: (c, e, s) => const Icon(Icons.bolt, color: Color(0xFFBE8345), size: 45)),
                    const SizedBox(height: 10),
                    const Text("SAGALI", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const Text("LIGHTNING", style: TextStyle(color: Color(0xFFBE8345), fontSize: 22, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    _payBadge(),
                    const SizedBox(height: 40),
                    
                    /// Updated Balance Section
                    _isLoading 
                      ? const CircularProgressIndicator(color: Color(0xFFBE8345))
                      : _balanceSection(),
                      
                    const SizedBox(height: 40),
                    const Text("Lightning", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    _actionButton(
                      context: context,
                      label: "Send",
                      icon: Icons.call_made,
                      background: Colors.white,
                      textColor: Colors.blue,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SendScreen())),
                    ),
                    const SizedBox(height: 14),
                    _actionButton(
                      context: context,
                      label: "Receive",
                      icon: Icons.call_received,
                      background: const Color(0xFFBE8345),
                      textColor: Colors.white,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiveScreen())),
                    ),
                    const SizedBox(height: 30),
                    const Text("Mobile Networks", style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 20),
                    _withdrawButton(context),
                    const SizedBox(height: 120), 
                  ],
                ),
              ),
            ),
          ),

          /// 3. FIXED FLOATING BOTTOM NAV
          _floatingBottomNav(context),
        ],
      ),
    );
  }

  Widget _payBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBE8345)),
      ),
      child: const Text("PAY", style: TextStyle(color: Color(0xFFBE8345), fontWeight: FontWeight.bold)),
    );
  }

  Widget _balanceSection() {
    return Column(
      children: [
        const Text("BALANCE", style: TextStyle(color: Colors.white70, letterSpacing: 1.2)),
        const SizedBox(height: 10),
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
            Text(_btcBalance, style: const TextStyle(color: Colors.white70)),
            const SizedBox(width: 6),
            const Icon(Icons.currency_bitcoin, color: Color(0xFFBE8345), size: 18),
            const SizedBox(width: 6),
            const Icon(Icons.bolt, color: Color(0xFFBE8345), size: 18),
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
          child: const Text("WITHDRAW MONEY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            height: 50,
            decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(30)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: textColor),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
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