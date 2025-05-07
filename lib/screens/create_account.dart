import 'package:flutter/material.dart';
import 'package:voiceats/custom%20widgets/custom_appbar.dart';
import 'package:voiceats/custom%20widgets/custom_button.dart';
import 'package:voiceats/custom%20widgets/head_title.dart';

import '../custom widgets/styles.dart';

class CreateAccount extends StatelessWidget {
  const CreateAccount({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Modified red arc with subtle curve
          ClipPath(
            clipper: CustomArcClipper(),
            child: Container(
              height: 450, // Increased from 300 to 450
              width: double.infinity,
              color: const Color(0xFFA61617),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 80,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "VOICEATS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          CustomAppbar(
            appbarTitle: "Sign Up / Register",
            onBackPressed: (context) => {
              Navigator.pushNamed(context, '/login'),
            },
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and title
                  const SizedBox(height: 30),

                  // Customer Account Button
                  CustomButton(
                      buttonText: "Customer Account",
                      navigateToPage: '/customerRegister'),

                  const SizedBox(height: 20),
                  CustomButton(
                      buttonText: "Hotel Account",
                      navigateToPage: '/hotelRegister'),

                  const Spacer(),

                  // Login text
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/login');
                      },
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(
                            fontSize: 14, // Slightly smaller
                            color: Colors.black,
                          ),
                          children: [
                            TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                color: Colors.black54,
                              ),
                            ),
                            TextSpan(
                              text: 'Login / Sign In',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFA61617),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
