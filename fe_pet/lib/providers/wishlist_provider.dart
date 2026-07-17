import 'package:flutter/material.dart';
import '../domain/entities/product.dart';
import '../services/wishlist_service.dart';

class WishlistProvider extends ChangeNotifier {
  final WishlistService _wishlistService = WishlistService();

  final Set<int> _wishlistIds = {};
  List<Product> _wishlistProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  Set<int> get wishlistIds => _wishlistIds;
  List<Product> get wishlistProducts => _wishlistProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isWishlisted(int productId) {
    return _wishlistIds.contains(productId);
  }

  // Initial load
  Future<void> loadWishlist() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final products = await _wishlistService.getWishlist();
      _wishlistProducts = products;
      _wishlistIds.clear();
      _wishlistIds.addAll(products.map((p) => p.productId));
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh
  Future<void> refresh() async {
    await loadWishlist();
  }

  // Optimistic add
  Future<void> add(Product product) async {
    final int pid = product.productId;
    if (_wishlistIds.contains(pid)) return;

    // Optimistically update
    _wishlistIds.add(pid);
    _wishlistProducts.insert(0, product);
    notifyListeners();

    try {
      await _wishlistService.addToWishlist(pid);
    } catch (e) {
      // Rollback
      _wishlistIds.remove(pid);
      _wishlistProducts.removeWhere((p) => p.productId == pid);
      notifyListeners();
      rethrow;
    }
  }

  // Optimistic remove
  Future<void> remove(int productId) async {
    if (!_wishlistIds.contains(productId)) return;

    // Save for potential rollback
    final index = _wishlistProducts.indexWhere((p) => p.productId == productId);
    Product? backupProduct;
    if (index != -1) {
      backupProduct = _wishlistProducts[index];
    }

    // Optimistically update
    _wishlistIds.remove(productId);
    _wishlistProducts.removeWhere((p) => p.productId == productId);
    notifyListeners();

    try {
      await _wishlistService.removeFromWishlist(productId);
    } catch (e) {
      // Rollback
      _wishlistIds.add(productId);
      if (backupProduct != null && index != -1) {
        _wishlistProducts.insert(index, backupProduct);
      }
      notifyListeners();
      rethrow;
    }
  }

  // Toggle helper
  Future<void> toggle(Product product) async {
    final int pid = product.productId;
    if (_wishlistIds.contains(pid)) {
      await remove(pid);
    } else {
      await add(product);
    }
  }
}
