import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:breez_sdk_spark_flutter/breez_sdk_spark.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class WalletService {
  // Singleton pattern
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  BreezSdk? _sdk;
  final _storage = const FlutterSecureStorage();
  final String _mnemonicKey = 'sagali_mnemonic_phrase';
  final String _pinKey = "user_pin";

  BreezSdk? get sdk => _sdk;

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

  /// INITIALIZE / RECOVER: Creates the Spark wallet and saves it for future logins
  Future<String> initializeWallet(List<String> words) async {
    try {
      final mnemonic = words.join(' ');

      final directory = await getApplicationDocumentsDirectory();
      final storageDir = Directory('${directory.path}/breez_spark');
      if (!storageDir.existsSync()) {
        storageDir.createSync(recursive: true);
      }

      // Build seed from mnemonic
      final seed = Seed.mnemonic(mnemonic: mnemonic, passphrase: null);

      // Build config
      final config = defaultConfig(network: Network.mainnet).copyWith(
        apiKey:
            'MIIBbzCCASGgAwIBAgIHPgc3izOVkzAFBgMrZXAwEDEOMAwGA1UEAxMFQnJlZXowHhcNMjUwNDI5MTQ1MjQ5WhcNMzUwNDI3MTQ1MjQ5WjApMRYwFAYDVQQKEw1TZWxmIEVtcGxveWVkMQ8wDQYDVQQDEwZEYXZpZXMwKjAFBgMrZXADIQDQg/XL3yA8HKIgyimHU/Qbpxy0tvzris1fDUtEs6ldd6OBgDB+MA4GA1UdDwEB/wQEAwIFoDAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTaOaPuXmtLDTJVv++VYBiQr9gHCTAfBgNVHSMEGDAWgBTeqtaSVvON53SSFvxMtiCyayiYazAeBgNVHREEFzAVgRNkb2xiZW44MDBAZ21haWwuY29tMAUGAytlcANBAEqOtvtp1I4Rx/QgM7uI/et7GcSxRpYJ3UIpkzAxfMes4ffL5crjmgC3KK0ScolI7kx7u4Frb85DYfE3zgw8CQY=',
      );

      final connectRequest = ConnectRequest(
        config: config,
        seed: seed,
        storageDir: storageDir.path,
      );

      _sdk = await connect(request: connectRequest);
      
      try {
        final status = await getSparkStatus();
        debugPrint("Spark Service Status: ${status.status.name}");
      } catch (e) {
        debugPrint("Spark Status Check Error: $e");
      }
      // Save mnemonic for future auto-login
      await _storage.write(key: _mnemonicKey, value: mnemonic);

      final info = await _sdk!.getInfo(request: const GetInfoRequest(ensureSynced: true));
      debugPrint("Spark Wallet Active. Identity: ${info.identityPubkey}");
      debugPrint("Spark Balance: ${info.balanceSats} sats");

      // Return a Bitcoin address as the default receive address
      return await getNewAddress();
    } catch (e) {
      debugPrint("Breez Spark Initialization Error: $e");
      rethrow;
    }
  }

  /// SYNC: Spark SDK syncs automatically, but we can force a sync
  Future<void> syncWallet() async {
    if (_sdk == null) return;
    try {
      await _sdk!.syncWallet(request: const SyncWalletRequest());
      debugPrint("Sync Successful");
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

  /// LIST PAYMENTS (returns all sent + received)
  Future<List<Payment>> getOnChainTransactions() async {
    if (_sdk == null) return [];

    try {
      final response = await _sdk!.listPayments(request: const ListPaymentsRequest());
      final payments = List<Payment>.from(response.payments);
      // Sort newest first
      payments.sort((a, b) {
        final aTime = a.timestamp;
        final bTime = b.timestamp;
        return bTime.compareTo(aTime);
      });
      return payments;
    } catch (e) {
      debugPrint("Error fetching transactions: $e");
      return [];
    }
  }

  /// GET BITCOIN ADDRESS: Used by ReceiveScreen for on-chain receives
  Future<String> getNewAddress() async {
    if (_sdk == null) throw Exception("Wallet not initialized");
    final response = await _sdk!.receivePayment(
      request: const ReceivePaymentRequest(
        paymentMethod: ReceivePaymentMethod.bitcoinAddress(),
      ),
    );
    return response.paymentRequest;
  }

  /// GET SPARK ADDRESS: Instant Spark-to-Spark transfers (static address)
  Future<String> getSparkAddress() async {
    if (_sdk == null) throw Exception("Wallet not initialized");
    final response = await _sdk!.receivePayment(
      request: const ReceivePaymentRequest(
        paymentMethod: ReceivePaymentMethod.sparkAddress(),
      ),
    );
    return response.paymentRequest;
  }

  /// GET LIGHTNING INVOICE (BOLT11): Used by ReceiveScreen
  Future<String> getLightningInvoice(BigInt amountSats,
      {String? description}) async {
    if (_sdk == null) throw Exception("Wallet not initialized");

    final BigInt? invoiceAmount =
        amountSats > BigInt.zero ? amountSats : null;

    final response = await _sdk!.receivePayment(
      request: ReceivePaymentRequest(
        paymentMethod: ReceivePaymentMethod.bolt11Invoice(
          description: description ?? '',
          amountSats: invoiceAmount,
          expirySecs: 3600,
          paymentHash: null,
        ),
      ),
    );
    return response.paymentRequest;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<String?> getMnemonic() async {
    return await _storage.read(key: _mnemonicKey);
  }

  /// LOGOUT: Deletes the stored key
  Future<void> logout() async {
    await _storage.delete(key: _mnemonicKey);
    if (_sdk != null) {
      await _sdk!.disconnect();
    }
    _sdk = null;
  }
}
