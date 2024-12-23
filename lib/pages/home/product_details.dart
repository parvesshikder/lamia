import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preownedhub/models/product.dart';
import 'package:preownedhub/pages/home/cart.dart';
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
    final cartItems = ref.watch(cartProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  // Navigate to Cart Page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(),
                    ),
                  );
                },
              ),
              if (cartItems
                  .isNotEmpty) // Only show the badge if cart is not empty
                Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      cartItems.length.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
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
                  onPressed: product.sellerId ==
                          FirebaseAuth.instance.currentUser?.uid
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text("You can't buy your own product!")),
                          );
                        }
                      : () {
                          if (product.status != 'sold') {
                            // Show the dialog to enter delivery address
                            _showBuyDialog(context, ref);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('This product is already sold!')),
                            );
                          }
                        },
                  child: const Text('Buy Now'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: product.sellerId ==
                          FirebaseAuth.instance.currentUser?.uid
                      ? () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "You can't add your own product to the cart!")),
                          );
                        }
                      : () {
                          if (product.status != 'sold') {
                            ref.read(cartProvider.notifier).addToCart(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to Cart!')),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('This product is already sold!')),
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
    final phoneController = TextEditingController();
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
                SizedBox(height: 5,),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 1,
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
                                  ref
                                      .read(paymentMethodProvider.notifier)
                                      .state = value;
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
                                  ref
                                      .read(paymentMethodProvider.notifier)
                                      .state = value;
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
                  await _processFreeOrder(context, addressController.text,
                      phoneController.text, ref);
                } else {
                  String paymentMethod = ref.read(paymentMethodProvider);
                  if (paymentMethod == 'COD') {
                    await _processCashOnDelivery(context,
                        addressController.text, phoneController.text, ref);
                  } else if (paymentMethod == 'Card') {
                    await _processCardPayment(context, addressController.text,
                        phoneController.text, ref);
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
      BuildContext context, String address, String phone, WidgetRef ref) async {
    await FirebaseService.updateProductStatus(product.id, 'sold');
    await FirebaseService.addBuyerToProduct(
        product.id, 'buyerID'); // Update with actual buyer ID
    await FirebaseService.addDeliveryDetails(
        product.id, address, phone, product); // Save delivery address

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')));
    ref.read(productProvider.notifier).refreshProducts();
    Navigator.of(context).pop(); // Close the dialog
  }

  Future<void> _processCashOnDelivery(
      BuildContext context, String address, String phone, WidgetRef ref) async {
    await FirebaseService.updateProductStatus(product.id, 'sold');
    await FirebaseService.addBuyerToProduct(product.id, 'buyerID');
    await FirebaseService.addDeliveryDetails(
        product.id, address, phone, product);

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed with Cash on Delivery!')));
    ref.read(productProvider.notifier).refreshProducts();
    Navigator.of(context).pop(); // Close the dialog
  }

  Future<void> _processCardPayment(
      BuildContext context, String address, String phone, WidgetRef ref) async {
    TextEditingController cardController = TextEditingController();
    TextEditingController cvvController = TextEditingController();
final GlobalKey<FormState> _cardFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Card Details'),
          content: Form(
            key: _cardFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: cardController,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 16, // Limit to 16 digits for card numbers
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a card number';
                    }
                    // Basic Visa/MasterCard pattern: starts with 4 (Visa) or 5 (MasterCard) and is 16 digits long
                    final cardPattern =
                        RegExp(r'^(4[0-9]{15}|5[1-5][0-9]{14})$');
                    if (!cardPattern.hasMatch(value)) {
                      return 'Enter a valid Visa or MasterCard number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 3, // CVV is typically 3 digits
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the CVV';
                    }
                    if (value.length != 3 ||
                        !RegExp(r'^\d{3}$').hasMatch(value)) {
                      return 'Enter a valid 3-digit CVV';
                    }
                    return null;
                  },
                ),
              ],
            ),
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
                  if (_cardFormKey.currentState?.validate() ?? false) {

                bool isValid = cardController.text.isNotEmpty &&
                    cvvController.text.isNotEmpty;
                if (isValid) {
                  await FirebaseService.updateProductStatus(product.id, 'sold');
                  await FirebaseService.addBuyerToProduct(
                      product.id, 'buyerID');
                  await FirebaseService.addDeliveryDetails(
                      product.id, address, phone, product);

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Order placed successfully!')));
                  ref.read(productProvider.notifier).refreshProducts();
                  Navigator.of(context).pop(); // Close the card dialog
                  Navigator.of(context).pop(); // Close the main dialog
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invalid Card Details')));
                }
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
