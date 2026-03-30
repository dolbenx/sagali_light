import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'dart:ui';
import '../../services/wallet_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  final Color primaryGold = const Color(0xFFBE8345);
  final Color bgColor = const Color(0xFF0E1A2B);

  Future<List<Payment>> _getHistory() async {
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
                  child: FutureBuilder<List<Payment>>(
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

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        physics: const BouncingScrollPhysics(),
                        itemCount: transactions.length + 1,
                        itemBuilder: (context, index) {
                          if (index == transactions.length) return const SizedBox(height: 100);
                          return _buildPaymentTile(transactions[index]);
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

  Widget _buildPaymentTile(Payment tx) {
    final bool isReceived = tx.paymentType == PaymentType.receive;
    final double btcValue = tx.amountSat.toDouble() / 100000000;
    final String amountLabel = "${isReceived ? '+' : '-'} ${btcValue.toStringAsFixed(8)} BTC";

    // Determine subtitle from payment details and status
    String subtitle;
    switch (tx.status) {
      case PaymentState.pending:
      case PaymentState.created:
        subtitle = 'Pending Confirmation';
        break;
      case PaymentState.complete:
        final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000);
        subtitle = 'Confirmed on ${date.day}/${date.month}/${date.year}';
        break;
      case PaymentState.failed:
      case PaymentState.timedOut:
        subtitle = 'Failed';
        break;
      default:
        subtitle = 'Processing...';
    }

    // Determine payment label from details
    String title = isReceived ? 'Received' : 'Sent';
    tx.details.when(
      lightning: (swapId, description, liquidExpirationBlockheight, preimage, invoice, 
                  bolt12Offer, paymentHash, destinationPubkey, lnurlInfo, bip353Address, 
                  payerNote, claimTxId, refundTxId, refundTxAmountSat) {
        title = isReceived ? 'Received via Lightning' : 'Sent via Lightning';
      },
      liquid: (destination, description, assetId, assetInfo, lnurlInfo, bip353Address, payerNote) {
        title = isReceived ? 'Received (Liquid)' : 'Sent (Liquid)';
      },
      bitcoin: (swapId, bitcoinAddress, description, autoAcceptedFees, liquidExpirationBlockheight,
                bitcoinExpirationBlockheight, lockupTxId, claimTxId, refundTxId, refundTxAmountSat) {
        title = isReceived ? 'Received Bitcoin' : 'Sent Bitcoin';
      },
    );

    return TransactionTile(
      icon: isReceived ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
      title: title,
      subtitle: subtitle,
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
            'Transaction History',
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
                    label: "Transactions",
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