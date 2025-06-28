import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/screens/send/send_screen.dart';
import '/screens/receive/receive_screen.dart';
import '/screens/withdraw/withdraw_screen.dart';

const Color primaryColor = Color(0xFF055C7A);

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0560A8), Color(0xFF0593D3)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              border: Border.all(color: primaryColor),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.account_balance_wallet_outlined, size: 20),
                                SizedBox(width: 4),
                                Text('Sagali Wallet'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Balance', style: TextStyle(fontSize: 20)),
                      const SizedBox(height: 5),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black), // Set default text color
                          children: [
                            TextSpan(
                              text: '0.00003193 ',
                              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'BTC',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: Colors.black), // Set default text color
                          children: [
                            TextSpan(
                              text: '80.32 ',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: 'ZMW',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
                Card(
                  color: Color(0xFFF5F5F5), // Light grey background
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  margin: const EdgeInsets.all(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ActionButton(
                          icon: Icons.arrow_upward,
                          label: 'Send',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SendScreen()),
                            );
                          },
                        ),
                        ActionButton(
                          icon: Icons.arrow_downward,
                          label: 'Receive',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ReceiveScreen()),
                            );
                          },
                        ),
                        ActionButton(
                          icon: Icons.sync_alt,
                          label: 'Withdraw',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const WithdrawScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Card(
                  margin: const EdgeInsets.all(5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(5),
                    child: Column(
                      children: const [
                        CoinTile(name: 'Bitcoin', symbol: 'BTC', icon: FontAwesomeIcons.btc, amount: '2.00', rate: '+4.5', value: '50.00'),
                        CoinTile(name: 'TRX', symbol: 'Tron', icon: FontAwesomeIcons.rebel, amount: '2.00', rate: '+4.5', value: '50.00'),
                        CoinTile(name: 'BNB', symbol: 'Binance', icon: FontAwesomeIcons.coins, amount: '30.00', rate: '+13.5', value: '45.00'),
                        CoinTile(name: 'Matic', symbol: 'Polygon', icon: FontAwesomeIcons.circle, amount: '10.00', rate: '+4.5', value: '100.00'),
                        CoinTile(name: 'ETH', symbol: 'Ethereum', icon: FontAwesomeIcons.ethereum, amount: '10.00', rate: '+4.5', value: '100.00'),
                        CoinTile(name: 'BNB', symbol: 'Binance', icon: FontAwesomeIcons.coins, amount: '30.00', rate: '+13.5', value: '45.00'),
                        CoinTile(name: 'Matic', symbol: 'Polygon', icon: FontAwesomeIcons.circle, amount: '10.00', rate: '+4.5', value: '100.00'),
                        CoinTile(name: 'ETH', symbol: 'Ethereum', icon: FontAwesomeIcons.ethereum, amount: '10.00', rate: '+4.5', value: '100.00'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: primaryColor,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold))
        ],
      ),
    );
  }
}

class CoinTile extends StatelessWidget {
  final String name;
  final String symbol;
  final IconData icon;
  final String amount;
  final String rate;
  final String value;

  const CoinTile({
    super.key,
    required this.name,
    required this.symbol,
    required this.icon,
    required this.amount,
    required this.rate,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Colors.transparent, child: FaIcon(icon, color: primaryColor)),
      title: Text('$name $symbol'),
      subtitle: Text('$amount + $rate'),
      trailing: Text(value),
    );
  }
}