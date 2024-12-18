import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preownedhub/models/product.dart';
import 'package:preownedhub/provider/cart_provider.dart';
import 'package:preownedhub/provider/product_provider.dart';
import 'package:preownedhub/servics/firebase_service.dart';

final paymentMethodProvider =
    StateProvider<String>((ref) => ''); // State for payment method

class ProductDetailsPage extends ConsumerWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.network(
                product.image,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              product.name,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Price: RM${product.price}',
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              'Description: ${product.description}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    if (product.status != 'sold') {
                      // Show the dialog to enter delivery address
                      _showBuyDialog(context, ref);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('This product is already sold!')),
                      );
                    }
                  },
                  child: const Text('Buy Now'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    if (product.status != 'sold') {
                      ref.read(cartProvider.notifier).addToCart(product);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Added to Cart!')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('This product is already sold!')),
                      );
                    }
                  },
                  child: const Text('Add to Cart'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Function to show a dialog for entering delivery address
  void _showBuyDialog(BuildContext context, WidgetRef ref) {
    final addressController = TextEditingController();
    final isFreeProduct = product.price == 0; // Check if the product is free

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Delivery Address'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Address',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                if (!isFreeProduct) ...[
                  const SizedBox(height: 10),
                  const Text('Choose Payment Method'),
                  Consumer(
                    builder: (context, ref, _) {
                      final selectedPaymentMethod =
                          ref.watch(paymentMethodProvider);
                      return Column(
                        children: [
                          ListTile(
                            title: const Text('Cash on Delivery'),
                            leading: Radio<String>(
                              value: 'COD',
                              groupValue: selectedPaymentMethod,
                              activeColor: Colors.black,
                              onChanged: (value) {
                                if (value != null) {
                                  ref.read(paymentMethodProvider.notifier).state = value;
                                }
                              },
                            ),
                          ),
                          ListTile(
                            title: const Text('Pay by Card'),
                            leading: Radio<String>(
                              value: 'Card',
                              groupValue: selectedPaymentMethod,
                              activeColor: Colors.black,
                              onChanged: (value) {
                                if (value != null) {
                                  ref.read(paymentMethodProvider.notifier).state = value;
                                }
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (addressController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an address')));
                  return;
                }

                if (isFreeProduct) {
                  // Directly process the free product
                  await _processFreeOrder(context, addressController.text, ref);
                } else {
                  String paymentMethod = ref.read(paymentMethodProvider);
                  if (paymentMethod == 'COD') {
                    await _processCashOnDelivery(context, addressController.text, ref);
                  } else if (paymentMethod == 'Card') {
                    await _processCardPayment(context, addressController.text, ref);
                  }
                }
              },
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processFreeOrder(
      BuildContext context, String address, WidgetRef ref) async {
    await FirebaseService.updateProductStatus(product.id, 'sold');
    await FirebaseService.addBuyerToProduct(
        product.id, 'buyerID'); // Update with actual buyer ID
    await FirebaseService.addDeliveryDetails(
        product.id, address, product); // Save delivery address

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')));
    ref.read(productProvider.notifier).refreshProducts();
    Navigator.of(context).pop(); // Close the dialog
  }

  Future<void> _processCashOnDelivery(
      BuildContext context, String address, WidgetRef ref) async {
    await FirebaseService.updateProductStatus(product.id, 'sold');
    await FirebaseService.addBuyerToProduct(product.id, 'buyerID');
    await FirebaseService.addDeliveryDetails(product.id, address, product);

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed with Cash on Delivery!')));
    ref.read(productProvider.notifier).refreshProducts();
    Navigator.of(context).pop(); // Close the dialog
  }

  Future<void> _processCardPayment(
      BuildContext context, String address, WidgetRef ref) async {
    TextEditingController cardController = TextEditingController();
    TextEditingController cvvController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Card Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cardController,
                decoration: const InputDecoration(labelText: 'Card Number'),
              ),
              TextField(
                controller: cvvController,
                decoration: const InputDecoration(labelText: 'CVV'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the card dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                bool isValid = cardController.text.isNotEmpty &&
                    cvvController.text.isNotEmpty;
                if (isValid) {
                  await FirebaseService.updateProductStatus(product.id, 'sold');
                  await FirebaseService.addBuyerToProduct(product.id, 'buyerID');
                  await FirebaseService.addDeliveryDetails(
                      product.id, address, product);

                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Order placed successfully!')));
                  ref.read(productProvider.notifier).refreshProducts();
                  Navigator.of(context).pop(); // Close the card dialog
                  Navigator.of(context).pop(); // Close the main dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid Card Details')));
                }
              },
              child: const Text('Proceed with Payment'),
            ),
          ],
        );
      },
    );
  }
}
