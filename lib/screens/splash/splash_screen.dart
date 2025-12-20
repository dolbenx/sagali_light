import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  late Animation<double> _flickerAnimation; // New flicker animation

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();

    // 1. Heartbeat Scale
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

    // 2. Lightning Flicker (Syncs with the peak of the heartbeat)
    _flickerAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 35), // Silent start
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.8), weight: 5),   // Flash 1
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 0.2), weight: 5),   // Quick dim
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.0), weight: 5),   // Flash 2 (Peak)
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 50),  // Fade out
    ]).animate(_controller);

    _checkWallet();
  }

  //
   Future<void> _checkWallet() async {
    await Future.delayed(const Duration(seconds: 5));

    final prefs = await SharedPreferences.getInstance();
    final hasWallet = prefs.getBool('hasWallet') ?? false;

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            hasWallet ? const PinScreen() : const AuthChoiceScreen(),
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
      backgroundColor: const Color(0xFF0E1A2B),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('assets/images/bg_pattern.png', fit: BoxFit.cover),
            ),
          ),

          /// LOGO WITH FLICKER OVERLAY
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Base Logo
                  Image.asset('assets/images/logo-2.png', width: 140),
                  
                  // Lightning Glow Overlay
                  FadeTransition(
                    opacity: _flickerAnimation,
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.white, // Or a lightning blue: Color(0xFF7DF9FF)
                        BlendMode.srcIn,
                      ),
                      child: Image.asset('assets/images/logo-2.png', width: 140),
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