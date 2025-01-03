import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preownedhub/models/product.dart';
import 'package:preownedhub/provider/cart_provider.dart';
import 'package:preownedhub/provider/product_provider.dart';
import 'package:preownedhub/servics/firebase_service.dart';

final paymentMethodProvider =
    StateProvider<String>((ref) => ''); // State for payment method

class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the cart items
    final cartItems = ref.watch(cartProvider);

    // Calculate the total price of all items in the cart
    double totalPrice = 0;
    for (var product in cartItems) {
      totalPrice += product.price;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: cartItems.isEmpty
          ? const Center(child: Text('Your cart is empty'))
          : Column(
              children: [
                // Cart items list
                Expanded(
                  child: ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final product = cartItems[index];
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.all(8.0),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: Image.network(
                              product.image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(product.name),
                          subtitle: Text('Price: RM${product.price}'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              // Show the dialog to enter delivery address and choose payment method
                              _showBuyDialog(context, ref, totalPrice, product);
                            },
                            child: const Text('Buy Now'),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Total price display
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Total Price: RM${totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
    );
  }

  // Function to show a dialog for entering delivery address and choosing payment method
  void _showBuyDialog(
      BuildContext context, WidgetRef ref, double totalPrice, Product product) {
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
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
                const SizedBox(height: 5),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 10),
                if (product.price >
                    0) // Only show payment options for products with a price
                  const Text('Choose Payment Method'),
                if (product.price > 0)
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
                // Validate the delivery address
                if (addressController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter an address')));
                  return;
                }

                // Handle the order based on product price
                if (product.price == 0) {
                  await _processFreeOrder(context, ref, addressController.text,
                      phoneController.text, product);
                } else {
                  String paymentMethod = ref.read(paymentMethodProvider);
                  if (paymentMethod == 'COD') {
                    await _processCashOnDelivery(
                        context,
                        ref,
                        addressController.text,
                        addressController.text,
                        totalPrice,
                        product);
                  } else if (paymentMethod == 'Card') {
                    await _processCardPayment(
                        context,
                        ref,
                        addressController.text,
                        addressController.text,
                        totalPrice,
                        product);
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

  Future<void> _processFreeOrder(BuildContext context, WidgetRef ref,
      String address, String phone, Product product) async {
    // Update the product status as 'sold' and save delivery details
    await FirebaseService.updateProductStatus(product.id, 'sold');
    await FirebaseService.addBuyerToProduct(
        product.id, 'buyerID'); // Update with actual buyer ID
    await FirebaseService.addDeliveryDetails(
        product.id, address, phone, product);

    // Remove product from the cart
    ref.read(cartProvider.notifier).removeProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully!')));
    Navigator.of(context).pop(); // Close the dialog

    ref.read(productProvider.notifier).refreshProducts();
  }

  Future<void> _processCashOnDelivery(BuildContext context, WidgetRef ref,
      String address, String phone, double totalPrice, Product product) async {
    // Assuming you have a method in FirebaseService to update the order status
    await FirebaseService.updateProductStatus(product.id, 'sold');
    await FirebaseService.addBuyerToProduct(
        product.id, 'buyerID'); // Update with actual buyer ID
    await FirebaseService.addDeliveryDetails(
        product.id, address, address, product); // Save delivery address

    // Remove product from the cart
    ref.read(cartProvider.notifier).removeProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed with Cash on Delivery!')));
    Navigator.of(context).pop(); // Close the dialog

    ref.read(productProvider.notifier).refreshProducts();
  }

  Future<void> _processCardPayment(BuildContext context, WidgetRef ref,
      String address, String phone, double totalPrice, Product product) async {
    // Show card payment dialog and process payment
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
                Navigator.of(context).pop(); // Close the card details dialog
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_cardFormKey.currentState?.validate() ?? false) {
                // Validate card details (for demo, assume valid card)
                bool isValid = cardController.text.isNotEmpty &&
                    cvvController.text.isNotEmpty;
                if (isValid) {
                  await FirebaseService.updateProductStatus(product.id, 'sold');
                  await FirebaseService.addBuyerToProduct(
                      product.id, 'buyerID');
                  await FirebaseService.addDeliveryDetails(product.id, address,
                      phone, product); // Save delivery address

                  // Remove product from the cart
                  ref.read(cartProvider.notifier).removeProduct(product);

                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Order placed with Card Payment!')));
                  ref.read(productProvider.notifier).refreshProducts();
                  Navigator.of(context).pop(); // Close the dialog
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
