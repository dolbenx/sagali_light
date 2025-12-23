import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/wallet_service.dart';
import '../dashboard/dashboard_screen.dart';

class VerifyMnemonicScreen extends StatefulWidget {
  final List<String> originalMnemonic;

  const VerifyMnemonicScreen({super.key, required this.originalMnemonic});

  @override
  State<VerifyMnemonicScreen> createState() => _VerifyMnemonicScreenState();
}

class _VerifyMnemonicScreenState extends State<VerifyMnemonicScreen> {
  List<String> _shuffledWords = [];
  final List<String> _selectedWords = [];

  @override
  void initState() {
    super.initState();
    // Create a shuffled copy so the user has to pick them in order
    _shuffledWords = List.from(widget.originalMnemonic)..shuffle();
  }

  /// Handles the BDK Wallet Initialization and Navigation
  void _handleFinishSetup() async {
    // 1. Show Loading Overlay
    _showLoadingOverlay(context);

    try {
      // 2. Initialize the BDK Wallet via our Service
      // We pass the words the user selected (which should be in correct order)
      await WalletService().initializeWallet(_selectedWords);

      if (!mounted) return;

      // 3. Close Loading Overlay
      Navigator.pop(context);

      // 4. Navigate to Dashboard and clear stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (route) => false,
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error creating wallet: $e"), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _showLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFFBE8345)),
              const SizedBox(height: 20),
              const Text("Securing your keys...", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isComplete = _selectedWords.length == widget.originalMnemonic.length;
    bool isCorrect = _selectedWords.join(' ') == widget.originalMnemonic.join(' ');

    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      appBar: AppBar(
        title: const Text("Verify Backup"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              "Tap the words in the correct order (1-24) to verify your backup.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),

          /// SELECTED WORDS AREA
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            // Use BoxConstraints to define the minimum height
              constraints: const BoxConstraints(
              minHeight: 150, 
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isComplete && !isCorrect ? Colors.red : Colors.white10),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedWords.map((word) {
                return InputChip(
                  label: Text(word),
                  onDeleted: () {
                    setState(() {
                      _selectedWords.remove(word);
                      _shuffledWords.add(word);
                    });
                  },
                );
              }).toList(),
            ),
          ),

          if (isComplete && !isCorrect)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text("Words are in the wrong order!", style: TextStyle(color: Colors.red)),
            ),

          const Spacer(),

          /// WORD SELECTION GRID
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _shuffledWords.map((word) {
                return ActionChip(
                  label: Text(word),
                  onPressed: () {
                    setState(() {
                      _selectedWords.add(word);
                      _shuffledWords.remove(word);
                    });
                  },
                );
              }).toList(),
            ),
          ),

          /// FINISH BUTTON
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBE8345),
                  disabledBackgroundColor: Colors.white10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: (isComplete && isCorrect) ? _handleFinishSetup : null,
                child: const Text("FINISH SETUP", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}