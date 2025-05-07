import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerHomescreen extends StatefulWidget {
  const CustomerHomescreen({super.key});

  @override
  State<CustomerHomescreen> createState() => _CustomerHomescreenState();
}

class _CustomerHomescreenState extends State<CustomerHomescreen> {
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      // 1. Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // 2. Clear local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. Navigate to login screen and remove all routes
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
            (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: _isLoggingOut
                ? const CupertinoActivityIndicator()
                : const Icon(Icons.logout),
            onPressed: _isLoggingOut ? null : _showLogoutConfirmation,
          ),
        ],
      ),
      body: const Center(
        child: Text("Hellooooo Narutoo"),
      ),
    );
  }
}