import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:preownedhub/models/product.dart';

class FirebaseService {
  static Future<void> updateProductStatus(
      String productId, String status) async {
    // Update the status of the product in Firebase
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update({
      'status': status,
    });
  }

  static Future<void> addBuyerToProduct(
      String productId, String buyerId) async {
    // Add buyer information to the product in Firebase
    await FirebaseFirestore.instance
        .collection('products')
        .doc(productId)
        .update({
      'buyerId': FirebaseAuth.instance.currentUser!.uid,
    });
  }

  static Future<void> addDeliveryDetails(
    String productId, String address, String phone, Product product) async {
  // Create the order data
  Map<String, dynamic> orderData = {
    'productId': productId,
    'address': address,
    'status': 'pending', // Initial order status
    'totalPrice': product.price, // Include product price
    'productName': product.name, // Include product name
    'paymentStatus': 'pending', // Default payment status
    'orderDate': DateTime.now().toIso8601String(), // Save the order date
    'sellerId': product.sellerId, // Include seller ID if needed
    'buyerId': FirebaseAuth.instance.currentUser!.uid,
    'orderId': product.id,
    'phone': phone,
  };

  // Save the order to Firebase using a unique productId
  try {
    await FirebaseFirestore.instance.collection('orders').doc(productId).set(orderData);
  } catch (e) {
    print('Error saving order: $e');
  }
}

}