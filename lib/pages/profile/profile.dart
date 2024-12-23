import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:preownedhub/pages/profile/my_products.dart';
import 'package:preownedhub/pages/profile/oder.dart';

final currentUserProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) throw Exception('User not logged in');

  final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(userId).get();
  if (!userDoc.exists) throw Exception('User details not found');

  return userDoc.data()!;
});

final userOrdersProvider =
    FutureProvider<Map<String, List<Map<String, dynamic>>>>((ref) async {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) throw Exception('User not logged in');

  final orderDocs = await FirebaseFirestore.instance.collection('orders').get();

  final purchases = <Map<String, dynamic>>[];
  final sales = <Map<String, dynamic>>[];

  for (final order in orderDocs.docs) {
    final orderData = order.data();
    if (orderData['buyerId'] == userId) {
      purchases.add(orderData);
    } else if (orderData['sellerId'] == userId) {
      sales.add(orderData);
    }
  }

  return {'purchases': purchases, 'sales': sales};
});

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final userOrders = ref.watch(userOrdersProvider);

    return Scaffold(
      body: currentUser.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
        data: (userData) {
          final userName = userData['name'] ?? 'User';
          final userEmail = userData['email'] ?? 'No Email';
          final profilePictureUrl = userData['profilePicture'] as String?;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profilePictureUrl != null
                        ? NetworkImage(profilePictureUrl)
                        : null,
                    child: profilePictureUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // User Name and Email
                  Text(
                    userName,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userEmail,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  // Orders Section
                  userOrders.when(
                    loading: () => const CircularProgressIndicator(),
                    error: (error, stackTrace) =>
                        Center(child: Text('Error: $error')),
                    data: (ordersData) {
                      final purchases = ordersData['purchases'] ?? [];
                      final sales = ordersData['sales'] ?? [];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // My Purchases Button
                          ElevatedButton(
                            onPressed: () {
                              _navigateToOrders(
                                  context, 'My Purchases', purchases);
                            },
                            child: const Text('My Purchases'),
                          ),

                          const SizedBox(height: 8),
                          // Product Sales Button
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MyProductsPage(),
                                ),
                              );
                            },
                            child: const Text('My Products'),
                          ),

                          const SizedBox(height: 8),
                          // Product Sales Button
                          ElevatedButton(
                            onPressed: () {
                              _navigateToOrders(
                                  context, 'Product Sales', sales);
                            },
                            child: const Text('Product Sales'),
                          ),
                          SizedBox(
                            height: 200,
                          ),

                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Logout'),
                                IconButton(
                                  icon: const Icon(
                                    Icons.exit_to_app,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed: () async {
                                    await FirebaseAuth.instance.signOut();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Logged out successfully')),
                                    );
                                    Navigator.of(context)
                                        .pop(); // Navigate back to the login page
                                  },
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            height: 100,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToOrders(
      BuildContext context, String title, List<Map<String, dynamic>> orders) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrdersPage(title: title, orders: orders),
      ),
    );
  }
}
