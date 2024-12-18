import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String image;
  final bool isDonatedItem;
  final String sellerId;
  final String status;
  final String? buyerId;
  final DateTime timestamp;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.image,
    required this.isDonatedItem,
    required this.sellerId,
    required this.status,
    this.buyerId,
    required this.timestamp,
  });

    // Create a Product from a Map (JSON)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'],
      status: json['status'],
      image: json['image'],
      isDonatedItem: json['isDonatedItem'],
      description: json['description'],
      sellerId: json['buyerId'],
      timestamp: json['timestamp'],
    );
  }

  // Convert a Product into a Map (JSON) using toJson method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'status': status,
      'image': image,
      'isDonatedItem': isDonatedItem,
      
    };
  }

  // Create a factory constructor to convert Firestore data to Product
  factory Product.fromFirestore(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      price: _parsePrice(data['price']),
      description: data['description'] ?? '',
      image: data['image'] ?? '',
      isDonatedItem: data['isDonatedItem'] ?? false,
      sellerId: data['sellerId'] ?? '',
      status: data['status'] ?? 'Unavailable',
      buyerId: data['buyerId'],
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  // Helper method to parse price from string to double
  static double _parsePrice(dynamic price) {
    if (price is String) {
      return double.tryParse(price) ?? 0.0; // Safe conversion
    }
    return price?.toDouble() ?? 0.0;
  }
}
