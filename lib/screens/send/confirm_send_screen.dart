import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
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
  bool _isLightningWithAmount = false;

  @override
  void initState() {
    super.initState();
    _detectInvoiceAmount();
  }

  Future<void> _detectInvoiceAmount() async {
    try {
      final sdk = WalletService().sdk;
      if (sdk == null) return;

      final inputType = await sdk.parse(input: widget.recipientAddress);
      if (inputType is InputType_Bolt11) {
        final amountMsat = inputType.invoice.amountMsat;
        if (amountMsat != null) {
          setState(() {
            _amountController.text = (amountMsat / BigInt.from(1000)).toString();
            _isLightningWithAmount = true;
          });
        }
      }
    } catch (e) {
      debugPrint("Error detecting amount: $e");
    }
  }

  Future<void> _handleSend() async {
    final String amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final sdk = WalletService().sdk;
      if (sdk == null) throw "Wallet not initialized. Please restart the app.";

      final int satsAmount = int.parse(amountStr);

      // Parse the input to determine if Lightning or On-chain
      final inputType = await sdk.parse(input: widget.recipientAddress);

      await inputType.when(
        bolt11: (invoice) async {
          // ---- LIGHTNING PAYMENT ----
          // Use provided amount for amountless invoices, or the invoice's own amount
          final prepareRes = await sdk.prepareSendPayment(
            req: PrepareSendRequest(
              destination: widget.recipientAddress,
              amount: invoice.amountMsat == null 
                ? PayAmount.bitcoin(receiverAmountSat: BigInt.from(satsAmount * 1000)) 
                : null,
            ),
          );
          final sendRes = await sdk.sendPayment(req: SendPaymentRequest(prepareResponse: prepareRes));
          if (mounted) _showSuccessDialog(sendRes.payment.txId ?? sendRes.payment.destination ?? 'Sent');
        },
        bitcoinAddress: (address) async {
          // ---- ON-CHAIN BITCOIN PAYMENT (via swap) ----
          final prepareRes = await sdk.preparePayOnchain(
            req: PreparePayOnchainRequest(
              amount: PayAmount.bitcoin(receiverAmountSat: BigInt.from(satsAmount)),
            ),
          );
          final sendRes = await sdk.payOnchain(
            req: PayOnchainRequest(
              address: widget.recipientAddress,
              prepareResponse: prepareRes,
            ),
          );
          if (mounted) _showSuccessDialog(sendRes.payment.txId ?? 'Sent');
        },
        liquidAddress: (address) async {
          // ---- LIQUID PAYMENT ----
          final prepareRes = await sdk.prepareSendPayment(
            req: PrepareSendRequest(
              destination: widget.recipientAddress,
              amount: PayAmount.bitcoin(receiverAmountSat: BigInt.from(satsAmount * 1000)), 
            ),
          );
          final sendRes = await sdk.sendPayment(req: SendPaymentRequest(prepareResponse: prepareRes));
          if (mounted) _showSuccessDialog(sendRes.payment.txId ?? sendRes.payment.destination ?? 'Sent');
        },
        // Fallback for other types
        nodeId: (_) => throw "Unsupported destination",
        url: (_) => throw "Unsupported destination",
        lnUrlPay: (data, bip353Address) => throw "LNUrl not supported yet",
        lnUrlWithdraw: (_) => throw "LNUrl Withdraw not supported",
        lnUrlAuth: (_) => throw "LNUrl Auth not supported",
        lnUrlError: (_) => throw "LNUrl Error",
        bolt12Offer: (offer, bip353Address) => throw "BOLT12 not supported yet",
        nostrWalletConnectUri: (_) => throw "NWC not supported",
      );
    } catch (e) {
      debugPrint("Send Error: $e");
      String errorMsg = e.toString();
      if (errorMsg.contains("InsufficientFunds") || errorMsg.contains("insufficient")) {
        errorMsg = "You don't have enough funds to cover this amount plus the network fee.";
      } else if (errorMsg.contains("invalid digit")) {
        errorMsg = "Please enter a valid number of Satoshis.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg.replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
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
            Text("Sats Sent!", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Your transaction has been broadcasted.",
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 16),
            const Text("TRANSACTION ID",
                style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.1)),
            const SizedBox(height: 4),
            SelectableText(
              txid,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text("CLOSE",
                style: TextStyle(color: Color(0xFFBE8345), fontWeight: FontWeight.bold)),
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
            const Text("RECIPIENT",
                style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.1)),
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
                style: const TextStyle(
                    color: Colors.white, fontSize: 14, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 32),
            const Text("AMOUNT TO SEND",
                style: TextStyle(color: Colors.white38, fontSize: 12, letterSpacing: 1.1)),
            TextField(
              controller: _amountController,
              autofocus: !_isLightningWithAmount,
              readOnly: _isLightningWithAmount,
              // Number keyboard without decimals
              keyboardType: TextInputType.number,
              // Block commas, dots, or negative signs
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                  color: _isLightningWithAmount ? Colors.white54 : Colors.white, 
                  fontSize: 40, 
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "0",
                hintStyle: const TextStyle(color: Colors.white10),
                border: InputBorder.none,
                suffixText: "SATS",
                suffixStyle: const TextStyle(color: Colors.white24, fontSize: 18),
                helperText: _isLightningWithAmount ? "Amount is fixed by the invoice" : null,
                helperStyle: const TextStyle(color: Color(0xFFBE8345)),
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
                  : const Text("Send Sats",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}