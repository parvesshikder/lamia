import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrdersPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> orders;

  const OrdersPage({super.key, required this.title, required this.orders});

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    orders = widget.orders;
  }

  Future<void> _markAsDelivered(BuildContext context, String orderId, Map<String, dynamic> order) async {
    try {
      // Update the local order status immediately
      setState(() {
        order['status'] = 'Delivered';
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order marked as Delivered')),
      );

      // Update the order status in Firestore
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': 'Delivered'});

      // After Firestore update, you can show a confirmation (if needed)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Firestore updated successfully')),
      );
    } catch (e) {
      // Revert local change in case of failure
      setState(() {
        order['status'] = 'Pending';
      });

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: orders.isEmpty
          ? const Center(child: Text('No orders found'))
          : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final orderId = order['orderId'] ?? '';

                return Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                      child: Row(
                        children: [
                          // Product Name
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order['productName'] ?? 'Unknown Product',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                // Price
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text(
                                    'RM${order['totalPrice'] ?? '0.00'}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ),
                                // Status
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Text("Status: ${order['status']}", style: const TextStyle(fontSize: 14)),
                                ),
                              ],
                            ),
                          ),

                          // Button (if status is not delivered)
                          if (order['status'] != 'Delivered')
                            TextButton(
                              onPressed: () => _markAsDelivered(context, orderId, order),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                foregroundColor: Colors.blue,
                              ),
                              child: const Text('Mark as Delivered'),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
