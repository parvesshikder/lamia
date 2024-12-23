import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preownedhub/provider/product_provider.dart';

class SellPage extends ConsumerStatefulWidget {
  const SellPage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SellPageState();
}

class _SellPageState extends ConsumerState<SellPage> {

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  bool _isDonatedItem = false; // Toggle for donated items
  bool _isUploading = false;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload product details to Firestore
  Future<void> _uploadProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _imageUrlController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Ensure that the user is logged in
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in. Please log in.')),
        );
        return;
      }

      // Add product to Firestore
      await _firestore.collection('products').add({
        'name': _nameController.text,
        'price': _isDonatedItem ? '0.00' : _priceController.text,
        'description': _descriptionController.text,
        'image': _imageUrlController.text,
        'sellerId': currentUser.uid, // Ensure user is logged in
        'buyerId': null, // Initially null
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'Available', // Available or Sold
        'isDonatedItem': _isDonatedItem, // Mark as donated item
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product uploaded successfully!')),
      );

      // Clear inputs
      _nameController.clear();
      _priceController.clear();
      _descriptionController.clear();
      _imageUrlController.clear();
      setState(() {
        _isDonatedItem = false;
      });

      // Refresh products in the HomePage
      ref.read(productProvider.notifier).refreshProducts(); // Refresh the product list

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading product: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Add Product to Sell'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Price Field
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
              keyboardType: TextInputType.number,
              enabled: !_isDonatedItem, // Disable if "Donate Item" is toggled
            ),
            const SizedBox(height: 10),
            // Donate Item Toggle
            Row(
              children: [
                const Text(
                  'Donate Item:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Switch(
                  value: _isDonatedItem,
                  onChanged: (value) {
                    setState(() {
                      _isDonatedItem = value;
                      if (_isDonatedItem) {
                        _priceController.text = '0.00';
                      } else {
                        _priceController.clear(); // Clear if toggled off
                      }
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Product Description
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            // Image URL Input
            TextField(
              controller: _imageUrlController,
              decoration: InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: Colors.blue, width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Upload Button
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _uploadProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlueAccent,
                    ),
                    child: const Text('Upload Product'),
                  ),
          ],
        ),
      ),
    );
  }
}
