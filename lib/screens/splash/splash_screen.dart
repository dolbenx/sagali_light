import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/wallet_service.dart';
import '../auth/auth_choice_screen.dart';
import '../auth/pin_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _flickerAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Setup Animation Controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // 2. Heartbeat Scale Animation
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 60,
      ),
    ]).animate(_controller);

    // 3. Lightning Flicker Animation (Electric Blue/White Effect)
    _flickerAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 35), 
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.8), weight: 5),  
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.2), weight: 5),  
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 5),  
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50), 
    ]).animate(_controller);

    // 4. Start Auth & Initialization check
    _checkWallet();
  }

  /// THE CORE LOGIC: Initialize BDK while animating
  Future<void> _checkWallet() async {
    // We give the branding at least 3 seconds of screen time
    final minimumTimer = Future.delayed(const Duration(seconds: 3));

    // Initialize the BDK Wallet (this checks Secure Storage for us)
    final loginTask = WalletService().tryAutoLogin();

    // Wait for BOTH the visual timer and the background BDK task
    final results = await Future.wait([minimumTimer, loginTask]);
    final bool hasWallet = results[1] as bool;

    if (!mounted) return;

    // Navigate to PinScreen if wallet exists, otherwise AuthChoiceScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasWallet ? const PinScreen() : const AuthChoiceScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1A2B), // Sagali Dark Blue
      body: Stack(
        children: [
          // Background Pattern
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset(
                'assets/images/bg_pattern.png', 
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(),
              ),
            ),
          ),

          // Logo with flickering electric effect
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Standard Gold/Logo
                  Image.asset('assets/images/logo-2.png', width: 160),
                  
                  // Lightning Blue Overlay
                  FadeTransition(
                    opacity: _flickerAnimation,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF7DF9FF), // Electric Blue
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('assets/images/logo-2.png', width: 160),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}