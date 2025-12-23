import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bdk_flutter/bdk_flutter.dart';
import 'dart:ui';
import 'verify_mnemonic_screen.dart';

class CreateMnemonicScreen extends StatefulWidget {
  final List<String> generatedWords; // Receive words from AuthChoiceScreen

  const CreateMnemonicScreen({super.key, required this.generatedWords});

  @override
  State<CreateMnemonicScreen> createState() => _CreateMnemonicScreenState();
}

class _CreateMnemonicScreenState extends State<CreateMnemonicScreen> {
  List<String> _mnemonicWords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generateNewMnemonic();
  }

  // Generate 24 words using BDK
  Future<void> _generateNewMnemonic() async {
    setState(() => _isLoading = true);
    try {
      // BDK default is 12 words; we specify WordCount.Words24
      final mnemonic = await Mnemonic.create(WordCount.Words24);
      setState(() {
        _mnemonicWords = mnemonic.asString().split(' ');
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error generating mnemonic: $e");
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
              child: Image.asset('assets/images/bg_pattern.png', fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFBE8345)))
              : Column(
                  children: [
                    _buildHeader(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            const Icon(Icons.security_rounded, color: Color(0xFFBE8345), size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              "Backup Your Recovery Phrase",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Write down these 24 words in the correct order and keep them offline.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white54, fontSize: 14),
                            ),
                            const SizedBox(height: 32),

                            /// MNEMONIC GRID
                            _buildMnemonicGrid(),

                            const SizedBox(height: 32),
                            _warningBox(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomButton(),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMnemonicGrid() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.2,
        ),
        itemCount: _mnemonicWords.length,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text("${index + 1}", style: const TextStyle(color: Color(0xFFBE8345), fontSize: 10)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _mnemonicWords[index],
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _warningBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.2)),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Never share these words. Anyone with this phrase can steal your Bitcoin.",
              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20)),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _mnemonicWords.join(' ')));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mnemonic copied to clipboard")));
            },
            child: const Text("Copy All", style: TextStyle(color: Color(0xFFBE8345))),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBE8345),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: () {
            // Navigate to the verification screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyMnemonicScreen(
                  originalMnemonic: _mnemonicWords, // Pass the 24 words
                ),
              ),
            );
          },
          child: const Text(
            "I'VE WRITTEN IT DOWN", 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}