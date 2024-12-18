import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:preownedhub/models/product.dart';

// Create a provider for fetching and managing product state
final productProvider = StateNotifierProvider<ProductStateNotifier, ProductState>((ref) {
  return ProductStateNotifier();
});

// Define the product state
class ProductState {
  final List<Product> allProducts;
  final List<Product> filteredProducts;
  final String searchQuery;

  ProductState({
    required this.allProducts,
    required this.filteredProducts,
    required this.searchQuery,
  });

  // Default state
  factory ProductState.initial() {
    return ProductState(
      allProducts: [],
      filteredProducts: [],
      searchQuery: '',
    );
  }

  // Method to apply search and filter changes
  ProductState copyWith({
    List<Product>? allProducts,
    List<Product>? filteredProducts,
    String? searchQuery,
  }) {
    return ProductState(
      allProducts: allProducts ?? this.allProducts,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

// StateNotifier to handle product-related logic (fetch, search, filter)
class ProductStateNotifier extends StateNotifier<ProductState> {
  ProductStateNotifier() : super(ProductState.initial());

  // Fetch products from Firestore
  Future<void> fetchProducts() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('products').get();
      List<Product> products = snapshot.docs.map((doc) {
        return Product.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      state = state.copyWith(
        allProducts: products,
        filteredProducts: products,
      );
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  // Trigger a refresh of the product list
  Future<void> refreshProducts() async {
    await fetchProducts();
  }

  // Search for products based on the query
  void searchProducts(String query) {
    state = state.copyWith(searchQuery: query);
    _filterProducts();
  }

  // Filter products based on search query and tab
  void _filterProducts() {
    List<Product> filtered = state.allProducts;

    // Apply search filter
    if (state.searchQuery.isNotEmpty) {
      filtered = filtered
          .where((product) =>
              product.name.toLowerCase().contains(state.searchQuery.toLowerCase()))
          .toList();
    }

    state = state.copyWith(filteredProducts: filtered);
  }

  // Filter products based on tab selection (e.g., donated items)
  void filterByTab(int tabIndex) {
    List<Product> filtered = state.allProducts;

    if (tabIndex == 1) {
      // For Donated Products tab, filter out those with price 0
      filtered = filtered
          .where((product) =>
              product.isDonatedItem == true && product.price == 0)
          .toList();
    }

    // Apply search filter again
    _filterProducts();

    state = state.copyWith(filteredProducts: filtered);
  }
}
