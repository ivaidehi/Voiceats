import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voiceats/custom%20widgets/custom_appbar.dart';
import 'package:voiceats/custom%20widgets/styles.dart';
import '../../custom widgets/custom_inputfield.dart';
import '../../custom widgets/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class HotelRegisterScreen extends StatefulWidget {
  const HotelRegisterScreen({super.key});

  @override
  _HotelRegisterScreenState createState() => _HotelRegisterScreenState();
}

class _HotelRegisterScreenState extends State<HotelRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hotelNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _contactController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _hotelIdController = TextEditingController();
  bool _isLoading = false;
  File? _profileImage;
  String? _profileImageUrl;
  final ImagePicker _picker = ImagePicker();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _generateHotelId();
  }

  void _generateHotelId() {
    const symbols = ['@', '#', '\$', '%', '^', '&', '*', '!', '?', '~', '+', '=', '-', '_', '/', '\\', '|', '<', '>', '§'];
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final random = DateTime.now().millisecondsSinceEpoch;

    final symbol = symbols[random % symbols.length];
    final numbers = (random % 1000).toString().padLeft(3, '0');
    final letter1 = letters[(random + 1) % letters.length];
    final letter2 = letters[(random + 2) % letters.length];
    final letter3 = letters[(random + 3) % letters.length];

    setState(() {
      _hotelIdController.text = '$symbol$numbers$letter1$letter2$letter3';
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: ${e.toString()}')),
      );
    }
  }

  Future<String?> _uploadImageToImgBB(File imageFile) async {
    try {
      final apiKey = 'acaf17dc0d62e42f7e5ab8a52bfef6d5'; // Replace with your actual ImgBB API key
      final url = Uri.parse('https://api.imgbb.com/1/upload?key=$apiKey');

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        url,
        body: {
          'image': base64Image,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['url'];
      } else {
        print("Failed to upload imageeeeeeeeeeeeeeeeeeeeeeeeeeeee :${response.statusCode}");
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return null;
      print("Failed to upload imageeeeeeeeeeeeeeeeeeeeeeeeeeeee : ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload image: ${e.toString()}')),
      );
      return null;
    }
  }

  Future<void> _registerHotel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Upload profile image to ImgBB if selected
      if (_profileImage != null) {
        _profileImageUrl = await _uploadImageToImgBB(_profileImage!);
        if (_profileImageUrl == null) {
          throw Exception('Failed to upload profile image');
        }
      }

      // Create auth user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Update user display name
      await userCredential.user?.updateDisplayName(_hotelNameController.text.trim());

      // Prepare hotel data
      final hotelData = {
        'hotelName': _hotelNameController.text.trim(),
        'ownerName': _ownerNameController.text.trim(),
        'contact': _contactController.text.trim(),
        'address': _addressController.text.trim(),
        'email': _emailController.text.trim(),
        'hotelId': _hotelIdController.text.trim(),
        'profileImageUrl': _profileImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'userType': 'hotel',
      };

      // Save to Firestore
      await _firestore.collection('Hotels').doc(userCredential.user?.uid).set(hotelData);

      // Save to local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstTime', false);
      await prefs.setString('userType', 'hotel');
      await prefs.setString('hotelId', _hotelIdController.text.trim());
      if (_profileImageUrl != null) {
        await prefs.setString('profileImageUrl', _profileImageUrl!);
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

    } on FirebaseAuthException catch (e) {
      String errorMessage = _handleAuthError(e.code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _handleAuthError(String code) {
    switch (code) {
      case 'email-already-in-use': return 'Email already in use.';
      case 'invalid-email': return 'Invalid email address.';
      case 'operation-not-allowed': return 'Email/password not enabled.';
      case 'weak-password': return 'Password too weak (min 6 chars).';
      case 'network-request-failed': return 'Network error. Check connection.';
      default: return 'Registration failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _hotelNameController.dispose();
    _ownerNameController.dispose();
    _contactController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _hotelIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppbar(appbarTitle: 'Create Hotel Account'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Photo Section
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _profileImage != null
                          ? FileImage(_profileImage!)
                          : null,
                      child: _profileImage == null
                          ? const Icon(Icons.hotel, size: 60, color: Colors.grey)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: styles.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.camera_alt, color: Colors.white),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Upload Hotel Photo',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),

              // Hotel Name Field
              CustomInputField(
                controller: _hotelNameController,
                labelText: 'Hotel Name',
                warning: 'Please enter hotel name',
                prefixIcon: Icon(Icons.business_outlined, color: styles.primary),
              ),
              const SizedBox(height: 20),

              // Owner Name Field
              CustomInputField(
                controller: _ownerNameController,
                labelText: 'Owner Name',
                warning: 'Please enter owner name',
                prefixIcon: Icon(Icons.person_outline, color: styles.primary),
              ),
              const SizedBox(height: 20),

              // Contact Number Field
              CustomInputField(
                controller: _contactController,
                labelText: 'Hotel/Owner Contact',
                warning: 'Please enter a valid contact number',
                keyboardType: TextInputType.phone,
                prefix: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('+91', style: TextStyle(fontSize: 16)),
                ),
                prefixIcon: Icon(Icons.phone, color: styles.primary),
              ),
              const SizedBox(height: 20),

              // Address Field
              CustomInputField(
                controller: _addressController,
                labelText: 'Hotel Address',
                warning: 'Please enter hotel address',
                maxlines: 3,
                prefixIcon: Icon(Icons.location_on_outlined, color: styles.primary),
              ),
              const SizedBox(height: 20),

              // Email Field
              CustomInputField(
                controller: _emailController,
                labelText: 'Email ID',
                warning: 'Please enter a valid email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icon(Icons.email_outlined, color: styles.primary),
              ),
              const SizedBox(height: 20),

              // Password Field
              CustomInputField(
                controller: _passwordController,
                labelText: 'Set Password',
                warning: 'Password must be at least 6 characters',
                maxlines: 1,
                isHide: true,
                showEye: true,
                prefixIcon: Icon(Icons.lock_outline, color: styles.primary),
              ),
              const SizedBox(height: 30),

              // Hotel ID Display
              TextFormField(
                style: TextStyle(fontWeight: FontWeight.bold, color: styles.primary),
                controller: _hotelIdController,
                decoration: InputDecoration(
                  labelText: 'Hotel ID',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: styles.primary),
                  ),
                  filled: true,
                  fillColor: Colors.red[100],
                  prefixIcon: Icon(Icons.account_box_outlined, color: styles.primary),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.refresh, color: styles.primary),
                    onPressed: _generateHotelId,
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 20),

              // Register Button
              CustomButton(
                buttonText: 'Register',
                onPressed: _registerHotel,
                isLoading: _isLoading,
                child: _isLoading
                    ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}