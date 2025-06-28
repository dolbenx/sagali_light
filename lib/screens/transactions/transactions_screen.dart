import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../main.dart'; // for primaryColor

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: const [
          SizedBox(height: 10),
          TransactionTile(
            icon: FontAwesomeIcons.arrowUpRightFromSquare,
            title: 'Sent BTC',
            subtitle: '0.005 BTC to John',
            amount: '-0.005 BTC',
            isExpense: true,
          ),
          TransactionTile(
            icon: FontAwesomeIcons.arrowDown,
            title: 'Received BTC',
            subtitle: '0.010 BTC from Alice',
            amount: '+0.010 BTC',
            isExpense: false,
          ),
          TransactionTile(
            icon: FontAwesomeIcons.syncAlt,
            title: 'Withdrawn',
            subtitle: '200 ZMW to bank',
            amount: '-200 ZMW',
            isExpense: true,
          ),
          TransactionTile(
            icon: FontAwesomeIcons.bolt,
            title: 'Lightning Topup',
            subtitle: '500 ZMW',
            amount: '+500 ZMW',
            isExpense: false,
          ),
          TransactionTile(
            icon: FontAwesomeIcons.btc,
            title: 'Bought BTC',
            subtitle: '0.002 BTC',
            amount: '+0.002 BTC',
            isExpense: false,
          ),
          TransactionTile(
            icon: FontAwesomeIcons.moneyBill,
            title: 'Cashout',
            subtitle: '150 ZMW',
            amount: '-150 ZMW',
            isExpense: true,
          ),
        ],
      ),
    );
  }
}

class TransactionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String amount;
  final bool isExpense;

  const TransactionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
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
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(
          amount,
          style: TextStyle(
            color: isExpense ? Colors.red : Colors.green,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
