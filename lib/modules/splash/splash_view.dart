import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SplashView extends StatefulWidget {
  @override
  _SplashViewState createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.green[500],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco,
                color: Colors.white,
                size: 80,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              'AgroGen Crateús',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
