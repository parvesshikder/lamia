import 'package:flutter/material.dart';

class LoginScrren extends StatelessWidget {
  const LoginScrren({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.green,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 250,
              width: 250,
              decoration: const BoxDecoration(
                shape:
                    BoxShape.circle, // Use BoxShape.circle for a perfect circle
              ),
              child: ClipOval(
                // Clip the image to be circular
                child: Image.asset(
                  'assets/images/logo.png',
                  fit:
                      BoxFit.cover, // Ensure the image covers the circular area
                ),
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            Center(
              child: SizedBox(
                width: 300, 
                height: 60,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(
                    context,
                    '/register',
                  ),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 50, vertical: 20),
                      textStyle: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
