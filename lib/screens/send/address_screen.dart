import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bdk_flutter/bdk_flutter.dart' as bdk; // Import BDK
import 'confirm_send_screen.dart'; // Import your confirm screen

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final TextEditingController _controller = TextEditingController();
  final Color primaryGold = const Color(0xFFBE8345);
  bool _isValidating = false;

  // 1. BIP21 CLEANER Helper
  String _cleanAddress(String input) {
    String clean = input.trim();
    if (clean.toLowerCase().startsWith("bitcoin:")) {
      clean = clean.substring(8);
    }
    if (clean.contains("?")) {
      clean = clean.split("?")[0];
    }
    return clean;
  }

  // 2. VALIDATION & NAVIGATION LOGIC
  Future<void> _handleContinue() async {
    final rawInput = _controller.text.trim();
    if (rawInput.isEmpty) return;

    setState(() => _isValidating = true);

    try {
      final cleanAddr = _cleanAddress(rawInput);

      // Verify if the address is valid for the network
      // This catches the "Base58/Bech32 encoding error" here instead of the next screen
      await bdk.Address.create(address: cleanAddr);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmSendScreen(recipientAddress: cleanAddr),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Invalid Bitcoin Address: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isValidating = false);
    }
  }

  Future<void> _pasteFromClipboard() async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null) {
      setState(() {
        _controller.text = data.text ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/bg_pattern.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Lightning Invoice or BTC Address",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withOpacity(0.1)),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _controller,
                                maxLines: 5,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.all(20),
                                  border: InputBorder.none,
                                  hintText: 'Paste or type address here...',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _pasteFromClipboard,
                                  icon: Icon(Icons.content_paste, size: 16, color: primaryGold),
                                  label: Text(
                                    "Paste from clipboard",
                                    style: TextStyle(color: primaryGold, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: primaryGold, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "Ensure the address is correct. Transactions are irreversible.",
                                style: TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 50),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isValidating ? null : _handleContinue,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGold,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: _isValidating
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'CONTINUE',
                                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Enter Address',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}