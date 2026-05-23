import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:math' as math;

class SplashView extends StatefulWidget {
  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4),
    )..repeat();

    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(Duration(seconds: 4));
    
    final storage = GetStorage();
    bool isLoggedIn = storage.read('isLoggedIn') ?? false;
    bool onboardingCompleted = storage.read('onboardingCompleted') ?? false;

    if (isLoggedIn) {
      if (onboardingCompleted) {
        Get.offAllNamed('/home');
      } else {
        Get.offAllNamed('/onboarding');
      }
    } else {
      Get.offAllNamed('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _controller,
              builder: (_, child) {
                return Transform.rotate(
                  angle: _controller.value * 2 * math.pi,
                  child: child,
                );
              },
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.green[500],
                  shape: BoxShape.circle,
                ),
                // Se você já tiver a logo, use Image.asset('assets/images/logo.png')
                // Enquanto não tem, usamos o ícone do projeto
                child: Icon(
                  Icons.eco,
                  color: Colors.white,
                  size: 80,
                ),
              ),
            ),
            SizedBox(height: 30),
            Text(
              'AgroGen Crateús',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 10),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
