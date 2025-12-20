import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'address_screen.dart';
import '../../../main.dart'; // For primaryColor

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? scannedData;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status != PermissionStatus.granted) {
      // Logic for denied permission
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        scannedData = scanData.code;
      });
      controller.pauseCamera();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      appBar: AppBar(
        title: const Text('Send Sats', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent, // Blends better with dark theme
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          /// 1. BACKGROUND PATTERN
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('assets/images/bg_pattern.png', fit: BoxFit.cover),
            ),
          ),

          /// 2. MAIN CONTENT
          Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Scan recipient's QR code",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 30),

              /// 3. SCANNER WITH CUSTOM OVERLAY
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                      overlay: QrScannerOverlayShape(
                        borderColor: Colors.blueAccent,
                        borderRadius: 20,
                        borderLength: 40,
                        borderWidth: 10,
                        cutOutSize: 250, // Size of the transparent box
                      ),
                    ),
                  ),
                ),
              ),

              /// 4. BOTTOM ACTION AREA
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (scannedData != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Address: $scannedData',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      ElevatedButton.icon(
                        icon: const Icon(Icons.paste_rounded, size: 20),
                        label: const Text("Paste Invoice / Address"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.1),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddressScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Position the QR code within the frame",
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}