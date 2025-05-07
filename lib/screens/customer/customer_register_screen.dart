import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voiceats/custom%20widgets/custom_appbar.dart';
import 'package:voiceats/custom%20widgets/styles.dart';
import '../../custom widgets/custom_inputfield.dart';
import '../../custom widgets/custom_button.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  _CustomerRegisterScreenState createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  int? _selectedProfileIndex;

  // List of predefined profile image asset paths
  final List<String> _profileImages = [
    'assets/profile1.png',
    'assets/profile2.png',
    'assets/profile3.png',
    'assets/profile4.png',
    'assets/profile5.png',
    'assets/profile6.png',
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _generateRandomName();
  }

  void _generateRandomName() {
    const adjectives = ['Spicy', 'Aromatic', 'Flavorful', 'Tangy', 'Creamy', 'Savory', 'Zesty', 'Fiery', 'Fragrant', 'Rich', "Tandoori"];
    const nouns = ['Manchurian', 'Chicken', 'Biryani', 'Noodles', 'Dosa', 'Samosa', 'Paneer', 'Panipuri', 'Naan', 'Vadapav', 'Pavbhaji'];
    final randomAdj = adjectives[(DateTime.now().millisecond % adjectives.length)];
    final randomNoun = nouns[(DateTime.now().second % nouns.length)];
    final randomNum = (DateTime.now().millisecond % 1000).toString().padLeft(3, '0');
    _nameController.text = '$randomAdj$randomNoun$randomNum';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProfileIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a profile image')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Create auth user
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Update user display name
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      // 3. Save to Firestore (using both collections for compatibility)
      final userData = {
        'profileImageIndex': _selectedProfileIndex,
        'aiGeneratedName': _nameController.text.trim(),
        'customerContact': _contactController.text.trim(),
        'email': _emailController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
        'userType': "customer",
      };

      final batch = _firestore.batch();


      // Write to Customers collection (if needed)
      final customerRef = _firestore.collection('Customers').doc(userCredential.user?.uid);
      batch.set(customerRef, userData);

      await batch.commit();

      // 4. Save to local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstTime', false);
      await prefs.setInt('profileImageIndex', _selectedProfileIndex!);

      // 5. Navigate on success
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);

    } on FirebaseAuthException catch (e) {
      String errorMessage = _handleAuthError(e.code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database error: ${e.message}')),
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
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppbar(appbarTitle: 'Create Customer Account'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Image Selection Section
              Text(
                'Select Profile Image',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: styles.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: _profileImages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedProfileIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedProfileIndex == index
                              ? styles.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          _profileImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),

              // AI Generated Name (non-editable)
              TextFormField(
                style: TextStyle(fontWeight: FontWeight.bold, color: styles.primary),
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'AI Generated Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  filled: true,
                  fillColor: Colors.red[100],
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.refresh, color: styles.primary),
                    onPressed: _generateRandomName,
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 20),

              // Contact Number Field
              CustomInputField(
                controller: _contactController,
                labelText: 'Customer Contact',
                warning: 'Please enter a valid contact number',
                keyboardType: TextInputType.phone,
                prefix: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text('+91', style: TextStyle(fontSize: 16)),
                ),
                prefixIcon: Icon(Icons.phone, color: styles.primary),
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
                labelText: 'Password',
                warning: 'Password must be at least 6 characters',
                isHide: true,
                showEye: true,
                maxlines: 1,
                prefixIcon: Icon(Icons.lock_outline, color: styles.primary),
              ),
              const SizedBox(height: 30),

              // Register Button
              CustomButton(
                buttonText: 'Register',
                onPressed: _register,
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