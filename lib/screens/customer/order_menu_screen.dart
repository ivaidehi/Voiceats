import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voiceats/custom widgets/styles.dart';
import 'package:voiceats/custom%20widgets/custom_button.dart';
import 'package:voiceats/get%20data/get_data.dart';

import '../../custom widgets/custom_appbar.dart';
import '../../custom widgets/custom_hotel_card.dart';

class OrderMenuScreen extends StatefulWidget {
  final Map<String, dynamic>? hotel;

  const OrderMenuScreen({Key? key, this.hotel}) : super(key: key);

  @override
  _OrderMenuScreenState createState() => _OrderMenuScreenState();
}

class _OrderMenuScreenState extends State<OrderMenuScreen> {
  late Future<List<String>> _menuImagesFuture;
  String customerName = " ";
  int profileImageIndex = 0;
  String hotelDescription = '';



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
    _menuImagesFuture = _fetchMenuImages();
    _loadCustomerData();
    _fetchHotelDescription();
  }

  Future<void> _loadCustomerData() async {
    final name = await GetCustomerData.getCustomerName();
    final index = await GetCustomerData.getCustomerProfileImageIndex();

    if (mounted) {
      setState(() {
        customerName = name;
        profileImageIndex = index;
      });
    }
  }

  Future<List<String>> _fetchMenuImages() async {
    try {
      if (widget.hotel == null || widget.hotel!['id'] == null) return [];

      final doc = await FirebaseFirestore.instance
          .collection('Hotels')
          .doc(widget.hotel!['id'])
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return List<String>.from(data['menuCardImageUrls'] ?? []);
      }
    } catch (e) {
      debugPrint("Error fetching menu images: $e");
    }
    return [];
  }

  Future<void> _fetchHotelDescription() async {
    if (widget.hotel?['id'] != null) {
      final desc = await GetHotelData.getHotelDescription(widget.hotel!['id']);
      if (mounted) {
        setState(() {
          hotelDescription = desc;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppbar(
        appbarTitle: customerName,
        onBackPressed: (context) => Navigator.pop(context),
        showProfileImage: true,
        profileImagePath: _profileImages[profileImageIndex],
      ),
      body: _buildMenuContent(),
    );
  }

  Widget _buildMenuContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.hotel != null) ...[
            CustomHotelCard(
              hotel: widget.hotel!,
              isFavorite: false,
              onTap: () {},
              onFavoritePressed: () {},
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                widget.hotel!['name'] ?? 'Hotel Name',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: styles.primary,
                ),
              ),
            ),

            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                hotelDescription,
                style: TextStyle(fontSize: 12, color: styles.primary),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 20),

            // Hide the "Order Now" button only in the OrderMenuScreen
            if (ModalRoute.of(context)?.settings.name != '/orderMenuScreen')
              CustomButton(
                buttonText: "Order Now",
                navigateToPage: '/orderNowScreen',
              ),
            const SizedBox(height: 15),
            CustomButton(buttonText: 'Top/ Regular Menu', navigateToPage: '/'),
            const SizedBox(height: 20),
          ],
          FutureBuilder<List<String>>(
            future: _menuImagesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    "No menu images available",
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "  Menu Card Items",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: styles.primary,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildMenuGrid(snapshot.data!),
                ],
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildMenuGrid(List<String> menuImages) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1,
      ),
      itemCount: menuImages.length,
      itemBuilder: (context, index) => _buildMenuImageCard(menuImages[index]),
    );
  }

  Widget _buildMenuImageCard(String imageUrl) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                color: styles.primary,
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
    );
  }
}
