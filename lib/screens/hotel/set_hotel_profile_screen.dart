// set_hotel_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'dart:convert';

import 'package:voiceats/custom%20widgets/custom_appbar.dart';
import 'package:voiceats/custom%20widgets/custom_button.dart';
import 'package:voiceats/custom%20widgets/custom_inputfield.dart';
import 'package:voiceats/custom%20widgets/head_title.dart';
import 'package:voiceats/custom%20widgets/styles.dart';
import 'package:voiceats/screens/hotel/order_status_screen.dart';
import 'package:voiceats/screens/hotel/view_hotel_profile.dart';

class SetHotelProfileScreen extends StatefulWidget {
  const SetHotelProfileScreen({super.key});

  @override
  State<SetHotelProfileScreen> createState() => _SetHotelProfileScreenState();
}

class _SetHotelProfileScreenState extends State<SetHotelProfileScreen> {
  bool _isLoggingOut = false;
  bool _isLoading = false;
  File? _hotelImage;
  final List<File> _menuCardImages = [];
  String? _hotelImageUrl;
  List<String> _menuCardImageUrls = [];
  final TextEditingController _descriptionController = TextEditingController();
  int _currentIndex = 0;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadHotelData();
  }

  Future<void> _loadHotelData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('Hotels').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _hotelImageUrl = doc.data()?['hotelImageUrl'];
          _menuCardImageUrls = List<String>.from(doc.data()?['menuCardImageUrls'] ?? []);
          _descriptionController.text = doc.data()?['description'] ?? '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading hotel data: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickImage({bool isMenuCard = false, int? replaceIndex}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);

      if (isMenuCard) {
        // If replacing an existing image
        if (replaceIndex != null) {
          await _uploadImageToImgBB(
            imageFile,
            isMenuCard: true,
            replaceIndex: replaceIndex,
          );
        } else {
          // Adding a new image
          await _uploadImageToImgBB(
            imageFile,
            isMenuCard: true,
          );
        }
      } else {
        // Hotel main image
        setState(() => _hotelImage = imageFile);
        await _uploadImageToImgBB(_hotelImage!);
      }
    }
  }

  Future<void> _uploadImageToImgBB(File image, {
    bool isMenuCard = false,
    int? replaceIndex,
  }) async {
    const apiKey = 'acaf17dc0d62e42f7e5ab8a52bfef6d5';
    final uri = Uri.parse('https://api.imgbb.com/1/upload');
    final bytes = await image.readAsBytes();
    final base64Image = base64Encode(bytes);
    final filename = path.basename(image.path);

    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        uri,
        body: {
          'key': apiKey,
          'image': base64Image,
          'name': filename,
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final imageUrl = jsonResponse['data']['url'];

        setState(() {
          if (isMenuCard) {
            if (replaceIndex != null && replaceIndex < _menuCardImageUrls.length) {
              _menuCardImageUrls[replaceIndex] = imageUrl;
            } else {
              _menuCardImageUrls.add(imageUrl);
            }
          } else {
            _hotelImageUrl = imageUrl;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully!')),
        );
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _firestore.collection('Hotels').doc(user.uid).set({
        'hotelImageUrl': _hotelImageUrl,
        'menuCardImageUrls': _menuCardImageUrls,
        'description': _descriptionController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _removeMenuCardImage(int index) {
    setState(() {
      _menuCardImageUrls.removeAt(index);
    });
  }

  Future<void> _logout() async {
    setState(() => _isLoggingOut = true);
    try {
      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
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

  // Here remove that 3 dots instaed of this display log icon direlcty
  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:  const HeadTitle(title: 'Log Out',),
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
                      onPressed: _logout,
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

  // ... [rest of your existing methods like _logout, _showLogoutConfirmation, etc.] ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppbar(
        appbarTitle: 'Set Hotel Profile',
        onBackPressed: (context) => Navigator.pushNamed(context, '/hotelHomeScreen'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _showLogoutConfirmation();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Text('Log Out', style: TextStyle(color: styles.primary, fontWeight: FontWeight.bold, fontSize: 15),),
                    const SizedBox(width: 10,),
                    Icon(Icons.logout, color: styles.primary,),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentIndex == 1 ? SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // const SizedBox(height: 20),
              Text(
                'Upload Hotel Image',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: styles.primary),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _pickImage(),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Stack(
                    children: [
                      // Image or Placeholder (FORCED to fill Container)
                      if (_hotelImage != null || _hotelImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _hotelImage != null
                              ? Image.file(
                            _hotelImage!,
                            fit: BoxFit.cover,  // Ensures image covers the space
                            width: double.infinity,  // Forces full width
                            height: double.infinity, // Forces full height
                          )
                              : Image.network(
                            _hotelImageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 50, color: Colors.red[200]),
                              const SizedBox(height: 10),
                              const Text(
                                'Upload Hotel Image',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                      // Edit Icon (Top-Right Corner)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(6),
                          child:  Icon(
                            Icons.edit,
                            color: Colors.red[900],
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 10),
              CustomInputField(controller: _descriptionController, labelText: "About Hotel (Description)", warning: "Please Enter Hotel Description", maxlines: 3,),
              const SizedBox(height: 20),
              const CustomButton(
                buttonText: "Top/Regular Menu",
                navigateToPage: '/setTopMenuScreen',
              ),
              const SizedBox(height: 20),
              Text(
                'Upload Menu Card Images',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: styles.primary),
              ),
              const SizedBox(height: 10),
              const Text(
                'You can add multiple menu card images',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: _menuCardImageUrls.length + 1,
                itemBuilder: (context, index) {
                  if (index == _menuCardImageUrls.length) {
                    return GestureDetector(
                      onTap: () => _pickImage(isMenuCard: true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo, size: 40, color: Colors.red[200]),
                            const SizedBox(height: 8),
                            const Text(
                              'Add Image',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  void showFullScreenImage(BuildContext context, String imageUrl) {
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

                  return GestureDetector(
                    onTap: () {
                      final imageUrl = index < _menuCardImages.length
                          ? null
                          : _menuCardImageUrls[index - _menuCardImages.length];
                      if (imageUrl != null) {
                        showFullScreenImage(context, imageUrl);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12), // Match hotel image
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Stack(
                        children: [
                          // Image Container (Square aspect ratio)
                          AspectRatio(
                            aspectRatio: 1, // Force square shape
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: index < _menuCardImages.length
                                  ? Image.file(
                                _menuCardImages[index],
                                fit: BoxFit.cover,
                              )
                                  : _menuCardImageUrls.length > index - _menuCardImages.length
                                  ? Image.network(
                                _menuCardImageUrls[index - _menuCardImages.length],
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
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              )
                                  : Container(color: Colors.grey[200]),
                            ),
                          ),

                          // Edit/Delete Buttons
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Material(
                              color: Colors.transparent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Edit Button
                                    // InkWell(
                                    //   onTap: () => _pickImage(isMenuCard: true, replaceIndex: index),
                                    //   borderRadius: BorderRadius.circular(12),
                                    //   child: Padding(
                                    //     padding: EdgeInsets.all(4),
                                    //     child: Icon(
                                    //       Icons.edit,
                                    //       size: 18,
                                    //       color: Colors.red[900],
                                    //     ),
                                    //   ),
                                    // ),
                                    // const SizedBox(width: 4),
                                    // Delete Button
                                    InkWell(
                                      onTap: () => _removeMenuCardImage(index),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.close,
                                          size: 20,
                                          color: Colors.red[900],
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
                  );
                },
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Flexible(
                    child: CustomButton(
                      buttonText: "View Profile",
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewHotelProfile(
                              description: _descriptionController.text,
                              imageUrl: _hotelImageUrl,
                              menuCardImageUrls: _menuCardImageUrls,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Flexible(
                    child: CustomButton(
                      buttonText: "Save Profile",
                      onPressed: _saveProfile,
                    ),
                  ),
                ],
              )

            ],
          ),
        ),
      ) : const OrderStatusScreen(),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: styles.primary,
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}