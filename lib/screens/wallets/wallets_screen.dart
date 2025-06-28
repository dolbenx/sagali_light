import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../main.dart'; // for primaryColor

class WalletsScreen extends StatelessWidget {
  const WalletsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          SizedBox(height: 10),
          WalletTile(
            icon: FontAwesomeIcons.btc,
            name: 'Bitcoin',
            symbol: 'BTC',
            amount: '0.02000',
            value: 'ZMW 2000.00',
          ),
          WalletTile(
            icon: FontAwesomeIcons.ethereum,
            name: 'Ethereum',
            symbol: 'ETH',
            amount: '1.50',
            value: 'ZMW 18000.00',
          ),
          WalletTile(
            icon: FontAwesomeIcons.coins,
            name: 'Binance Coin',
            symbol: 'BNB',
            amount: '5.25',
            value: 'ZMW 9000.00',
          ),
          WalletTile(
            icon: FontAwesomeIcons.rebel,
            name: 'Tron',
            symbol: 'TRX',
            amount: '350.00',
            value: 'ZMW 1500.00',
          ),
          WalletTile(
            icon: FontAwesomeIcons.circle,
            name: 'Polygon',
            symbol: 'MATIC',
            amount: '125.00',
            value: 'ZMW 3000.00',
          ),
        ],
      ),
    );
  }
}

class WalletTile extends StatelessWidget {
  final IconData icon;
  final String name;
  final String symbol;
  final String amount;
  final String value;

  const WalletTile({
    super.key,
    required this.icon,
    required this.name,
    required this.symbol,
    required this.amount,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: primaryColor.withOpacity(0.1),
          child: FaIcon(icon, color: primaryColor),
        ),
        title: Text('$name ($symbol)'),
        subtitle: Text('$amount $symbol'),
        trailing: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}
