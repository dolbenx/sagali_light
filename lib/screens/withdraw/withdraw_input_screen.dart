import 'package:flutter/material.dart';
import 'withdraw_confirm_screen.dart'; // We will create this next

class WithdrawInputScreen extends StatefulWidget {
  final String networkName;
  final String imagePath;

  const WithdrawInputScreen({
    super.key, 
    required this.networkName, 
    required this.imagePath
  });

  @override
  State<WithdrawInputScreen> createState() => _WithdrawInputScreenState();
}

class _WithdrawInputScreenState extends State<WithdrawInputScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B),
      body: Stack(
        children: [
          Positioned.fill(child: Opacity(opacity: 0.4, child: Image.asset('assets/images/bg_pattern.png', fit: BoxFit.cover))),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Image.asset(widget.imagePath, height: 35)),
                        const SizedBox(height: 10),
                        Text(widget.networkName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 40),
                        
                        _inputField("Mobile Number", _phoneController, TextInputType.phone, "097xxxxxxx"),
                        const SizedBox(height: 20),
                        _inputField("Amount (ZMW)", _amountController, TextInputType.number, "0.00"),
                        
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFBE8345),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => WithdrawConfirmScreen(
                                network: widget.networkName,
                                mobile: _phoneController.text,
                                amountZMW: double.tryParse(_amountController.text) ?? 0.0,
                              )));
                            },
                            child: const Text("SUBMIT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputField(String label, TextEditingController controller, TextInputType type, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          style: const TextStyle(color: Colors.white, fontSize: 18),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(children: [
        IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
        const Text("Details", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ]),
    );
  }
}