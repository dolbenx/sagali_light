import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import '../../services/wallet_service.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Payment> _transactions = [];
  bool _isLoading = true;

  final List<String> _months = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun", 
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"
  ];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    try {
      final txs = await WalletService().getOnChainTransactions();
      if (mounted) {
        setState(() {
          _transactions = txs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching txs: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      appBar: AppBar(
        title: const Text('Transactions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _isLoading = true);
              _fetchTransactions();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/bg_pattern.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFBE8345)))
              : _transactions.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionList(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 80, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 24),
            const Text(
              "No Spark History",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "No transactions found on the Spark network.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: const Color(0xFFBE8345).withOpacity(0.7), size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        "Liquid vs Spark",
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "This wallet uses the Breez Spark SDK. If you previously had funds on the Liquid Network (LBTC), they are stored on a different protocol and will not appear here automatically. You must transfer them from a Liquid-capable wallet to your new address to see them here.",
                    style: TextStyle(color: Colors.white24, fontSize: 11, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return ListView.separated(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 120),
      itemCount: _transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final tx = _transactions[index];
        return _buildPaymentTile(tx);
      },
    );
  }

  Widget _buildPaymentTile(Payment tx) {
    final bool isReceived = tx.paymentType == PaymentType.receive;
    final double btcValue = (tx.amount).toDouble() / 100000000;
    final String amountLabel = "${isReceived ? '+' : '-'} ${btcValue.toStringAsFixed(8)} BTC";

    String subtitle;
    final status = tx.status;
    if (status == PaymentStatus.pending) {
      subtitle = 'Pending Confirmation';
    } else if (status == PaymentStatus.completed) {
      final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp.toInt() * 1000);
      final month = _months[date.month - 1];
      final time = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
      subtitle = '$month ${date.day}, ${date.year} • $time';
    } else if (status == PaymentStatus.failed) {
      subtitle = 'Failed';
    } else {
      subtitle = 'Processing...';
    }

    String title = isReceived ? 'Received' : 'Sent';
    final details = tx.details;
    if (details is PaymentDetails_Lightning) {
      title = isReceived ? 'Received via Lightning' : 'Sent via Lightning';
    } else if (details is PaymentDetails_Deposit) {
      title = 'Received Bitcoin';
    } else if (details is PaymentDetails_Withdraw) {
      title = 'Sent Bitcoin';
    } else if (details is PaymentDetails_Spark) {
      title = isReceived ? 'Received via Spark' : 'Sent via Spark';
    }

    Color themeColor;
    if (status == PaymentStatus.pending) {
      themeColor = Colors.white;
    } else if (status == PaymentStatus.failed) {
      themeColor = Colors.redAccent;
    } else if (isReceived) {
      themeColor = Colors.greenAccent;
    } else {
      themeColor = const Color(0xFFBE8345);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: () => _showTransactionDetails(tx, title, themeColor),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isReceived ? Icons.add : Icons.remove,
            color: themeColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
        ),
        trailing: Text(
          amountLabel,
          style: TextStyle(
            color: isReceived ? Colors.greenAccent : Colors.white70,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showTransactionDetails(Payment tx, String title, Color themeColor) {
    final bool isReceived = tx.paymentType == PaymentType.receive;
    final double btcValue = (tx.amount).toDouble() / 100000000;
    final double feeValue = (tx.fees).toDouble() / 100000000;
    final String fiatValue = (btcValue * 1500000).toStringAsFixed(2);
    final String feeFiatValue = (feeValue * 1500000).toStringAsFixed(2);
    final date = DateTime.fromMillisecondsSinceEpoch(tx.timestamp.toInt() * 1000);
    final month = _months[date.month - 1];
    final time = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    final String formattedDate = "$month ${date.day}, ${date.year} • $time";

    String? txId;
    String? payDesc;
    String? address;

    final details = tx.details;
    if (details is PaymentDetails_Lightning) {
      payDesc = details.description;
      address = details.invoice;
    } else if (details is PaymentDetails_Deposit) {
      txId = details.txId;
      address = null; // Address not directly available in Deposit details
    } else if (details is PaymentDetails_Withdraw) {
      txId = details.txId;
      address = null; // Address not directly available in Withdraw details
    } else if (details is PaymentDetails_Spark) {
      payDesc = details.invoiceDetails?.description;
      address = details.invoiceDetails?.invoice;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF0E1A2B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(isReceived ? Icons.call_received : Icons.call_made, color: themeColor, size: 30),
            ),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(btcValue.toStringAsFixed(8) + " BTC", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            Text("≈ $fiatValue ZMW", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(
                children: [
                  _detailRow("Status", tx.status.name.toUpperCase(), valueColor: themeColor),
                  _detailRow("Date", formattedDate),
                  _detailRow("Fees", "${feeValue.toStringAsFixed(8)} BTC"),
                  _detailRow("Fees (ZMW)", "$feeFiatValue ZMW"),
                  if (payDesc != null && payDesc.isNotEmpty) _detailRow("Description", payDesc),
                  if (address != null && address!.isNotEmpty) _detailRow("Address", address!.substring(0, 8) + "..." + address!.substring(address!.length - 8), isCopyable: true, fullValue: address),
                  if (txId != null) _detailRow("TX ID", txId.substring(0, 8) + "..." + txId.substring(txId.length - 8), isCopyable: true, fullValue: txId),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBE8345), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {Color valueColor = Colors.white70, bool isCopyable = false, String? fullValue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13)),
          GestureDetector(
            onTap: isCopyable ? () {
              Clipboard.setData(ClipboardData(text: fullValue ?? value));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Copied to clipboard"), behavior: SnackBarBehavior.floating));
            } : null,
            child: Row(
              children: [
                Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w600, fontSize: 14)),
                if (isCopyable) const SizedBox(width: 6),
                if (isCopyable) Icon(Icons.copy, size: 14, color: Colors.white.withOpacity(0.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}