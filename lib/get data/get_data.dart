import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Fetch Hotel Data
class GetHotelData {

  // Fetch Hotel Name
  static Future<String> getHotelName(String hotelId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('Hotels').doc(hotelId).get();
      if (doc.exists) {
        return doc['hotelName'] ?? 'Unnamed Hotel';
      }
    } catch (e) {
      debugPrint("Error fetching hotel name: $e");
    }
    return 'Unknown Hotel';
  }

  // Fetch Hotel Image
  static Future<String> getHotelImageUrl(String hotelId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('Hotels').doc(hotelId).get();
      if (doc.exists) {
        return doc['hotelImageUrl'] ?? 'https://via.placeholder.com/150';
      }
    } catch (e) {
      debugPrint("Error fetching hotel image URL: $e");
    }
    return 'https://via.placeholder.com/150';
  }

  // Fetch Hotel Description
  static Future<String> getHotelDescription(String hotelId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('Hotels').doc(hotelId).get();
      if (doc.exists) {
        return doc['description'] ?? 'No description available.';
      }
    } catch (e) {
      debugPrint("Error fetching hotel description: $e");
    }
    return 'No description available.';
  }
}



// Fetch Customer Data
class GetCustomerData {
  static Future<String> getCustomerName() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 'Guest';

      final doc = await FirebaseFirestore.instance.collection('Customers').doc(currentUser.uid).get();
      if (doc.exists) {
        return doc['aiGeneratedName'] ?? 'Customer';
      }
    } catch (e) {
      debugPrint("Error fetching customer name: $e");
    }
    return 'Customer';
  }

  static Future<int> getCustomerProfileImageIndex() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return 0;

      final doc = await FirebaseFirestore.instance.collection('Customers').doc(currentUser.uid).get();
      if (doc.exists) {
        return doc['profileImageIndex'] ?? 0;
      }
    } catch (e) {
      debugPrint("Error fetching profile image index: $e");
    }
    return 0;
  }
}
