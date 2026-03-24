import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bdk_flutter/bdk_flutter.dart' as bdk;
import '../../services/wallet_service.dart';
import '../../services/ldk_service.dart';

class ConfirmSendScreen extends StatefulWidget {
  final String recipientAddress;
  final bool isLightning;

  const ConfirmSendScreen({
    super.key,
    required this.recipientAddress,
    this.isLightning = false,
  });

  @override
  State<ConfirmSendScreen> createState() => _ConfirmSendScreenState();
}

class _ConfirmSendScreenState extends State<ConfirmSendScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isSending = false;
  late bool _isLightning;

  @override
  void initState() {
    super.initState();
    // Double-check the prefix if the flag wasn't explicitly passed
    _isLightning = widget.isLightning || 
                   widget.recipientAddress.toLowerCase().startsWith('lnbc');
  }

  /// THE MAIN SEND HANDLER
  Future<void> _handleSend() async {
    final String amountStr = _amountController.text.trim();
    
    // Validation: On-chain always needs an amount. 
    // Lightning might have it baked into the invoice.
    if (!_isLightning && amountStr.isEmpty) {
      _showSnackBar("Please enter an amount in Sats.");
      return;
    }

    setState(() => _isSending = true);

    try {
      if (_isLightning) {
        await _executeLightningPayment(amountStr);
      } else {
        await _executeOnChainPayment(amountStr);
      }
    } catch (e) {
      _handleError(e);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// LIGHTNING LOGIC
  Future<void> _executeLightningPayment(String amountStr) async {
    final ldk = LdkService();
    
    if (amountStr.isEmpty) {
      // 1. Fixed-Amount Invoice
      await ldk.sendPayment(widget.recipientAddress);
    } else {
      // 2. Zero-Amount (Variable) Invoice
      final int sats = int.parse(amountStr);
      await ldk.sendPaymentWithAmount(widget.recipientAddress, sats);
    }

    if (mounted) _showSuccessDialog("Lightning Payment Sent!");
  }

  /// ON-CHAIN LOGIC (BDK)
  Future<void> _executeOnChainPayment(String amountStr) async {
    final walletService = WalletService();
    if (walletService.wallet == null) throw "Wallet not initialized.";

    await walletService.syncWallet();
    
    final int satsAmount = int.parse(amountStr);
    final wallet = walletService.getWallet;
    final blockchain = walletService.getBlockchain;

    final address = await bdk.Address.create(address: widget.recipientAddress);
    final script = await address.scriptPubKey();

    // Build, Sign, and Broadcast
    final txBuilder = bdk.TxBuilder().addRecipient(script, satsAmount);
    final txResult = await txBuilder.finish(wallet);
    final signedPsbt = await wallet.sign(psbt: txResult.psbt);
    final finalTx = await signedPsbt.extractTx();

    await blockchain.broadcast(finalTx);
    final txid = await finalTx.txid();

    if (mounted) _showSuccessDialog(txid);
  }

  /// HELPER: Error Mapping
  void _handleError(dynamic e) {
    debugPrint("Send Error: $e");
    String errorMsg = e.toString();
    
    if (errorMsg.contains("InsufficientFunds")) {
      errorMsg = "Insufficient balance to cover amount + fees.";
    } else if (errorMsg.contains("NoRouteFound")) {
      errorMsg = "No Lightning route found. Check your outbound capacity.";
    }

    _showSnackBar(errorMsg, isError: true);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.blueAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog(String identifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E1A2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent),
            SizedBox(width: 10),
            Text("Success!", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          _isLightning ? identifier : "Transaction Broadcasted.\n\nID: $identifier",
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("CLOSE", style: TextStyle(color: Color(0xFFBE8345))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      appBar: AppBar(
        title: Text(_isLightning ? "Pay Invoice" : "Send Bitcoin"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isLightning ? "LIGHTNING INVOICE" : "RECIPIENT ADDRESS",
                style: const TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.recipientAddress,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 32),
            const Text("AMOUNT TO SEND",
                style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.1)),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: _isLightning ? "Optional" : "0",
                hintStyle: const TextStyle(color: Colors.white10),
                border: InputBorder.none,
                suffixText: "SATS",
                suffixStyle: const TextStyle(color: Colors.white24, fontSize: 18),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSending ? null : _handleSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBE8345),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Confirm Payment",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}