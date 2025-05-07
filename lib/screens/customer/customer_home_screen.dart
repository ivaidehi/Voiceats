import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voiceats/custom%20widgets/styles.dart';

import '../../custom widgets/custom_searchbar.dart';
import 'order_menu_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({Key? key}) : super(key: key);

  @override
  _CustomerHomeScreenState createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  String customerName = "Customer Name";
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
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('Customers')
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          customerName = userDoc.data()?['aiGeneratedName'] ?? customerName;
          profileImageIndex = userDoc.data()?['profileImageIndex'] ?? 0;
        });
        await prefs.setString('aiGeneratedName', customerName);
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
        setState(() {
          hotels.clear();
          hotels.addAll(snapshot.docs.map((doc) => {
                'name': doc['hotelName'] ?? 'Hotel Name',
                'imageUrl':
                    doc['hotelImageUrl'] ?? 'https://via.placeholder.com/150',
                'id': doc.id,
              }));
        });
      }
    } catch (e) {
      debugPrint("Error fetching hotels: $e");
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: AssetImage(_profileImages[profileImageIndex]),
            ),
            const SizedBox(width: 53),
            Text(customerName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: styles.primary)),
          ],
        ),
        actions: [
          IconButton(
            icon:  Icon(Icons.logout, color: styles.primary,),
            onPressed: _logout,
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
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: styles.primary),
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderMenuScreen(hotel: hotel),
          ),
        );
      },
      child: Card(
        color: styles.bgcolor,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hotel Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Image.network(
                  hotel['imageUrl'],
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
      
              // Black Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                    stops: [0.1, 0.5],
                  ),
                ),
              ),
      
              // Hotel Info
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel['name'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        SizedBox(width: 4),
                        Text(
                          '4.0 (100 Reviews)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      
              // Favorite Button
              Positioned(
                bottom: 8,
                right: 8,
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.white,
                    size: 25,
                  ),
                  onPressed: () {
                    // TODO: Implement favorite toggle functionality
                    setState(() {
                      isFavorite = !isFavorite;
                    });
                    // Call method to update in Firestore
                    // _toggleFavorite(hotel['id'], isFavorite);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
