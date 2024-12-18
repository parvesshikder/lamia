class Order {
  final String sellerId;
  final String buyerId;
  final String productId;
  final String productName;
  final double totalPrice;
  final String paymentStatus;
  final String status;
  final String address;
  final DateTime orderDate;

  Order({
    required this.sellerId,
    required this.buyerId,
    required this.productId,
    required this.productName,
    required this.totalPrice,
    required this.paymentStatus,
    required this.status,
    required this.address,
    required this.orderDate,
  });

  factory Order.fromFirestore(Map<String, dynamic> data) {
    return Order(
      sellerId: data['sellerId'] as String,
      buyerId: data['buyerId'] as String,
      productId: data['productId'] as String,
      productName: data['productName'] as String,
      totalPrice: (data['totalPrice'] as num).toDouble(),
      paymentStatus: data['paymentStatus'] as String,
      status: data['status'] as String,
      address: data['address'] as String,
      orderDate: DateTime.parse(data['orderDate'] as String),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'buyerId': buyerId,
      'productId': productId,
      'productName': productName,
      'totalPrice': totalPrice,
      'paymentStatus': paymentStatus,
      'status': status,
      'address': address,
      'orderDate': orderDate.toIso8601String(),
    };
  }
}
