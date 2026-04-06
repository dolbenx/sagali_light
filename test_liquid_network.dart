import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';

void main() {
  final config = defaultConfig(network: LiquidNetwork.regtest);
  print('Liquid Regtest default config:');
  print('liquidExplorer: ${config.liquidExplorer}');
  print('bitcoinExplorer: ${config.bitcoinExplorer}');
  print('syncServiceUrl: ${config.syncServiceUrl}');
}
