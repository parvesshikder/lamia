import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:preownedhub/models/product.dart';

// Define a CartProvider to hold the cart state
class CartNotifier extends StateNotifier<List<Product>> {
  CartNotifier() : super([]);

  // Add product to the cart
  void addToCart(Product product) {
    state = [...state, product];
  }

  // Get all products in the cart
  List<Product> getCartItems() {
    return state;
  }

    void removeProduct(Product product) {
    state = state.where((item) => item.id != product.id).toList();
  }

  void clearCart() {
    state = [];
  }
}

// CartProvider to manage cart state
final cartProvider = StateNotifierProvider<CartNotifier, List<Product>>((ref) {
  return CartNotifier();
});
