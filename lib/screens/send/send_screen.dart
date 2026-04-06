import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'address_screen.dart';
import 'confirm_send_screen.dart';

class SendScreen extends StatefulWidget {
  const SendScreen({super.key});

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
  final MobileScannerController scannerController = MobileScannerController();
  String? scannedData;
  bool isNavigationInProgress = false;

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
    scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (isNavigationInProgress) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code != null) {
        setState(() {
          isNavigationInProgress = true;
          scannedData = code;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmSendScreen(recipientAddress: code),
          ),
        ).then((_) {
          setState(() {
            isNavigationInProgress = false;
          });
        });
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanWindowSize = size.width * 0.75;
    
    // Position the window slightly above center for better ergonomics
    final scanWindow = Rect.fromLTWH(
      (size.width - scanWindowSize) / 2,
      (size.height - scanWindowSize) / 2 - 50, 
      scanWindowSize,
      scanWindowSize,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          /// 1. FULL SCREEN SCANNER
          Positioned.fill(
            child: MobileScanner(
              controller: scannerController,
              onDetect: _onDetect,
              scanWindow: scanWindow,
            ),
          ),

          /// 2. FULL SCREEN DARK OVERLAY WITH HOLE
          Positioned.fill(
            child: CustomPaint(
              painter: ScannerOverlayPainter(scanWindow: scanWindow),
            ),
          ),

          /// 3. SCAN WINDOW BORDER
          Positioned(
            left: scanWindow.left,
            top: scanWindow.top,
            child: Container(
              width: scanWindow.width,
              height: scanWindow.height,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFBE8345), width: 2), // Gold border
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          /// 4. FLOATING HEADER (App Bar Equivalent)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text(
                  'Send Sats',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                ValueListenableBuilder(
                  valueListenable: scannerController,
                  builder: (context, state, child) {
                    final flashState = state.torchState;
                    final flashOn = flashState == TorchState.on;
                    return IconButton(
                      icon: Icon(
                        flashOn ? Icons.flash_on : Icons.flash_off,
                        color: flashOn ? Colors.yellow : Colors.white70,
                      ),
                      onPressed: () => scannerController.toggleTorch(),
                    );
                  },
                ),
              ],
            ),
          ),

          /// 5. INSTRUCTIONS
          Positioned(
            top: scanWindow.top - 40,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "Scan Recipient's QR Code",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ),
          ),

          /// 6. FLOATING FOOTER (Glassmorphism Paste Button)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 30,
            left: 30,
            right: 30,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.paste_rounded, size: 20),
                        label: const Text("Paste Invoice / Address"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddressScreen()),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Position the QR code within the frame",
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  ScannerOverlayPainter({required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addRRect(RRect.fromRectAndRadius(scanWindow, const Radius.circular(20)));
    final path = Path.combine(PathOperation.difference, backgroundPath, holePath);
    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.5));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}