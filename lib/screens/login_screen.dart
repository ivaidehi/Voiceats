import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voiceats/custom%20widgets/custom_inputfield.dart';
import '../custom%20widgets/styles.dart'; // Assuming CustomArcClipper is defined here

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Authenticate user
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      // 2. Try fetching from Hotels first
      DocumentSnapshot userDocHotel =
          await FirebaseFirestore.instance.collection('Hotels').doc(uid).get();
      // DocumentSnapshot userDocCustomer = await FirebaseFirestore.instance.collection('Customers').doc(uid).get();

      String userType = 'customer'; // default

      if (userDocHotel.exists && userDocHotel.data() != null) {
        userType = (userDocHotel.data() as Map<String, dynamic>)['userType'] ??
            'hotel';
      } else {
        // 3. If not found in Hotels, check Customers
        userDocHotel = await FirebaseFirestore.instance
            .collection('Customers')
            .doc(uid)
            .get();

        if (userDocHotel.exists && userDocHotel.data() != null) {
          userType =
              (userDocHotel.data() as Map<String, dynamic>)['userType'] ??
                  'customer';
        } else {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message:
                'User document not found in both Hotels and Customers collections.',
          );
        }
      }

      // 4. Save login state
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstTime', false);

      // 5. Success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login successful!'),
          backgroundColor: Colors.green,
        ),
      );

      // 6. Navigate based on userType
      Future.delayed(const Duration(milliseconds: 500), () {
        if (userType == 'hotel') {
          Navigator.pushReplacementNamed(context, '/hotelHomeScreen');
        } else {
          Navigator.pushReplacementNamed(context, '/customerHomeScreen');
        }
      });
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Authentication failed'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            controller: _scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Red arc header
                    ClipPath(
                      clipper: CustomArcClipper(),
                      child: Container(
                        height: 250, // Reduced height for better keyboard space
                        width: double.infinity,
                        color: const Color(0xFFA61617),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 60,
                              ),
                              SizedBox(height: 12),
                              Text(
                                "VOICEATS",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Back button and title
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/register');
                                    },
                                    child: const Icon(
                                      Icons.arrow_back_ios,
                                      color: Color(0xFFA61617),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Login / Sign In',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFA61617),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),

                              // Input fields
                              CustomInputField(
                                controller: _emailController,
                                labelText: "Email Id",
                                warning: "Please enter valid Email ID",
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: Icon(Icons.email_outlined,
                                    color: styles.primary),
                              ),
                              const SizedBox(height: 20),
                              CustomInputField(
                                controller: _passwordController,
                                labelText: "Password",
                                warning: "Please enter valid password",
                                prefixIcon: Icon(Icons.lock_outline,
                                    color: styles.primary),
                                isHide: true,
                                showEye: true,
                                maxlines: 1,
                              ),
                              const SizedBox(height: 10),

                              // Forgot password
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    // Implement forgot password logic
                                  },
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFA61617),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const CircularProgressIndicator(
                                          color: Colors.white)
                                      : const Text(
                                          'Login',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),

                              const Spacer(),

                              // Register Text
                              Padding(
                                padding: const EdgeInsets.only(bottom: 30),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/register');
                                    },
                                    child: RichText(
                                      text: const TextSpan(
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'Don\'t have an account? ',
                                            style: TextStyle(
                                                color: Colors.black54),
                                          ),
                                          TextSpan(
                                            text: 'Register / Sign Up',
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
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
