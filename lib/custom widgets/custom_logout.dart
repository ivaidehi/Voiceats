import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voiceats/custom%20widgets/styles.dart';

import 'custom_button.dart';
import 'head_title.dart';

class CustomLogOut {
  static Future<void> logoutUser(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  static void showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  HeadTitle(title: 'Log Out',),
        content: Text('Are you sure you want to log out?', style: TextStyle(color: styles.primary, fontWeight: FontWeight.bold),),
        actions: [
          SizedBox(
            width: double.infinity, // Make the row take full width
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: CustomButton(
                      buttonText: "Cancel",
                      onPressed: () => Navigator.pop(context),
                      // buttonHeight: 40,
                    ),
                  ),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: CustomButton(
                      buttonText: "Log Out",
                      onPressed: ()=> {
                        Navigator.pop(context),
                        logoutUser(context),
                        }
                      // buttonHeight: 40,
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
}
