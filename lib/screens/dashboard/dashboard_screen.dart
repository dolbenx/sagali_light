import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '/screens/send/send_screen.dart';
import '/screens/receive/receive_screen.dart';
import '/screens/withdraw/withdraw_screen.dart';
import '/screens/wallets/wallets_screen.dart';
import '/screens/transactions/transactions_screen.dart';
import '/screens/settings/settings_screen.dart';

const Color primaryColor = Color(0xFF055C7A);

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    DashboardContent(),
    WalletsScreen(),
    TransactionsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: _tabs[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: primaryColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: ''),
        ],
      ),
    );
  }
}

class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black),
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
                    text: const TextSpan(
                      style: TextStyle(color: Colors.black),
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
              color: const Color(0xFFF5F5F5),
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
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transactions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            Card(
              margin: const EdgeInsets.all(5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: const Padding(
                padding: EdgeInsets.all(5),
                child: Column(
                  children: [
                    CoinTile(name: 'Bitcoin', symbol: 'BTC', icon: FontAwesomeIcons.btc, amount: '2.00', rate: '+4.5', value: '50.00'),
                    CoinTile(name: 'TRX', symbol: 'Tron', icon: FontAwesomeIcons.rebel, amount: '2.00', rate: '+4.5', value: '50.00'),
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
      leading: CircleAvatar(
        backgroundColor: Colors.transparent,
        child: FaIcon(icon, color: primaryColor),
      ),
      title: Text('$name ($symbol)'),
      subtitle: Text('$amount • $rate%'),
      trailing: Text(value),
    );
  }
}
