import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../main.dart'; // for primaryColor

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String btcAddress = 'bc1qexampleaddress';
  final String lightningAddress = 'lightning:sagali@ln.example.com';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  String get activeAddress =>
      _tabController.index == 0 ? btcAddress : lightningAddress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receive Bitcoin'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // TODO: Implement scan logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Scan QR feature coming soon")),
              );
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Bitcoin'),
            Tab(text: 'Lightning'),
          ],
          onTap: (_) => setState(() {}), // To rebuild QR code when switching tabs
        ),
      ),
        body: Column(
          children: [
            Expanded(
              child: Center(
                child: QrImageView(
                  data: activeAddress,
                  version: QrVersions.auto,
                  size: MediaQuery.of(context).size.width * 0.8, // Responsive size
                  foregroundColor: primaryColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SelectableText(
                    activeAddress,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: activeAddress));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Address copied")),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text("Copy"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Share.share(activeAddress, subject: 'My Bitcoin Address');
                      },
                      icon: const Icon(Icons.share),
                      label: const Text("Share"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
    );
  }
}
