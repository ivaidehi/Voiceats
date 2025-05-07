// view_hotel_profile.dart
import 'package:flutter/material.dart';
import 'package:voiceats/custom%20widgets/custom_appbar.dart';
import 'package:voiceats/custom%20widgets/custom_button.dart';

class ViewHotelProfile extends StatelessWidget {
  final String? hotelName;
  final String description;
  final String? imageUrl;
  final List<String> menuCardImageUrls;

  const ViewHotelProfile({
    super.key,
    this.hotelName,
    required this.description,
    this.imageUrl,
    required this.menuCardImageUrls,
  });

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 3.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppbar(
        appbarTitle: 'View Hotel Profile',
        onBackPressed: (context) {
          Navigator.pushNamed(context, '/hotelHomeScreen');
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Name - only show if exists
            if (hotelName != null && hotelName!.isNotEmpty)
              Text(
                hotelName ?? 'Our Hotel',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            const SizedBox(height: 16),

            // Hotel Image
            if (imageUrl != null)
              GestureDetector(
                onTap: () => _showFullScreenImage(context, imageUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 16),

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 16),

            // Our Menu Section
            const Center(
              child: Text(
                'Our Menu',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Menu Card Images
            if (menuCardImageUrls.isNotEmpty)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1, // Changed to square aspect ratio
                ),
                itemCount: menuCardImageUrls.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(context, menuCardImageUrls[index]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12), // Matches hotel image style
                      child: Image.network(
                        menuCardImageUrls[index],
                        fit: BoxFit.cover, // Matches hotel image style
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 16),

            // Top/Special Menu Button
            CustomButton(
              buttonText: "Top/Regular Menu",
              navigateToPage: '/setTopMenuScreen',
            ),
          ],
        ),
      ),
    );
  }
}