import 'dart:io';
import 'package:ldk_node/ldk_node.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:flutter/foundation.dart';

class LdkService {// 1. Create the static instance
  static final LdkService _instance = LdkService._internal();

  // 2. Factory constructor returns the same instance every time
  factory LdkService() => _instance;

  // 3. Private internal constructor
  LdkService._internal();
  Node? _node;

  Node? get node => _node;

  /// Initialize wallet (create or restore)
  Future<void> initWallet({String? mnemonic}) async {
    final dir = await getApplicationDocumentsDirectory();
    final storagePath = "${dir.path}/ldk_wallet";

    final esploraUrl = "https://mempool.space/testnet/api";

    
    // Generate or restore mnemonic
    final mnemonicString = mnemonic ?? bip39.generateMnemonic();
    final ldkMnemonic = Mnemonic(mnemonicString);

    final config = Config(
      storageDirPath: storagePath,
      network: Network.Testnet,
      listeningAddress: NetAddress.iPv4(addr: "0.0.0.0", port: 3006),
      defaultCltvExpiryDelta: 144,
      onchainWalletSyncIntervalSecs: 60,
      walletSyncIntervalSecs: 20,
      feeRateCacheUpdateIntervalSecs: 600,
      trustedPeers0Conf: [],
      probingLiquidityLimitMultiplier: 3,
      logLevel: LogLevel.Debug,
    );


    final builder = Builder.fromConfig(config: config);

    _node = await builder
        .setEntropyBip39Mnemonic(mnemonic: ldkMnemonic)
        .setEsploraServer(esploraServerUrl: esploraUrl)
        .build();

    try {
      await _node!.start();
      print("Node started ------------------------------");

      await Future.delayed(Duration(seconds: 2));

      await _node!.syncWallets();
      print("Wallet synced ++++++++++++++++++++++++++");
    } catch (e, stack) {
      print("++++++++++++++++++++ Init error: $e");
      print(stack);
    }
  }

  Future<int> getLdkTotalBalance() async {
    if (_node == null) return 0;

    try {
      // 1. Sync the node first
      await _node!.syncWallets();

      // 2. Get On-chain balance (Internal LDK wallet)
      final int onChainSats = await _node!.totalOnchainBalanceSats();

      // 3. Get Lightning balance (Sum of outbound capacity in all channels)
      final List<ChannelDetails> channels = await _node!.listChannels();
      int lightningSats = 0;
      
      for (var channel in channels) {
        // We divide by 1000 because LDK expresses capacity in millisatoshis (msat)
        lightningSats += (channel.outboundCapacityMsat ~/ 1000);
      }

      return onChainSats + lightningSats;
    } catch (e) {
      print("Error retrieving balances: $e");
      return 0;
    }
  }

  // Inside ldk_service.dart
  Future<String?> generateInvoice({
    required int amountSats, 
    required String description,
    int expirySecs = 3600,
  }) async {
    if (_node == null) return null;

    try {
      final amountMsat = amountSats * 1000;

      // 1. Generate the invoice object
      final invoice = await _node!.receivePayment(
        amountMsat: amountMsat,
        description: description,
        expirySecs: expirySecs,
      );

      // 2. Access the encoded string via 'asString'
     return invoice.toString();
    } catch (e) {
      debugPrint("Error generating invoice: $e");
      return null;
    }
  }

  Future<String> createInvoice({
    required int amountSat,
    String? description,
  }) async {
    if (_node == null) throw Exception("LDK Node not initialized");

    // LDK works in Millisatoshis
    final int amountMsat = amountSat * 1000;
    
    // Generate the invoice object
    final invoice = await _node!.receivePayment(
      amountMsat: amountMsat,
      description: (description != null && description.trim().isNotEmpty)
          ? description
          : 'Sagali Fixed Payment',
      expirySecs: 10000,
    );

    // Return the raw 'lnbc...' string using .internal
    return invoice.internal;
  }

  /// 2. Create a Zero-Sat (Variable Amount) BOLT11 Invoice
  Future<String> createZeroSatInvoice({String? description}) async {
    if (_node == null) throw Exception("LDK Node not initialized");

    // 1. Get the PublicKey object (Don't convert it to String yet!)
    final PublicKey myNodeIdObject = await _node!.nodeId();

    // 2. Pass the object directly into the nodeId parameter
    final invoice = await _node!.receiveVariableAmountPayment(
      nodeId: myNodeIdObject, // Pass the object here
      description: (description != null && description.trim().isNotEmpty)
          ? description
          : 'Sagali Flexible Payment',
      expirySecs: 10000,
    );

    // 3. Return the raw 'lnbc...' string from the resulting invoice
    return invoice.internal;
  }

  /// Sends a payment for a BOLT11 invoice that has an amount baked in
  Future<void> sendPayment(String invoiceHash) async {
    if (_node == null) throw Exception("LDK Node not initialized");

    // Wrap the raw string into the required Bolt11Invoice object
    final invoice = Bolt11Invoice(internal: invoiceHash);

    // Execute the payment
    await _node!.sendPayment(invoice: invoice);
  }

  /// Sends a payment for a "Zero-Amount" invoice by specifying the sats
  Future<void> sendPaymentWithAmount(String invoiceHash, int amountSats) async {
    if (_node == null) throw Exception("LDK Node not initialized");

    final invoice = Bolt11Invoice(internal: invoiceHash);

    // LDK expects Millisatoshis (sats * 1000)
    await _node!.sendPaymentUsingAmount(
      invoice: invoice,
      amountMsat: amountSats * 1000,
    );
  }

  /// List channels
  Future<List<ChannelDetails>> getChannels() async {
    return await _node!.listChannels();
  }

  /// Stop node
  Future<void> stop() async {
    await _node?.stop();
  }
}