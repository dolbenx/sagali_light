import 'package:flutter/material.dart';
import 'package:bdk_flutter/bdk_flutter.dart' as bdk;
import '../../services/wallet_service.dart';

class ConfirmSendScreen extends StatefulWidget {
  final String recipientAddress;
  const ConfirmSendScreen({super.key, required this.recipientAddress});

  @override
  State<ConfirmSendScreen> createState() => _ConfirmSendScreenState();
}

class _ConfirmSendScreenState extends State<ConfirmSendScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isSending = false;

Future<void> _handleSend() async {
    final String amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) return;

    setState(() => _isSending = true);

    try {
      // 1. Check if wallet is null before proceeding
      if (WalletService().wallet == null) {
         throw "Wallet not initialized. Please go back and try again.";
      }

      // 2. Ensure Blockchain is initialized and Synced
      // This prevents the "Null check operator" error
      await WalletService().syncWallet(); 

      final double btcAmount = double.parse(amountStr);
      final BigInt satsAmount = BigInt.from((btcAmount * 100000000).round());

      // 3. Now it is safe to use the getters
      final wallet = WalletService().getWallet;
      final blockchain = WalletService().getBlockchain;

      // ... rest of your code (Address creation, building, signing) ...
      final address = await bdk.Address.create(address: widget.recipientAddress);
      final script = await address.scriptPubKey();

      final txBuilder = bdk.TxBuilder().addRecipient(script, satsAmount.toInt());
      final txResult = await txBuilder.finish(wallet);
      
      final signedPsbt = await wallet.sign(psbt: txResult.psbt);
      final finalTx = await signedPsbt.extractTx();

      await blockchain.broadcast(finalTx);
      final txid = await finalTx.txid();

      if (mounted) {
        _showSuccessDialog(txid);
      }
    } catch (e) {
      debugPrint("Send Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }
  
  void _showSuccessDialog(String txid) {
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
            Text("Sent Successfully", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your transaction has been broadcasted to the network.", 
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const Text("TXID", style: TextStyle(color: Colors.white38, fontSize: 12)),
            SelectableText(
              txid,
              style: const TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("Done", style: TextStyle(color: Color(0xFFBE8345), fontWeight: FontWeight.bold)),
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
        title: const Text("Confirm Send"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("RECIPIENT", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.1)),
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
                style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 32),
            const Text("AMOUNT TO SEND", style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.1)),
            TextField(
              controller: _amountController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: "0.00",
                hintStyle: TextStyle(color: Colors.white10),
                border: InputBorder.none,
                suffixText: "BTC",
                suffixStyle: TextStyle(color: Colors.white24, fontSize: 18),
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
                ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("Send Bitcoin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}