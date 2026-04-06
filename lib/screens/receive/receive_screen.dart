import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/wallet_service.dart';

class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  String btcAddress = 'Loading...'; 
  bool _isLoadingBtc = true;

  String lightningInvoice = ''; 
  bool _isLoadingLn = false;
  
  bool _isFixedAmount = false;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchBtcAddress();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index == 1 && lightningInvoice.isEmpty && !_isLoadingLn) {
        _generateLnInvoice(0);
      }
      if (mounted) setState(() {}); 
    });
  }

  Future<void> _fetchBtcAddress() async {
    try {
      final address = await WalletService().getNewAddress();
      setState(() {
        btcAddress = address;
        _isLoadingBtc = false;
      });
    } catch (e) {
      setState(() {
        btcAddress = "Error loading address";
        _isLoadingBtc = false;
      });
    }
  }

  Future<void> _generateLnInvoice(int sats) async {
    setState(() {
      _isLoadingLn = true;
      _isFixedAmount = sats > 0;
    });
    
    try {
      // Adapted to use WalletService (Breez Liquid SDK)
      final invoice = await WalletService().getLightningInvoice(BigInt.from(sats));
      
      setState(() {
        lightningInvoice = invoice;
        _isLoadingLn = false;
      });
    } catch (e) {
      setState(() => _isLoadingLn = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Breez Error: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  String get activeAddress {
    if (_tabController.index == 0) return btcAddress;
    return lightningInvoice.isEmpty ? "Generating..." : lightningInvoice;
  }

  String _cleanAddress(String address) {
    if (address.startsWith('bitcoin:')) {
      return address.split(':').last.split('?').first;
    }
    if (address.startsWith('lightning:')) {
      return address.split(':').last.split('?').first;
    }
    return address;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: const Text('Receive', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFBE8345),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'Bitcoin'),
            Tab(text: 'Lightning'),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('assets/images/bg_pattern.png', fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container()),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: _buildQrSection(),
                                    ),
                                    const SizedBox(height: 24),
                                    Text(
                                      _tabController.index == 0 
                                          ? "Bitcoin Address" 
                                          : "Lightning Invoice",
                                      style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildAddressText(),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),
                              
                              if (_tabController.index == 1) ...[
                                _ActionButton(
                                  icon: Icons.edit_note_rounded,
                                  label: "Set Specific Amount",
                                  onTap: _showAmountSheet,
                                ),
                                const SizedBox(height: 16),
                              ],

                              Row(
                                children: [
                                  Expanded(
                                    child: _ActionButton(
                                      icon: Icons.copy_all_rounded,
                                      label: "Copy",
                                      onTap: () {
                                        final textToCopy = _cleanAddress(activeAddress);
                                        Clipboard.setData(ClipboardData(text: textToCopy));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text("Copied to clipboard"), behavior: SnackBarBehavior.floating),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _ActionButton(
                                      icon: Icons.share_rounded,
                                      label: "Share",
                                      onTap: () => Share.share(_cleanAddress(activeAddress)),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const SizedBox(height: 24),
                              const Text(
                                "Payments sent to the Lightning invoice are nearly instant. Bitcoin transactions require a little bit more time.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white24, fontSize: 11),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    bool loading = (_tabController.index == 0 && _isLoadingBtc) || (_tabController.index == 1 && _isLoadingLn);
    final qrSize = MediaQuery.of(context).size.width * 0.55;
    
    if (loading) {
      return SizedBox(
        width: qrSize, 
        height: qrSize, 
        child: const Center(child: CircularProgressIndicator(color: Color(0xFFBE8345)))
      );
    }
    return QrImageView(
      data: activeAddress,
      version: QrVersions.auto,
      size: qrSize,
      foregroundColor: const Color(0xFF0E1A2B),
    );
  }

  Widget _buildAddressText() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: SelectableText(
        _cleanAddress(activeAddress),
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 11),
      ),
    );
  }

  void _showAmountSheet() {
    _amountController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0E1A2B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Set Amount",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Generate invoice with a specific amount.",
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      hintText: "0",
                      hintStyle: TextStyle(color: Colors.white10),
                      suffixText: "SATS",
                      suffixStyle: TextStyle(
                        color: Color(0xFFBE8345),
                        fontWeight: FontWeight.bold,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.white10),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFFBE8345)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      final sats = int.tryParse(_amountController.text) ?? 0;
                      if (sats > 0) {
                        Navigator.pop(context);
                        _generateLnInvoice(sats);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBE8345),
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "GENERATE INVOICE",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.08),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}