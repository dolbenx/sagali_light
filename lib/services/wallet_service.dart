import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class WalletService {
  // Singleton pattern
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  BreezSdkLiquid? _sdk;
  final _storage = const FlutterSecureStorage();
  final String _mnemonicKey = 'sagali_mnemonic_phrase';
  final String _pinKey = "user_pin";

  BreezSdkLiquid? get sdk => _sdk;

  /// AUTO-LOGIN: Checks if a mnemonic is saved and initializes
  Future<bool> tryAutoLogin() async {
    try {
      String? savedMnemonic = await _storage.read(key: _mnemonicKey);
      if (savedMnemonic != null && savedMnemonic.trim().isNotEmpty) {
        debugPrint("Found saved mnemonic, logging in...");
        await initializeWallet(savedMnemonic.trim().split(' '));
        return true;
      }
    } catch (e) {
      debugPrint("Auto-login error: $e");
    }
    return false;
  }

  /// INITIALIZE / RECOVER: Creates the wallet and saves it for future logins
  Future<String> initializeWallet(List<String> words) async {
    try {
      final mnemonic = words.join(' ');

      final directory = await getApplicationDocumentsDirectory();
      final workingDir = Directory('${directory.path}/breez_liquid');
      if (!workingDir.existsSync()) {
        workingDir.createSync(recursive: true);
      }

      // Ensure we use Mainnet by default
      final defaultC = defaultConfig(network: LiquidNetwork.mainnet);
      
      final config = Config(
        liquidExplorer: defaultC.liquidExplorer,
        bitcoinExplorer: defaultC.bitcoinExplorer,
        workingDir: workingDir.path,
        network: LiquidNetwork.mainnet, // FORCE MAINNET
        paymentTimeoutSec: defaultC.paymentTimeoutSec,
        syncServiceUrl: defaultC.syncServiceUrl,
        zeroConfMaxAmountSat: defaultC.zeroConfMaxAmountSat,
        breezApiKey: 'MIIBbzCCASGgAwIBAgIHPgc3izOVkzAFBgMrZXAwEDEOMAwGA1UEAxMFQnJlZXowHhcNMjUwNDI5MTQ1MjQ5WhcNMzUwNDI3MTQ1MjQ5WjApMRYwFAYDVQQKEw1TZWxmIEVtcGxveWVkMQ8wDQYDVQQDEwZEYXZpZXMwKjAFBgMrZXADIQDQg/XL3yA8HKIgyimHU/Qbpxy0tvzris1fDUtEs6ldd6OBgDB+MA4GA1UdDwEB/wQEAwIFoDAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTaOaPuXmtLDTJVv++VYBiQr9gHCTAfBgNVHSMEGDAWgBTeqtaSVvON53SSFvxMtiCyayiYazAeBgNVHREEFzAVgRNkb2xiZW44MDBAZ21haWwuY29tMAUGAytlcANBAEqOtvtp1I4Rx/QgM7uI/et7GcSxRpYJ3UIpkzAxfMes4ffL5crjmgC3KK0ScolI7kx7u4Frb85DYfE3zgw8CQY=',
        externalInputParsers: defaultC.externalInputParsers,
        useDefaultExternalInputParsers: defaultC.useDefaultExternalInputParsers,
        onchainFeeRateLeewaySat: defaultC.onchainFeeRateLeewaySat,
        assetMetadata: defaultC.assetMetadata,
        sideswapApiKey: defaultC.sideswapApiKey,
        useMagicRoutingHints: defaultC.useMagicRoutingHints,
        onchainSyncPeriodSec: defaultC.onchainSyncPeriodSec,
        onchainSyncRequestTimeoutSec: defaultC.onchainSyncRequestTimeoutSec,
      );

      final req = ConnectRequest(config: config, mnemonic: mnemonic);
      
      try {
        _sdk = await connect(req: req);
      } catch (e) {
        // If it fails with a network mismatch, try to clear the working directory and retry once
        if (e.toString().contains("networkNotSupported") || e.toString().contains("NetworkMismatch")) {
          debugPrint("Network mismatch detected. Clearing directory and retrying...");
          if (workingDir.existsSync()) {
            workingDir.deleteSync(recursive: true);
            workingDir.createSync(recursive: true);
          }
          _sdk = await connect(req: req);
        } else {
          rethrow;
        }
      }

      // SECURE STORAGE: Save the phrase for Login persistence
      await _storage.write(key: _mnemonicKey, value: mnemonic);

      final walletInfo = await _sdk!.getInfo();
      debugPrint("Wallet Active. Pubkey: ${walletInfo.walletInfo.pubkey}");
      
      // Return a Liquid address as the default
      return await getNewAddress();
    } catch (e) {
      debugPrint("Breez Liquid Initialization Error: $e");
      rethrow;
    }
  }

  /// SYNC: Connects to the network to update balance and tx history
  Future<void> syncWallet() async {
    if (_sdk == null) return;
    try {
      await _sdk!.sync();
      debugPrint("Sync Successful");
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

   Future<List<Payment>> getOnChainTransactions() async {
    if (_sdk == null) return [];

    try {
      // Empty request gets all payments
      final transactions = await _sdk!.listPayments(req: const ListPaymentsRequest());

      var modifiableList = List<Payment>.from(transactions);
      modifiableList.sort((a, b) {
        final aTime = a.timestamp;
        final bTime = b.timestamp;
        return bTime.compareTo(aTime);
      });

      return modifiableList;
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
      return [];
    }
  }

  /// GET LIQUID ADDRESS: Used by ReceiveScreen
  Future<String> getNewAddress() async {
    if (_sdk == null) throw Exception("Wallet not initialized");
    final reqReceive = PrepareReceiveRequest(paymentMethod: PaymentMethod.bitcoinAddress);
    final receiveRes = await _sdk!.prepareReceivePayment(req: reqReceive);
    final finalRes = await _sdk!.receivePayment(req: ReceivePaymentRequest(prepareResponse: receiveRes));
    return finalRes.destination;
  }

  /// GET LIQUID ADDRESS: Used by ReceiveScreen for direct L-BTC
  Future<String> getLiquidAddress() async {
    if (_sdk == null) throw Exception("Wallet not initialized");
    final reqReceive = PrepareReceiveRequest(paymentMethod: PaymentMethod.liquidAddress);
    final receiveRes = await _sdk!.prepareReceivePayment(req: reqReceive);
    final finalRes = await _sdk!.receivePayment(req: ReceivePaymentRequest(prepareResponse: receiveRes));
    return finalRes.destination;
  }

  /// GET LIGHTNING INVOICE: Used by ReceiveScreen
  Future<String> getLightningInvoice(BigInt amountSats, {String? description}) async {
    if (_sdk == null) throw Exception("Wallet not initialized");
    
    final effectiveAmount = amountSats > BigInt.zero ? amountSats : BigInt.from(1000); 
    
    final reqReceive = PrepareReceiveRequest(
      paymentMethod: PaymentMethod.bolt11Invoice,
      amount: ReceiveAmount.bitcoin(payerAmountSat: effectiveAmount),
    );
    
    final receiveRes = await _sdk!.prepareReceivePayment(req: reqReceive);
    final finalRes = await _sdk!.receivePayment(req: ReceivePaymentRequest(
      prepareResponse: receiveRes,
      description: description,
    ));
    
    return finalRes.destination;
  }

  /// GET BOLT12 OFFER: Static payment address
  Future<String> getBolt12Offer({String? description}) async {
    if (_sdk == null) throw Exception("Wallet not initialized");
    
    final reqReceive = PrepareReceiveRequest(
      paymentMethod: PaymentMethod.bolt12Offer,
    );
    
    final receiveRes = await _sdk!.prepareReceivePayment(req: reqReceive);
    final finalRes = await _sdk!.receivePayment(req: ReceivePaymentRequest(
      prepareResponse: receiveRes,
      description: description,
    ));
    
    return finalRes.destination;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<String?> getMnemonic() async {
    return await _storage.read(key: _mnemonicKey);
  }

  /// LOGOUT: Deletes the stored key so the user has to re-enter words or create new
  Future<void> logout() async {
    await _storage.delete(key: _mnemonicKey);
    if (_sdk != null) {
      await _sdk!.disconnect();
    }
    _sdk = null;
  }
}
