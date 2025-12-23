import 'package:flutter/material.dart';
import 'package:bdk_flutter/bdk_flutter.dart'; // Ensure bdk_flutter is imported
import 'create_mnemonic_screen.dart'; // The screen showing the 24 words
import 'recover_wallet_screen.dart';

class AuthChoiceScreen extends StatelessWidget {
  const AuthChoiceScreen({super.key});

  /// Logic to generate mnemonic and navigate
  Future<void> _handleCreateWallet(BuildContext context) async {
    try {
      // 1. Generate the 24-word mnemonic using BDK
      final mnemonic = await Mnemonic.create(WordCount.Words24);
      final List<String> words = mnemonic.asString().split(' ');

      if (!context.mounted) return;

      // 2. Navigate to the display screen with the generated words
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateMnemonicScreen(generatedWords: words),
        ),
      );
    } catch (e) {
      // Handle potential generation errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating wallet: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      body: Stack(
        children: [
          /// 1. BACKGROUND IMAGE
          Positioned.fill(
            child: Opacity(
              opacity: 0.1, // Adjusted for better visibility of pattern
              child: Image.asset(
                'assets/images/bg_pattern.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// 2. SCREEN CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 100,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const Text(
                    "Welcome to Sagali Wallet",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "The most secure way to manage your Bitcoin",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 60),

                  /// CREATE WALLET BUTTON
                  ElevatedButton(
                    onPressed: () => _handleCreateWallet(context), // Updated trigger
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      backgroundColor: const Color(0xFFBE8345),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "CREATE NEW WALLET",
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1),
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// RECOVER WALLET BUTTON
                  OutlinedButton(
                    onPressed: () {
                      // Navigates to the RecoverWalletScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RecoverWalletScreen(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: Colors.white24),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text("RECOVER EXISTING WALLET"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}