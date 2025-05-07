// set_topmenu_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:voiceats/custom%20widgets/custom_appbar.dart';
import 'package:voiceats/custom%20widgets/custom_button.dart';
import 'package:voiceats/custom%20widgets/custom_inputfield.dart';
import 'package:voiceats/custom%20widgets/head_title.dart';
import 'package:voiceats/custom%20widgets/styles.dart';

class SetTopMenuScreen extends StatefulWidget {
  const SetTopMenuScreen({super.key});

  @override
  State<SetTopMenuScreen> createState() => _SetTopMenuScreenState();
}

class _SetTopMenuScreenState extends State<SetTopMenuScreen> {
  final TextEditingController _menuItemController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;
  List<Map<String, dynamic>> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _loadMenuItems();
  }

  Future<void> _loadMenuItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final doc = await _firestore.collection('Hotels').doc(user.uid).get();
      if (doc.exists && doc.data()?['topMenu'] != null) {
        final menuData = doc.data()?['topMenu'] as List;
        setState(() {
          _menuItems = List<Map<String, dynamic>>.from(menuData);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading menu items: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addMenuItem() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_menuItemController.text.isNotEmpty &&
        _priceController.text.isNotEmpty) {
      setState(() => _isLoading = true);
      try {
        final newItem = {
          'name': _menuItemController.text,
          'price': 'Rs.${_priceController.text}',
          'image': '',
        };

        await _firestore.collection('Hotels').doc(user.uid).update({
          'topMenu': FieldValue.arrayUnion([newItem]),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _menuItems.add(newItem);
          _menuItemController.clear();
          _priceController.clear();
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Menu item added successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding menu item: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _removeMenuItem(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final itemToRemove = _menuItems[index];

      await _firestore.collection('Hotels').doc(user.uid).update({
        'topMenu': FieldValue.arrayRemove([itemToRemove]),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _menuItems.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Menu item removed successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing menu item: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddMenuItemDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: HeadTitle(title: 'Add Menu Item',),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomInputField(controller: _menuItemController, labelText: 'Item Name', warning: "Please Enter Menu Item."),
            const SizedBox(height: 10),
            CustomInputField(controller: _priceController, labelText: 'Price', warning: "Please Correct Price."),
          ],
        ),
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
                      buttonText: "Add",
                      onPressed: _addMenuItem,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppbar(
        appbarTitle: 'Set Top Menu',
        actions: [
          IconButton(
            icon:  Icon(Icons.add, color: styles.primary,),
            onPressed: _showAddMenuItemDialog,
          ),
        ],
      ),
      // appBar: AppBar(
      //   title: const Text('Top Menu'),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.add),
      //       onPressed: _showAddMenuItemDialog,
      //     ),
      //   ],
      // ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final item = _menuItems[index];
                      return Card(
                        color: styles.primary,
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 2,
                        child: ListTile(
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                item['image'] == null || item['image'].isEmpty
                                    ? const Icon(Icons.fastfood,
                                        size: 30, color: Colors.grey)
                                    : ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(item['image'],
                                            fit: BoxFit.cover),
                                      ),
                          ),
                          title: Text(
                            item['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 18),
                          ),
                          subtitle: Text(
                            item['price'],
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.white),
                            onPressed: () => _removeMenuItem(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _menuItemController.dispose();
    _priceController.dispose();
    super.dispose();
  }
}
