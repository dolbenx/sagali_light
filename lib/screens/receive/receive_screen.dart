import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String btcAddress = 'bc1qexampleaddress1234567890';
  final String lightningAddress = 'lightning:sagali@ln.example.com';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) setState(() {});
    });
  }

  String get activeAddress => _tabController.index == 0 ? btcAddress : lightningAddress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      // Extend the body so the background goes behind the status bar and app bar
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text('Receive', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFBE8345), // Using your primary gold
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'On-Chain'),
            Tab(text: 'Lightning'),
          ],
        ),
      ),
      body: Stack(
        children: [
          /// 1. FIXED BACKGROUND
          /// By using MediaQuery, we ensure it covers the exact screen pixels 
          /// regardless of content scrolling.
          Positioned.fill(
            child: Opacity(
              opacity: 0.4, // Lowered for a cleaner "premium" feel
              child: Image.asset(
                'assets/images/bg_pattern.png', 
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// 2. CONTENT
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    
                    /// QR CARD
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: QrImageView(
                              data: activeAddress,
                              version: QrVersions.auto,
                              size: MediaQuery.of(context).size.width * 0.55,
                              foregroundColor: const Color(0xFF0E1A2B),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _tabController.index == 0 ? "Bitcoin Address" : "Lightning Invoice",
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SelectableText(
                              activeAddress,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40), 

                    Row(
                      children: [
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.copy_all_rounded,
                            label: "Copy",
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: activeAddress));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Address copied to clipboard"),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _ActionButton(
                            icon: Icons.share_rounded,
                            label: "Share",
                            onTap: () => Share.share(activeAddress),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Only send BTC to this address. Sending other assets may result in permanent loss.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white24, fontSize: 11, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.08),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
    );
  }
}