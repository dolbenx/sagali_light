import 'package:flutter/material.dart';
import '../../services/wallet_service.dart';
import '../dashboard/dashboard_screen.dart';
import 'pin_setup_screen.dart';

class RecoverWalletScreen extends StatefulWidget {
  const RecoverWalletScreen({super.key});

  @override
  State<RecoverWalletScreen> createState() => _RecoverWalletScreenState();
}

class _RecoverWalletScreenState extends State<RecoverWalletScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  void _handleRecovery() async {
    final input = _controller.text.trim().toLowerCase();
    final words = input.split(RegExp(r'\s+')); // Splits by any whitespace

    if (words.length != 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter exactly 24 words")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // BDK math handles the rest. If the words are correct, 
      // the same addresses will be generated.
      await WalletService().initializeWallet(words);

      if (!mounted) return;
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid Mnemonic: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      appBar: AppBar(title: const Text("Recover Wallet"), backgroundColor: Colors.transparent),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              "Enter your 24-word recovery phrase to restore your Sagali wallet.",
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "word1 word2 word3...",
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFBE8345)),
                onPressed: _isLoading ? null : _handleRecovery,
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text("RESTORE WALLET"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}