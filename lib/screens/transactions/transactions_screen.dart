import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'dart:ui';
import '../../services/wallet_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../settings/settings_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final Color primaryGold = const Color(0xFFBE8345);
  final Color bgColor = const Color(0xFF0E1A2B);

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  Future<List<Payment>> _getHistory() async {
    try {
      final walletService = WalletService();
      await walletService.syncWallet();
      return await walletService.getOnChainTransactions();
    } catch (e) {
      debugPrint("History Sync Error: $e");
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
                        return const Center(child: CircularProgressIndicator(color: Color(0xFFBE8345)));
                      }

                      final transactions = snapshot.data ?? [];

                      if (transactions.isEmpty) {
                        return const Center(
                          child: Text("No Activity Found", style: TextStyle(color: Colors.white38)),
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
        final month = _months[date.month - 1];
        final time = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
        subtitle = '$month ${date.day}, ${date.year} • $time';
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

    // Determine color based on status and type
    Color themeColor;
    if (tx.status == PaymentState.pending || tx.status == PaymentState.created) {
      themeColor = Colors.white;
    } else if (tx.status == PaymentState.failed || tx.status == PaymentState.timedOut) {
      themeColor = Colors.redAccent;
    } else if (isReceived) {
      themeColor = Colors.greenAccent;
    } else {
      // Sent (Complete)
      themeColor = const Color(0xFFBE8345); // Gold
    }

    return TransactionTile(
      icon: isReceived ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp,
      title: title,
      subtitle: subtitle,
      amount: amountLabel,
      themeColor: themeColor,
      isExpense: !isReceived,
      onTap: () => _showTransactionDetails(tx, title, themeColor),
    );
  }

  void _showTransactionDetails(Payment tx, String title, Color themeColor) {
    final bool isReceived = tx.paymentType == PaymentType.receive;
    final double btcValue = tx.amountSat.toDouble() / 100000000;
    final double feeValue = (tx.feesSat.toDouble() + (tx.swapperFeesSat?.toDouble() ?? 0)) / 100000000;
    
    // Mock conversion (consistent with dashboard)
    final String fiatValue = (btcValue * 1500000).toStringAsFixed(2);
    final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp * 1000);
    final month = _months[date.month - 1];
    final time = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    final String formattedDate = "$month ${date.day}, ${date.year} • $time";

    String statusText = tx.status.name.toUpperCase();
    String address = "N/A";
    String? txId;
    String? payDesc;

    tx.details.when(
      lightning: (swapId, description, _, __, invoice, ___, paymentHash, ____, _____, ______, _______, ________, _________, __________) {
        address = invoice ?? paymentHash ?? "N/A";
        txId = swapId;
        payDesc = description;
      },
      liquid: (destination, description, _, __, ___, ____, _____) {
        address = destination;
        payDesc = description;
      },
      bitcoin: (swapId, bitcoinAddress, description, _, __, ___, lockupTxId, claimTxId, ____, _____) {
        address = bitcoinAddress;
        txId = claimTxId ?? lockupTxId ?? swapId;
        payDesc = description;
      },
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0E1A2B),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              // Header Icon
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
                child: FaIcon(isReceived ? FontAwesomeIcons.arrowDown : FontAwesomeIcons.arrowUp, color: themeColor, size: 32),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text(statusText, style: TextStyle(color: themeColor, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 32),
              
              // Amount Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withOpacity(0.05))),
                child: Column(
                  children: [
                    Text("${isReceived ? '+' : '-'} ${btcValue.toStringAsFixed(8)} BTC", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text("≈ $fiatValue ZMW", style: const TextStyle(color: Colors.white54, fontSize: 16)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Info Rows
              if (payDesc != null && payDesc!.trim().isNotEmpty) ...[
                _infoRow("Description", payDesc!),
              ],
              _infoRow("Date", formattedDate),
              _infoRow("Network Fee", "${feeValue.toStringAsFixed(8)} BTC"),
              if (txId != null) _infoRowWithCopy("Transaction ID", txId!),
              _infoRowWithCopy(isReceived ? "From" : "To", address),
              
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Close", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _infoRowWithCopy(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(child: Text(value, style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'), overflow: TextOverflow.ellipsis)),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard"), behavior: SnackBarBehavior.floating));
                  },
                  child: Icon(Icons.copy_all_rounded, color: primaryGold, size: 20),
                ),
              ],
            ),
          ),
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

class TransactionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final Color themeColor;
  final bool isExpense;
  final VoidCallback onTap;

  const TransactionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.themeColor,
    required this.isExpense,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: FaIcon(
                icon,
                color: themeColor,
                size: 18,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: TextStyle(
                color: themeColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
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