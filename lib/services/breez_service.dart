// lib/services/breez_service.dart
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;
import 'package:path_provider/path_provider.dart';
import 'package:bip39/bip39.dart' as bip39; // Import bip39 here
import 'dart:io';

class BreezService {
  static final BreezService _instance = BreezService._internal();

  factory BreezService() => _instance;

  BreezService._internal();

  late liquid_sdk.BindingLiquidSdk breezSDKLiquid;

  // No parameters needed for initBreezSDK anymore, as it will handle them internally
  Future<void> initBreezSDK() async {
    try {
      // 1. Initialize liquid_sdk (which might also perform some internal Rust bridge setup)
      // We keep this here as it's part of the liquid_sdk's own initialization flow.
      // However, note that the explicit RustLib.init() is *still* needed in main.dart
      // as the very first bridge initialization.
      await liquid_sdk.initialize();
      print("Breez Liquid SDK initialized internally.");

      // 2. Generate Mnemonic (or retrieve securely)
      final mnemonic = bip39.generateMnemonic(strength: 256);
      print("-----------Generated Mnemonic----------$mnemonic");

      // 3. Define API Key
      const String API_KEY = 'MIIBbzCCASGgAwIBAgIHPgc3izOVkzAFBgMrZXAwEDEOMAwGA1UEAxMFQnJlZXowHhcNMjUwNDI5MTQ0NjMyWhcNMzUwNDI3MTQ0NjMyWjApMRYwFAYDVQQKEw1TZWxmIEVtcGxveWVkMQ8wDQYDVQQDEwZEYXZpZXMwKjAFBgMrZXADIQDQg/XL3yA8HKIgyimHU/Qbpxy0tvzris1fDUtEs6ldd6OBgDB+MA4GA1UdDwEB/wQEAwIFoDAMBgNVHRMBAf8EAjAAMB0GA1UdDgQWBBTaOaPuXmtLDTJVv++VYBiQr9gHCTAfBgNVHSMEGDAWgBTeqtaSVvON53SSFvxMtiCyayiYazAeBgNVHREEFzAVgRNkb2xiZW44MDBAZ21haWwuY29tMAUGAytlcANBAEqOtvtp1I4Rx/QgM7uI/et7GcSxRpYJ3UIpkzAxfMes4ffL5crjmgC3KK0ScolI7kx7u4Frb85DYfE3zgw8CQY=';

      // 4. Define Working Directory
      final appDocumentDir = await getApplicationDocumentsDirectory();
      final workingDir = "${appDocumentDir.path}/breez_liquid_sdk";

      // 5. Configure Breez Liquid SDK
      final config = liquid_sdk.Config(
        breezApiKey: API_KEY,
        network: liquid_sdk.LiquidNetwork.testnet, // Use LiquidNetwork.mainnet for mainnet
        workingDir: workingDir,
        liquidExplorer: liquid_sdk.BlockchainExplorer.esplora(
          url: 'https://blockstream.info/liquid/api',
          useWaterfalls: false,
        ),
        bitcoinExplorer: liquid_sdk.BlockchainExplorer.esplora(
          url: 'https://blockstream.info/api',
          useWaterfalls: false,
        ),
        paymentTimeoutSec: BigInt.from(60),
        useDefaultExternalInputParsers: true,
      );

      // 6. Connect to Breez Liquid SDK
      final connectRequest = liquid_sdk.ConnectRequest(
        mnemonic: mnemonic,
        config: config,
      );

      breezSDKLiquid = await liquid_sdk.connect(req: connectRequest);
      print("Breez Liquid SDK connected successfully!");

    } catch (e) {
      print("Error during BreezService.initBreezSDK: $e");
      rethrow; // Re-throw the error so main can catch it
    }
  }
}