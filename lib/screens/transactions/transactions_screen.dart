import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'dart:ui';
import '../../services/wallet_service.dart';
import '../../services/ldk_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';

/// 1. UNIFIED TRANSACTION MODEL
/// This allows us to mix BDK and LDK data into one list
class SagaliTransaction {
  final String title;
  final String subtitle;
  final String amount;
  final bool isExpense;
  final bool isLightning;
  final DateTime timestamp;
  final String id;

  SagaliTransaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
    required this.isLightning,
    required this.timestamp,
    required this.id,
  });
}

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final Color primaryGold = const Color(0xFFBE8345);
  final Color bgColor = const Color(0xFF0E1A2B);

  Future<List<Payment>> _getHistory() async {
    try {
      // --- PART A: ON-CHAIN (BDK) ---
      final bdkService = WalletService();
      await bdkService.syncWallet();
      final onChainTxs = await bdkService.getOnChainTransactions();

      for (var tx in onChainTxs) {
        final isReceived = tx.received > tx.sent;
        final sats = isReceived ? (tx.received - tx.sent) : (tx.sent - tx.received);
        final btc = sats / 100000000;

        // Extract timestamp safely
        int ts = 0;
        final rawTs = tx.confirmationTime?.timestamp;
        if (rawTs != null) {
          ts = rawTs is BigInt ? rawTs.toInt() : rawTs as int;
        }

        combinedList.add(SagaliTransaction(
          id: tx.txid,
          title: isReceived ? 'Received Bitcoin' : 'Sent Bitcoin',
          subtitle: tx.confirmationTime == null ? 'Pending Confirmation' : 'Confirmed On-chain',
          amount: "${isReceived ? '+' : '-'} ${btc.toStringAsFixed(8)} BTC",
          isExpense: !isReceived,
          isLightning: false,
          timestamp: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
        ));
      }

      // --- PART B: LIGHTNING (LDK) ---
      final ldkService = LdkService();
      if (ldkService.node != null) {
        final payments = await ldkService.node!.listPayments();
        for (var p in payments) {
          // Skip failed attempts to keep the list clean
          if (p.status == ldk.PaymentStatus.Failed) continue;

          final isExpense = p.direction == ldk.PaymentDirection.Outbound;
          final sats = (p.amountMsat ?? 0) ~/ 1000;

          combinedList.add(SagaliTransaction(
            id: p.hash.toString(),
            title: isExpense ? 'Lightning Sent' : 'Lightning Received',
            subtitle: p.status == ldk.PaymentStatus.Pending ? 'In Progress' : 'Lightning Payment',
            amount: "${isExpense ? '-' : '+'} $sats SATS",
            isExpense: isExpense,
            isLightning: true,
            // LDK 0.1.2 listPayments doesn't always expose timestamp in the basic object
            // We'll use current time if it's missing, or you can map it from your own DB
            timestamp: DateTime.now(), 
          ));
        }
      }

      // --- PART C: SORTING ---
      // Newest transactions at the top
      combinedList.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    } catch (e) {
      debugPrint("Full History Sync Error: $e");
    }

    return combinedList;
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
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFBE8345)));
                      }

                      final transactions = snapshot.data ?? [];

                      if (transactions.isEmpty) {
                        return const Center(
                          child: Text("No activity found", style: TextStyle(color: Colors.white38)),
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