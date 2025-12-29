import 'package:bdk_flutter/bdk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WalletService {
  // Singleton pattern
  static final WalletService _instance = WalletService._internal();
  factory WalletService() => _instance;
  WalletService._internal();

  Wallet? _wallet;
  final _storage = const FlutterSecureStorage();
  final String _mnemonicKey = 'sagali_mnemonic_phrase';
  final String _pinKey = "user_pin";

  Wallet? get wallet => _wallet;
  Blockchain? _blockchain;

  /// AUTO-LOGIN: Checks if a mnemonic is saved and initializes BDK
  Future<bool> tryAutoLogin() async {
    try {
      String? savedMnemonic = await _storage.read(key: _mnemonicKey);
      if (savedMnemonic != null && savedMnemonic.isNotEmpty) {
        debugPrint("Found saved mnemonic, logging in...");
        await initializeWallet(savedMnemonic.split(' '));
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
      // 1. Create the Mnemonic object
      final mnemonic = await Mnemonic.fromString(words.join(' '));

      // 2. Generate the Descriptor Secret Key
      final descriptorSecretKey = await DescriptorSecretKey.create(
        network: Network.Testnet,
        mnemonic: mnemonic,
      );

      // 3. Create a SegWit (BIP84) External Descriptor
      final externalDescriptor = await Descriptor.newBip84(
        secretKey: descriptorSecretKey,
        network: Network.Testnet,
        keychain: KeychainKind.External,
      );

      // 4. Create the Wallet instance
      _wallet = await Wallet.create(
        descriptor: externalDescriptor,
        network: Network.Testnet,
        databaseConfig: const DatabaseConfig.memory(),
      );

      // 5. SECURE STORAGE: Save the phrase for Login persistence
      await _storage.write(key: _mnemonicKey, value: words.join(' '));

      final addressInfo = await _wallet!.getAddress(
        addressIndex: const AddressIndex.lastUnused(),
      );

      debugPrint("Wallet Active. Address: ${addressInfo.address}");
      return addressInfo.address;
    } catch (e) {
      debugPrint("BDK Initialization Error: $e");
      rethrow;
    }
  }

  /// RECOVERY HELPER: Just an alias for initializeWallet for code clarity
  Future<String> recoverWallet(List<String> words) async {
    return await initializeWallet(words);
  }

  /// GET NEW ADDRESS: Used by ReceiveScreen
  Future<String> getNewAddress() async {
    if (_wallet == null) throw Exception("Wallet not initialized");
    final addressInfo = await _wallet!.getAddress(
      addressIndex: const AddressIndex.lastUnused(),
    );
    return addressInfo.address;
  }

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }
  /// LOGOUT: Deletes the stored key so the user has to re-enter words or create new
  Future<void> logout() async {
    await _storage.delete(key: _mnemonicKey);
    _wallet = null;
  }

  /// SYNC: Connects to the network to update balance and tx history
  Future<void> syncWallet() async {
    if (_wallet == null) return;
    try {
      _blockchain ??= await Blockchain.create(
        config: BlockchainConfig.electrum(
          config: ElectrumConfig(
            url: 'ssl://electrum.blockstream.info:60002',
            retry: 5,
            timeout: 5,
            stopGap: 10,
            validateDomain: true,
          ),
        ),
      );
      
      await _wallet!.sync(_blockchain!);
      debugPrint("Sync Successful");
    } catch (e) {
      debugPrint("Sync Error: $e");
    }
  }

   Future<List<TransactionDetails>> getOnChainTransactions() async {
  if (_wallet == null) return [];

  try {
    final transactions = await _wallet!.listTransactions(false);

    transactions.sort((a, b) {
      // This helper ensures we ALWAYS return a BigInt to satisfy the sort
      BigInt getSafeTime(BlockTime? time) {
        if (time == null) {
          // Use a massive number for pending txs to keep them at the top
          return BigInt.from(8640000000); 
        }

        // We use 'dynamic' here because the BDK bridge varies between int/BigInt
        final dynamic ts = time.timestamp;

        if (ts is BigInt) {
          return ts;
        } else if (ts is int) {
          return BigInt.from(ts);
        } else {
          return BigInt.from(0);
        }
      }

      final aTime = getSafeTime(a.confirmationTime);
      final bTime = getSafeTime(b.confirmationTime);
      
      return bTime.compareTo(aTime);
    });

    return transactions;
  } catch (e) {
    debugPrint("Error fetching transactions: $e");
    return [];
  }
}
}