import 'package:flutter/material.dart';
import '../../main.dart'; // for primaryColor

class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Withdraw'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: const [
          WithdrawOption(
            label: 'Airtel Money',
            imagePath: 'assets/images/airtel.png',
          ),
          WithdrawOption(
            label: 'MTN Mobile Money',
            imagePath: 'assets/images/mtn.png',
          ),
          WithdrawOption(
            label: 'Zamtel Kwacha',
            imagePath: 'assets/images/zamtel.png',
          ),
          WithdrawOption(
            label: 'Zed Mobile',
            imagePath: 'assets/images/zedmobile.png',
          ),
        ],
      ),
    );
  }
}

class WithdrawOption extends StatelessWidget {
  final String label;
  final String imagePath;

  const WithdrawOption({
    super.key,
    required this.label,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to specific withdrawal logic
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected: $label')),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(color: primaryColor.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, height: 50),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            )
          ],
        ),
      ),
    );
  }
}
