import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../../services/wallet_service.dart';
import '../send/send_screen.dart';
import '../send/address_screen.dart';
import '../receive/receive_screen.dart';
import '../settings/settings_screen.dart';
import '../transactions/transactions_screen.dart';
import '../withdraw/withdraw_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver {
  String _btcBalance = "0.00000000";
  String _fiatBalance = "0.00";
  String _fiatCurrency = "ZMW";
  String _bitcoinUnit = "BTC";
  bool _isLoading = true;
  bool _isBalanceHidden = false;
  
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshWallet();
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 120), (timer) {
      _refreshWallet();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _lockApp();
    }
  }

  void _lockApp() {
    Navigator.of(context).pushNamedAndRemoveUntil('/pin', (route) => false);
  }

  Future<void> _loadPreferences() async {
    final fiat = await const FlutterSecureStorage().read(key: 'fiat_currency');
    final btcUnit = await const FlutterSecureStorage().read(key: 'bitcoin_unit');
    final hideBalance = await const FlutterSecureStorage().read(key: 'hide_balance');

    if (mounted) {
      setState(() {
        if (fiat != null) _fiatCurrency = fiat;
        if (btcUnit != null) _bitcoinUnit = btcUnit;
        if (hideBalance != null) _isBalanceHidden = hideBalance == 'true';
      });
    }
  }

  Future<void> _toggleBalanceVisibility() async {
    setState(() {
      _isBalanceHidden = !_isBalanceHidden;
    });
    await const FlutterSecureStorage().write(
      key: 'hide_balance',
      value: _isBalanceHidden.toString(),
    );
  }

  Future<void> _refreshWallet() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final sdk = WalletService().sdk;
      await _loadPreferences();

      if (sdk != null) {
        // Force a manual sync with the network
        try {
          await sdk.syncWallet(request: const SyncWalletRequest());
        } catch (e) {
          debugPrint("Manual Sync Error (ignored): $e");
        }

        // Pulse the network to ensure sync state is reflected in Info
        final info = await sdk.getInfo(request: const GetInfoRequest(ensureSynced: true));
        final BigInt balanceSat = info.balanceSats;
        final double btcValue = balanceSat.toDouble() / 100000000;

        if (mounted) {
          setState(() {
            if (_bitcoinUnit == 'SATS') {
              _btcBalance = balanceSat.toString();
            } else {
              _btcBalance = btcValue.toStringAsFixed(8);
            }

            if (_fiatCurrency == 'USD') {
              _fiatBalance = (btcValue * 65000).toStringAsFixed(2);
            } else {
              _fiatBalance = (btcValue * 1500000).toStringAsFixed(2);
            }
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint("Dashboard Sync Error: $e");
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
              opacity: 0.2,
              child: Image.asset(
                'assets/images/bg_pattern.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: _refreshWallet,
              color: const Color(0xFFBE8345),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          _balanceSection(),
                          const SizedBox(height: 40),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _actionButton(
                                    context: context,
                                    label: "Send",
                                    icon: Icons.call_made,
                                    background: Colors.white,
                                    textColor: const Color(0xFF0E1A2B),
                                    onTap: () async {
                                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const SendScreen()));
                                      _refreshWallet();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _actionButton(
                                    context: context,
                                    label: "Receive",
                                    icon: Icons.call_received,
                                    background: const Color(0xFFBE8345),
                                    textColor: Colors.white,
                                    onTap: () async {
                                      await Navigator.push(context, MaterialPageRoute(builder: (context) => const ReceiveScreen()));
                                      _refreshWallet();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          const Text("Funds Transfer", style: TextStyle(color: Colors.white, fontSize: 16)),
                          const SizedBox(height: 16),
                          _withdrawButton(context),
                          const SizedBox(height: 120), // Extra padding for the floating nav bar
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceSection() {
    final String fiatDisplay = _isBalanceHidden ? "****" : _fiatBalance;
    final String btcDisplay = _isBalanceHidden ? "****" : _btcBalance;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 48), // Spacer to balance the eye icon
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(text: "$fiatDisplay ", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  TextSpan(text: _fiatCurrency, style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                _isBalanceHidden ? Icons.visibility_off : Icons.visibility,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: _toggleBalanceVisibility,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(btcDisplay, style: const TextStyle(color: Colors.white70, fontSize: 23)),
            Text(
              " $_bitcoinUnit", 
              style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)
            ),
          ],
        ),
      ],
    );
  }

  Widget _withdrawButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WithdrawScreen())),
          child: const Text("Mobile Money Wallet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  static Widget _actionButton({required BuildContext context, required String label, required IconData icon, required Color background, required Color textColor, required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: background, 
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
