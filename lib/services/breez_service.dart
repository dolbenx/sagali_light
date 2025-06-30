// lib/breez_service.dart
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart' as liquid_sdk;

import 'dart:io';

class BreezService {
  static final BreezService _instance = BreezService._internal();

  factory BreezService() => _instance;

  BreezService._internal();

  late liquid_sdk.BindingLiquidSdk breezSDKLiquid;

  Future<void> initBreezSDK({
    required String mnemonic,
    required String breezApiKey,
    required String workingDir,
    bool isMainnet = true,
  }) async {
    final config = liquid_sdk.Config(
      breezApiKey: breezApiKey,
      network: isMainnet ? liquid_sdk.LiquidNetwork.mainnet : liquid_sdk.LiquidNetwork.testnet,
      workingDir: workingDir,
      // CORRECTED: Use liquid_sdk.BlockchainExplorer.esplora
      liquidExplorer: liquid_sdk.BlockchainExplorer.esplora(
        url: 'https://blockstream.info/liquid/api', // Pass the API URL to 'url'
        useWaterfalls: false, // Set to true if you need this feature
      ),
      // CORRECTED: Use liquid_sdk.BlockchainExplorer.esplora
      bitcoinExplorer: liquid_sdk.BlockchainExplorer.esplora(
        url: 'https://blockstream.info/api', // Pass the API URL to 'url'
        useWaterfalls: false, // Set to true if you need this feature
      ),
      paymentTimeoutSec: BigInt.from(60),
      useDefaultExternalInputParsers: true,
    );

    final connectRequest = liquid_sdk.ConnectRequest(
      mnemonic: mnemonic,
      config: config,
    );

    breezSDKLiquid = await liquid_sdk.connect(req: connectRequest);
  }
}