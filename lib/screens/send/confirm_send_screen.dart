import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import '../../services/wallet_service.dart';
import 'send_screen.dart';

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
  bool _isAmountlessLightning = false; 
  bool _isBitcoinOnchain = false;
  bool _isSparkAddress = false;
  bool _isSparkInvoice = false;

  BigInt? _estimatedFeeSat;
  PrepareSendPaymentResponse? _prepareResponse;

  @override
  void initState() {
    super.initState();
    _detectInvoiceAmount();
  }

  Future<void> _detectInvoiceAmount() async {
    try {
      setState(() {
        _isBitcoinOnchain = false;
        _isLightningWithAmount = false;
        _isAmountlessLightning = false;
        _isSparkAddress = false;
        _isSparkInvoice = false;
        _estimatedFeeSat = null;
        _prepareResponse = null;
      });

      final sdk = WalletService().sdk;
      if (sdk == null) return;

      final inputType = await sdk.parse(input: widget.recipientAddress);

      if (inputType is InputType_Bolt11Invoice) {
        final amountMsat = inputType.field0.amountMsat;
        if (amountMsat != null && amountMsat != BigInt.zero) {
          setState(() {
            _amountController.text =
                (amountMsat ~/ BigInt.from(1000)).toString();
            _isLightningWithAmount = true;
          });
        } else {
          setState(() => _isAmountlessLightning = true);
        }
      } else if (inputType is InputType_BitcoinAddress) {
        setState(() => _isBitcoinOnchain = true);
      } else if (inputType is InputType_SparkAddress) {
        setState(() => _isSparkAddress = true);
      } else if (inputType is InputType_SparkInvoice) {
        final amt = inputType.field0.amount;
        if (amt != null && amt > BigInt.zero) {
          setState(() {
            _amountController.text = amt.toString();
            _isSparkInvoice = true;
            _isLightningWithAmount = true;
          });
        } else {
          setState(() => _isSparkInvoice = true);
        }
      }
    } catch (e) {
      debugPrint("Error detecting invoice type: $e");
    }
  }

  Future<void> _prepareSend(int satsAmount) async {
    final sdk = WalletService().sdk;
    if (sdk == null) return;

    try {
      final BigInt? amountArg = (_isAmountlessLightning || _isSparkAddress)
          ? BigInt.from(satsAmount)
          : null;

      final response = await sdk.prepareSendPayment(
        request: PrepareSendPaymentRequest(
          paymentRequest: widget.recipientAddress,
          amount: amountArg,
          tokenIdentifier: null,
          conversionOptions: null,
          feePolicy: null,
        ),
      );

      BigInt? fee;
      final method = response.paymentMethod;
      if (method is SendPaymentMethod_Bolt11Invoice) {
        fee = method.lightningFeeSats;
      } else if (method is SendPaymentMethod_BitcoinAddress) {
        fee = method.feeQuote.speedMedium.userFeeSat +
            method.feeQuote.speedMedium.l1BroadcastFeeSat;
      } else if (method is SendPaymentMethod_SparkAddress) {
        fee = method.fee;
      }

      setState(() {
        _prepareResponse = response;
        _estimatedFeeSat = fee;
      });
    } catch (e) {
      debugPrint("Prepare Error: $e");
      rethrow;
    }
  }

  Future<void> _handleSend() async {
    final String amountStr = _amountController.text.trim();
    if (amountStr.isEmpty) return;

    setState(() => _isSending = true);

    try {
      final sdk = WalletService().sdk;
      if (sdk == null) throw "Wallet not initialized. Please restart the app.";

      final int satsAmount = double.parse(amountStr).round();

      if (_isBitcoinOnchain && satsAmount < 1000) {
        throw "Minimum amount for Bitcoin on-chain is 1,000 sats.";
      }

      await _prepareSend(satsAmount);
      if (_prepareResponse == null) throw "Failed to prepare payment.";

      if (mounted) {
        await _showFeeDialog(satsAmount);
      }
    } catch (e) {
      debugPrint("Send Error: $e");
      String errorMsg = e.toString();
      if (errorMsg.contains("InsufficientFunds") ||
          errorMsg.contains("insufficient")) {
        errorMsg =
            "You don't have enough funds to cover this amount plus the network fee.";
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

  Future<void> _showFeeDialog(int satsAmount) async {
    final feeText = _estimatedFeeSat != null
        ? '${_estimatedFeeSat} sats'
        : 'unknown';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0E1A2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Confirm Payment",
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _feeRow("Amount", "$satsAmount sats"),
            _feeRow("Network Fee", feeText),
            const Divider(color: Colors.white12, height: 24),
            _feeRow(
              "Total",
              "${satsAmount + (_estimatedFeeSat?.toInt() ?? 0)} sats",
              bold: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL",
                style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("CONFIRM",
                style: TextStyle(
                    color: Color(0xFFBE8345), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSending = true);
    try {
      final sdk = WalletService().sdk;
      if (sdk == null) throw "Wallet not initialized.";

      final method = _prepareResponse!.paymentMethod;
      SendPaymentOptions? options;
      if (method is SendPaymentMethod_Bolt11Invoice) {
        options = const SendPaymentOptions.bolt11Invoice(
          preferSpark: true,
          completionTimeoutSecs: 30,
        );
      }

      final response = await sdk.sendPayment(
        request: SendPaymentRequest(
          prepareResponse: _prepareResponse!,
          options: options,
          idempotencyKey: null,
        ),
      );

      if (mounted) {
        _showSuccessDialog(response.payment.id);
      }
    } catch (e) {
      debugPrint("Send Error (execute): $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e
                .toString()
                .replaceAll('Exception:', '')
                .trim()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Widget _feeRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _showSuccessDialog(String paymentId) {
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
            const Text("PAYMENT ID",
                style: TextStyle(
                    color: Colors.white38, fontSize: 10, letterSpacing: 1.1)),
            const SizedBox(height: 4),
            SelectableText(
              paymentId,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SendScreen()),
              (route) => route.isFirst,
            ),
            child: const Text("CLOSE",
                style: TextStyle(
                    color: Color(0xFFBE8345), fontWeight: FontWeight.bold)),
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
                style: TextStyle(
                    color: Colors.white38, fontSize: 12, letterSpacing: 1.1)),
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
                overflow: TextOverflow.ellipsis,
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 24),
            if (_isSparkAddress || _isSparkInvoice || _isAmountlessLightning ||
                _isBitcoinOnchain) ...[
              _buildTypeBadge(),
              const SizedBox(height: 16),
            ],
            const Text("AMOUNT TO SEND",
                style: TextStyle(
                    color: Colors.white38, fontSize: 12, letterSpacing: 1.1)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              autofocus: !_isLightningWithAmount,
              readOnly: _isLightningWithAmount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: TextStyle(
                  color: _isLightningWithAmount
                      ? Colors.white54
                      : Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: "0",
                hintStyle: const TextStyle(color: Colors.white10),
                border: InputBorder.none,
                suffixText: "SATS",
                suffixStyle:
                    const TextStyle(color: Colors.white24, fontSize: 18),
                helperText: _isLightningWithAmount
                    ? "Amount is fixed by the invoice"
                    : (_isBitcoinOnchain
                        ? "Minimum: 1,000 SAT for Bitcoin on-chain"
                        : (_isAmountlessLightning
                            ? "Enter how many sats to send"
                            : null)),
                helperStyle: TextStyle(
                    color: _isBitcoinOnchain
                        ? Colors.blueAccent
                        : const Color(0xFFBE8345)),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSending ? null : _handleSend,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFBE8345),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSending
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text(
                      "Send Sats",
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    String label;
    Color color;
    IconData icon;

    if (_isSparkAddress) {
      label = "Spark Transfer";
      color = Colors.purpleAccent;
      icon = Icons.flash_on;
    } else if (_isSparkInvoice) {
      label = "Spark Invoice";
      color = Colors.purpleAccent;
      icon = Icons.receipt;
    } else if (_isAmountlessLightning) {
      label = "Lightning (enter amount)";
      color = Colors.orangeAccent;
      icon = Icons.bolt;
    } else {
      label = "Bitcoin On-chain";
      color = Colors.blueAccent;
      icon = Icons.currency_bitcoin;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}