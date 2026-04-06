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
  bool _isBitcoinOnchain = false;
  bool _isLnUrlPay = false;
  bool _isLnUrlAuth = false;
  bool _isBolt12 = false;
  int? _minLnUrlSats;
  int? _maxLnUrlSats;

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
        _isLnUrlPay = false;
        _isLnUrlAuth = false;
        _isBolt12 = false;
        _minLnUrlSats = null;
        _maxLnUrlSats = null;
      });

      final sdk = WalletService().sdk;
      if (sdk == null) return;

      final inputType = await sdk.parse(input: widget.recipientAddress);
      
      if (inputType is InputType_Bolt11) {
        final amountMsat = inputType.invoice.amountMsat;
        if (amountMsat != null && amountMsat != BigInt.zero) {
          setState(() {
            // Use integer division to avoid decimals (1000 msat = 1 sat)
            _amountController.text = (amountMsat ~/ BigInt.from(1000)).toString();
            _isLightningWithAmount = true;
          });
        }
      } else if (inputType is InputType_BitcoinAddress) {
        setState(() {
          _isBitcoinOnchain = true;
        });
      } else if (inputType is InputType_LnUrlPay) {
        setState(() {
          _isLnUrlPay = true;
          _minLnUrlSats = (inputType.data.minSendable ~/ BigInt.from(1000)).toInt();
          _maxLnUrlSats = (inputType.data.maxSendable ~/ BigInt.from(1000)).toInt();
          // Pre-fill min amount if it's the same as max (fixed amount LNURL)
          if (_minLnUrlSats == _maxLnUrlSats) {
            _amountController.text = _minLnUrlSats.toString();
            _isLightningWithAmount = true;
          }
        });
      } else if (inputType is InputType_LnUrlAuth) {
        setState(() {
          _isLnUrlAuth = true;
        });
        // Auto-trigger auth confirmation
        WidgetsBinding.instance.addPostFrameCallback((_) => _handleLnUrlAuth(inputType.data));
      } else if (inputType is InputType_Bolt12Offer) {
        setState(() {
          _isBolt12 = true;
          final minAmt = inputType.offer.minAmount;
          if (minAmt is Amount_Bitcoin) {
             _amountController.text = (minAmt.amountMsat ~/ BigInt.from(1000)).toString();
          }
        });
      }

      // FETCH AND LOG GLOBAL LIGHTNING LIMITS FOR DEBUGGING
      try {
        final limits = await sdk.fetchLightningLimits();
        debugPrint("Lightning Limits (SEND): Min=${limits.send.minSat}, Max=${limits.send.maxSat}");
      } catch (e) {
        debugPrint("Could not fetch Lightning limits: $e");
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

      // Parse as double first to handle cases like "10.0" then convert to Satoshis
      final int satsAmount = double.parse(amountStr).round();

      // Proactive check for Bitcoin on-chain minimum
      if (_isBitcoinOnchain && satsAmount < 25000) {
        throw "Minimum amount for Bitcoin on-chain is 25,000 sats.";
      }

      // Parse the input to determine if Lightning or On-chain
      final inputType = await sdk.parse(input: widget.recipientAddress);

      await inputType.when(
        bolt11: (invoice) async {
          // ---- LIGHTNING PAYMENT ----
          final bool invoiceHasAmount = invoice.amountMsat != null && invoice.amountMsat! > BigInt.zero;
          debugPrint("Lightning Send: HasAmount=$invoiceHasAmount, AmountMsat=${invoice.amountMsat}, ManualSats=$satsAmount");

          final prepareRes = await sdk.prepareSendPayment(
            req: PrepareSendRequest(
              // Use the cleaned bolt11 string from the SDK parse
              destination: invoice.bolt11,
              amount: !invoiceHasAmount 
                ? PayAmount.bitcoin(receiverAmountSat: BigInt.from(satsAmount)) 
                : null,
            ),
          );
          final sendRes = await sdk.sendPayment(req: SendPaymentRequest(prepareResponse: prepareRes));
          if (mounted) _showSuccessDialog(sendRes.payment.txId ?? sendRes.payment.destination ?? 'Sent');
        },
        bitcoinAddress: (addressData) async {
          // ---- ON-CHAIN BITCOIN PAYMENT (via swap) ----
          final prepareRes = await sdk.preparePayOnchain(
            req: PreparePayOnchainRequest(
              amount: PayAmount.bitcoin(receiverAmountSat: BigInt.from(satsAmount)),
            ),
          );
          final sendRes = await sdk.payOnchain(
            req: PayOnchainRequest(
              address: addressData.address, // Use cleaned address
              prepareResponse: prepareRes,
            ),
          );
          if (mounted) _showSuccessDialog(sendRes.payment.txId ?? 'Sent');
        },
        liquidAddress: (addressData) async {
          // ---- LIQUID PAYMENT ----
          final prepareRes = await sdk.prepareSendPayment(
            req: PrepareSendRequest(
              destination: addressData.address, // Use cleaned address
              amount: PayAmount.bitcoin(receiverAmountSat: BigInt.from(satsAmount)), 
            ),
          );
          final sendRes = await sdk.sendPayment(req: SendPaymentRequest(prepareResponse: prepareRes));
          if (mounted) _showSuccessDialog(sendRes.payment.txId ?? sendRes.payment.destination ?? 'Sent');
        },
        lnUrlPay: (data, bip353Address) async {
          // ---- LNURL PAY (Lightning Address) ----
          if (_minLnUrlSats != null && satsAmount < _minLnUrlSats!) {
            throw "Minimum amount for this address is ${_minLnUrlSats} sats.";
          }
          if (_maxLnUrlSats != null && satsAmount > _maxLnUrlSats!) {
            throw "Maximum amount for this address is ${_maxLnUrlSats} sats.";
          }

          final prepareRes = await sdk.prepareLnurlPay(
            req: PrepareLnUrlPayRequest(
              data: data,
              amount: PayAmount.bitcoin(receiverAmountSat: BigInt.from(satsAmount)),
              bip353Address: bip353Address,
            ),
          );
          
          final payRes = await sdk.lnurlPay(
            req: LnUrlPayRequest(
              prepareResponse: prepareRes,
            ),
          );
          
          if (mounted) _showSuccessDialog('Payment Successful');
        },
        lnUrlWithdraw: (data) async {
          // ---- LNURL WITHDRAW ----
          final withdrawRes = await sdk.lnurlWithdraw(
            req: LnUrlWithdrawRequest(
              data: data,
              amountMsat: BigInt.from(satsAmount * 1000),
            ),
          );
          if (mounted) _showSuccessDialog('Withdrawal Successful');
        },
        bolt12Offer: (offerData, bip353Address) async {
          // ---- BOLT12 PAYMENT ----
          try {
            // offerData is the LNOffer object
            final invoiceRes = await sdk.createBolt12Invoice(
              req: CreateBolt12InvoiceRequest(
                offer: offerData.offer,
                invoiceRequest: "",
              ),
            );
            
            final prepareRes = await sdk.prepareSendPayment(
              req: PrepareSendRequest(
                destination: invoiceRes.invoice,
              ),
            );
            
            final sendRes = await sdk.sendPayment(req: SendPaymentRequest(prepareResponse: prepareRes));
            if (mounted) _showSuccessDialog(sendRes.payment.txId ?? 'Sent');
          } catch (e) {
            throw "BOLT12 Payment failed: $e";
          }
        },
        lnUrlAuth: (data) async {
          // Already handled via _handleLnUrlAuth dialog
        },
        lnUrlError: (data) => throw "LNUrl Error: ${data.reason}",
        nostrWalletConnectUri: (data) => throw "NWC not supported",
        url: (url) => throw "Unsupported destination",
        nodeId: (nodeId) => throw "Unsupported destination",
      );
    } catch (e) {
      debugPrint("Send Error: $e");
      String errorMsg = e.toString();
      if (errorMsg.contains("InsufficientFunds") || errorMsg.contains("insufficient")) {
        errorMsg = "You don't have enough funds to cover this amount plus the network fee.";
      } else if (errorMsg.contains("invalid digit")) {
        errorMsg = "Please enter a valid number of Satoshis.";
      } else if (errorMsg.contains("below minimum")) {
        // Specifically handle the 25,000 sat limit for Bitcoin L1 swaps
        errorMsg = "The amount is below the minimum required (25,000 sats for Bitcoin on-chain).";
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
            if (_isLnUrlPay || _isLnUrlAuth || _isBolt12) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isLnUrlAuth ? Icons.lock : Icons.bolt, 
                      color: Colors.blueAccent, 
                      size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _isLnUrlAuth 
                        ? "Authentication Request" 
                        : (_isBolt12 ? "BOLT12 Offer Detected" : "Lightning Address Detected"), 
                      style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
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
                helperText: _isLnUrlPay 
                    ? "Min: $_minLnUrlSats sats | Max: $_maxLnUrlSats sats"
                    : (_isBolt12
                        ? "Amount is suggested by the offer"
                        : (_isLightningWithAmount 
                            ? "Amount is fixed by the invoice" 
                            : (_isBitcoinOnchain ? "Note: Minimum 25,000 SAT for Bitcoin on-chain" : null))),
                helperStyle: TextStyle(
                    color: (_isBitcoinOnchain || _isLnUrlPay || _isBolt12) ? Colors.blueAccent : const Color(0xFFBE8345)),
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

  Future<void> _handleLnUrlAuth(LnUrlAuthRequestData data) async {
    final sdk = WalletService().sdk;
    if (sdk == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0E1A2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: Color(0xFFBE8345)),
            SizedBox(width: 10),
            Text("Login Request", style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text("Do you want to login to ${data.domain}?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isSending = true);
              try {
                await sdk.lnurlAuth(reqData: data);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Authenticated successfully!"), backgroundColor: Colors.green),
                  );
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Auth Error: $e"), backgroundColor: Colors.redAccent),
                  );
                }
              } finally {
                if (mounted) setState(() => _isSending = false);
              }
            },
            child: const Text("LOGIN", style: TextStyle(color: Color(0xFFBE8345), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}