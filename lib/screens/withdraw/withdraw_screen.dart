import 'package:flutter/material.dart';
import 'dart:ui';
import 'withdraw_input_screen.dart'; // Adjust path

class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});

  final Color primaryGold = const Color(0xFFBE8345);
  final Color bgColor = const Color(0xFF0E1A2B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      // We wrap everything in a SizedBox to ensure the Stack fills the screen
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        child: Stack(
          children: [
            /// 1. BACKGROUND PATTERN (Fixed and covering the whole screen)
            Positioned.fill(
              child: Opacity(
                opacity: 0.1, // Increased slightly for visibility
                child: Image.asset(
                  'assets/images/bg_pattern.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            /// 2. CONTENT LAYER
            SafeArea(
              bottom: false, // Allows background to reach the very bottom
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(context),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    child: Text(
                      "Select a network to withdraw funds",
                      style: TextStyle(
                        color: Colors.white54, 
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 10),

                  /// SCROLLABLE LIST OF OPTIONS
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav or padding
                      child: Column(
                        children: [
                          _withdrawActionOption(
                            label: 'Airtel Money',
                            imagePath: 'assets/images/airtel.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WithdrawInputScreen(
                                    networkName: 'Airtel Money',
                                    imagePath: 'assets/images/airtel.png',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          _withdrawActionOption(
                            label: 'MTN MoMo',
                            imagePath: 'assets/images/mtn.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WithdrawInputScreen(
                                    networkName: 'MTN MoMo',
                                    imagePath: 'assets/images/mtn.png',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          _withdrawActionOption(
                            label: 'Zamtel Kwacha',
                            imagePath: 'assets/images/zamtel.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WithdrawInputScreen(
                                    networkName: 'Zamtel Kwacha',
                                    imagePath: 'assets/images/zamtel.png',
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 14),
                          _withdrawActionOption(
                            label: 'Zed Mobile',
                            imagePath: 'assets/images/zedmobile.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const WithdrawInputScreen(
                                    networkName: 'Zed Mobile',
                                    imagePath: 'assets/images/zedmobile.png',
                                  ),
                                ),
                              );
                            },
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
      ),
    );
  }

  /// Custom Header with Back Button
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Withdraw',
            style: TextStyle(
              color: Colors.white, 
              fontSize: 24, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  /// Withdraw Option Item
  Widget _withdrawActionOption({
    required String label,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: double.infinity,
            height: 65, // Comfortable height
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Logo Circle
                  Container(
                    padding: const EdgeInsets.all(6),
                    height: 40,
                    width: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      imagePath, 
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Label
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios, 
                    color: Colors.white24, 
                    size: 16
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleWithdraw(BuildContext context, String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Processing withdrawal for $provider'),
        backgroundColor: primaryGold,
      ),
    );
  }
}