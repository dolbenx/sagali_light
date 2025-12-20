import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:ui';
import '../dashboard/dashboard_screen.dart'; 
import '../settings/settings_screen.dart'; 

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  // Using the same primary color from your dashboard
  final Color primaryGold = const Color(0xFFBE8345);
  final Color bgColor = const Color(0xFF0E1A2B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          /// 1. BACKGROUND PATTERN
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/bg_pattern.png',
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// 2. CONTENT
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildHeader(context),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    children: const [
                      TransactionTile(
                        icon: FontAwesomeIcons.arrowUp,
                        title: 'Sent BTC',
                        subtitle: 'To John • 12:45 PM',
                        amount: '-0.005 BTC',
                        isExpense: true,
                      ),
                      TransactionTile(
                        icon: FontAwesomeIcons.arrowDown,
                        title: 'Received BTC',
                        subtitle: 'From Alice • Yesterday',
                        amount: '+0.010 BTC',
                        isExpense: false,
                      ),
                      TransactionTile(
                        icon: FontAwesomeIcons.syncAlt,
                        title: 'Withdrawn',
                        subtitle: 'To Airtel • Oct 22',
                        amount: '-200 ZMW',
                        isExpense: true,
                      ),
                      TransactionTile(
                        icon: FontAwesomeIcons.syncAlt,
                        title: 'Withdrawn',
                        subtitle: 'To MTN • Oct 20',
                        amount: '-500 ZMW',
                        isExpense: true,
                      ),
                      TransactionTile(
                        icon: FontAwesomeIcons.arrowDown,
                        title: 'Received BTC',
                        subtitle: 'Market Order • Oct 18',
                        amount: '+0.042 BTC',
                        isExpense: false,
                      ),
                      TransactionTile(
                        icon: FontAwesomeIcons.arrowUp,
                        title: 'Sent BTC',
                        subtitle: 'ln11nsaqud83 • Oct 15',
                        amount: '-150 BTC',
                        isExpense: true,
                      ),
                      SizedBox(height: 100), // Padding so last items aren't hidden by nav
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// 3. FLOATING BOTTOM NAV
          _floatingBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            'Transactions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _floatingBottomNav(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.account_balance_wallet,
                    label: "Wallet",
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const DashboardScreen()),
                    ),
                  ),
                  _NavItem(
                    icon: Icons.swap_horiz,
                    label: "Transactions",
                    isActive: true, // This screen
                    onTap: () {},
                  ),
                  _NavItem(
                    icon: Icons.settings,
                    label: "Settings",
                    onTap: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isExpense 
              ? Colors.red.withOpacity(0.1) 
              : Colors.green.withOpacity(0.1),
          child: FaIcon(
            icon, 
            color: isExpense ? Colors.redAccent : Colors.greenAccent, 
            size: 18
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        trailing: Text(
          amount,
          style: TextStyle(
            color: isExpense ? Colors.redAccent : Colors.greenAccent,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFFBE8345) : Colors.white54,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}