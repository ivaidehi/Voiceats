import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voiceats/custom%20widgets/custom_appbar.dart';
import 'package:voiceats/custom%20widgets/styles.dart';

import '../../custom widgets/custom_hotel_card.dart';
import '../../custom widgets/custom_logout.dart';
import '../../custom widgets/custom_searchbar.dart';
import '../../get data/get_data.dart';
import 'order_menu_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({Key? key}) : super(key: key);

  @override
  _CustomerHomeScreenState createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String customerName = "";
  int profileImageIndex = 0;
  final List<Map<String, dynamic>> hotels = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _imagesLoading = true;

  static const _profileImages = [
    'assets/profile1.png',
    'assets/profile2.png',
    'assets/profile3.png',
    'assets/profile4.png',
    'assets/profile5.png',
    'assets/profile6.png',
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _loadUserData();
    await _fetchHotels();
    setState(() => _isLoading = false);
    // Pre-cache hotel images
    _precacheImages();
  }

  Future<void> _precacheImages() async {
    try {
      for (var hotel in hotels) {
        final imageUrl = hotel['imageUrl'];
        if (imageUrl.startsWith('http')) {
          await precacheImage(NetworkImage(imageUrl), context);
        }
      }
    } catch (e) {
      debugPrint("Image precaching error: $e");
    } finally {
      if (mounted) {
        setState(() => _imagesLoading = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final name = await GetCustomerData.getCustomerName();
      final index = await GetCustomerData.getCustomerProfileImageIndex();

      if (mounted) {
        setState(() {
          customerName = name;
          profileImageIndex = index;
        });
      }
    } catch (e) {
      debugPrint("Error loading user data: $e");
    }
  }

  Future<void> _fetchHotels() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('Hotels').get();

      if (snapshot.docs.isNotEmpty) {
        hotels.clear();

        for (var doc in snapshot.docs) {
          final hotelId = doc.id;
          final name = await GetHotelData.getHotelName(hotelId);
          final imageUrl = await GetHotelData.getHotelImageUrl(hotelId);

          hotels.add({
            'id': hotelId,
            'name': name,
            'imageUrl': imageUrl,
          });
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint("Error fetching hotels: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppbar(
        appbarTitle: customerName,
        onBackPressed: (context) =>
            Navigator.pushNamed(context, '/customerHomeScreen'),
        showProfileImage: true,
        profileImagePath: _profileImages[profileImageIndex],
        actions: [
          Center(
            child: IconButton(
              icon: Icon(Icons.logout, color: styles.primary),
              onPressed: () =>
                  CustomLogOut.showLogoutConfirmationDialog(context),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildHomeContent(),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 20),
          Text(
            'Explore Hotels',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: styles.primary),
          ),
          const SizedBox(height: 15),
          _buildHotelsList(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return CustomSearchBar(
      controller: _searchController,
      hintText: 'Search Hotel',
    );
  }

  Widget _buildHotelsList() {
    return _imagesLoading
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: hotels.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 15.0),
              child: _buildHotelCard(hotels[index]),
            ),
          );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    bool isFavorite = false; // You'll want to manage this state properly

    return CustomHotelCard(
      hotel: hotel,
      isFavorite: isFavorite,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderMenuScreen(hotel: hotel),
          ),
        );
      },
      onFavoritePressed: () {
        setState(() {
          isFavorite = !isFavorite;
        });
        // Call method to update in Firestore
        // _toggleFavorite(hotel['id'], isFavorite);
      },
      showOrderNowButton: true,
    );
  }
}
