import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bdk_flutter/bdk_flutter.dart' as bdk;
import 'dart:ui';
import '../../services/wallet_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  final Color primaryGold = const Color(0xFFBE8345);
  final Color bgColor = const Color(0xFF0E1A2B);

  Future<List<bdk.TransactionDetails>> _getHistory() async {
    try {
      await WalletService().syncWallet();
      return await WalletService().getOnChainTransactions();
    } catch (e) {
      debugPrint("Sync error: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(context),
                const SizedBox(height: 10),
                Expanded(
                  child: FutureBuilder<List<bdk.TransactionDetails>>(
                    future: _getHistory(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFFBE8345)),
                        );
                      }

                      final transactions = snapshot.data ?? [];

                      if (transactions.isEmpty) {
                        return const Center(
                          child: Text(
                            "No transaction history found",
                            style: TextStyle(color: Colors.white38),
                          ),
                        );
                      }

                      // FIX: Safe sorting logic that handles both int and BigInt types
                      transactions.sort((a, b) {
                        BigInt extractTime(dynamic tx) {
                          final timestamp = tx.confirmationTime?.timestamp;
                          if (timestamp == null) return BigInt.from(8640000000);
                          // Safely convert to BigInt regardless of input type
                          return timestamp is BigInt ? timestamp : BigInt.from(timestamp as int);
                        }

                        final aTime = extractTime(a);
                        final bTime = extractTime(b);
                        return bTime.compareTo(aTime);
                      });

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        physics: const BouncingScrollPhysics(),
                        itemCount: transactions.length + 1,
                        itemBuilder: (context, index) {
                          if (index == transactions.length) return const SizedBox(height: 100);
                          return _buildOnChainTile(transactions[index]);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          _floatingBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildOnChainTile(bdk.TransactionDetails tx) {
    // 1. Logic for Net Amount (Received - Sent)
    // We use .toBigInt() or direct subtraction depending on your BDK version
    final BigInt received = BigInt.from(tx.received);
    final BigInt sent = BigInt.from(tx.sent);
    
    final bool isReceived = received > sent;
    final BigInt netAmountSats = isReceived ? (received - sent) : (sent - received);
    
    // 2. Convert Satoshis to BTC decimal string
    final double btcValue = netAmountSats.toDouble() / 100000000;
    final String amountLabel = "${isReceived ? '+' : '-'} ${btcValue.toStringAsFixed(8)} BTC";

    return TransactionTile(
      icon: isReceived ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
      title: isReceived ? 'Received Bitcoin' : 'Sent Bitcoin',
      subtitle: tx.confirmationTime == null 
          ? 'Pending Confirmation' 
          : 'Confirmed at block ${tx.confirmationTime!.height}',
      amount: amountLabel,
      isExpense: !isReceived,
    );
  }

  // ... (Header and Nav methods remain the same)
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
            'Activity',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
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
                    label: "History",
                    isActive: true,
                    onTap: () {},
                  ),
                  _NavItem(
                    icon: Icons.settings,
                    label: "Settings",
                    onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
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

// ... (TransactionTile and _NavItem classes remain the same)
class TransactionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isExpense;

  const TransactionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isExpense ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
          child: FaIcon(icon, color: isExpense ? Colors.redAccent : Colors.greenAccent, size: 18),
        ),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: Text(
          amount,
          style: TextStyle(
            color: isExpense ? Colors.redAccent : Colors.greenAccent,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
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
}