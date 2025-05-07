import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voiceats/screens/create_account.dart';
import 'package:voiceats/screens/customer/customer_home_screen.dart';
import 'package:voiceats/screens/customer/customer_register_screen.dart';
import 'package:voiceats/screens/hotel/set_hotel_profile_screen.dart';
import 'package:voiceats/screens/hotel/hotel_register_screen.dart';
import 'package:voiceats/screens/hotel/order_status_screen.dart';
import 'package:voiceats/screens/hotel/set_topmenu_screen.dart';
import 'package:voiceats/screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAQ7Nm-YNVMJtesZ63wvseugGI20XLnFJA",
      appId: "1:307478280139:android:65fa4bc720023a0198a84e",
      messagingSenderId: "307478280139",
      projectId: "voiceats-f1ee8",
      // Add other required options
    ),
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VOICEATS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const CreateAccount(),
        '/customerRegister': (context) => const CustomerRegisterScreen(),
        '/customerHomeScreen': (context) => const CustomerHomescreen(),
        '/hotelRegister': (context) => const HotelRegisterScreen(),
        '/hotelHomeScreen': (context) => const SetHotelProfileScreen(),
        '/setTopMenuScreen': (context) => const SetTopMenuScreen(),
        '/orderStatusScreen': (context) => const OrderStatusScreen(),
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isFirstTime = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFirstTime = prefs.getBool('isFirstTime') ?? true;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return _isFirstTime ? const CreateAccount() : const LoginScreen();
          }

          // If user is logged in, fetch userType from Firestore
          return FutureBuilder<String>(
            future: _getUserType(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const LoginScreen(); // fallback if userType fetch fails
              }

              final userType = snapshot.data!;
              if (userType == 'hotel') {
                return const SetHotelProfileScreen();
              } else {
                return const CustomerHomescreen();
              }
            },
          );
        }

        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

// 🔍 Utility function to fetch userType
  Future<String> _getUserType(String uid) async {
    final hotelDoc = await FirebaseFirestore.instance.collection('Hotels').doc(uid).get();
    if (hotelDoc.exists && hotelDoc.data() != null) {
      return (hotelDoc.data() as Map<String, dynamic>)['userType'] ?? 'hotel';
    }

    final customerDoc = await FirebaseFirestore.instance.collection('Customers').doc(uid).get();
    if (customerDoc.exists && customerDoc.data() != null) {
      return (customerDoc.data() as Map<String, dynamic>)['userType'] ?? 'customer';
    }

    return 'customer'; // default if not found
  }
}