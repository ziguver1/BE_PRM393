import 'package:flutter/material.dart';
import '../data/models/cart_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();

  CartResponse? _cart;
  bool _isLoading = false;
  String? _errorMessage;
  final Set<int> _selectedCartItemIds = <int>{};

  CartResponse? get cart => _cart;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Set<int> get selectedCartItemIds => Set.unmodifiable(_selectedCartItemIds);

  int get totalItems {
    if (_cart == null) return 0;
    return _cart!.items.fold(0, (sum, item) => sum + item.quantity);
  }

  bool get allSelected {
    if (_cart == null || _cart!.items.isEmpty) return false;
    return _cart!.items.every(
      (item) => _selectedCartItemIds.contains(item.cartItemId),
    );
  }

  bool isSelected(int cartItemId) => _selectedCartItemIds.contains(cartItemId);

  double get selectedTotal {
    if (_cart == null) return 0;
    return _cart!.items
        .where((item) => _selectedCartItemIds.contains(item.cartItemId))
        .fold(0.0, (sum, item) {
          return sum + (item.quantity * item.product.price);
        });
  }

  int get selectedItemCount => _selectedCartItemIds.length;

  void toggleSelectItem(int cartItemId) {
    if (_selectedCartItemIds.contains(cartItemId)) {
      _selectedCartItemIds.remove(cartItemId);
    } else {
      _selectedCartItemIds.add(cartItemId);
    }
    notifyListeners();
  }

  void toggleSelectAll() {
    if (_cart == null) return;
    if (allSelected) {
      _selectedCartItemIds.clear();
    } else {
      for (final item in _cart!.items) {
        _selectedCartItemIds.add(item.cartItemId);
      }
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedCartItemIds.clear();
    notifyListeners();
  }

  // Load the shopping cart from backend
  Future<void> fetchCart({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _cart = await _cartService.getCart();
      if (_cart != null) {
        final existingIds = _cart!.items.map((item) => item.cartItemId).toSet();
        _selectedCartItemIds.retainWhere(existingIds.contains);
        if (_selectedCartItemIds.isEmpty && _cart!.items.isNotEmpty) {
          for (final item in _cart!.items) {
            _selectedCartItemIds.add(item.cartItemId);
          }
        }
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add an item to the cart
  Future<bool> addToCart(int productId, int quantity, {String? selectedVariant}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _cartService.addToCart(productId, quantity, selectedVariant: selectedVariant);
      // Fetch fresh cart data to sync
      await fetchCart(silent: true);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update cart item quantity with Optimistic Updates
  Future<bool> updateQuantity(int cartItemId, int newQuantity) async {
    if (newQuantity <= 0) {
      return removeFromCart(cartItemId);
    }

    if (_cart == null) return false;

    // Save previous state for rollback
    final previousCart = _cart;

    // Optimistically update local state
    final updatedItems = _cart!.items.map((item) {
      if (item.cartItemId == cartItemId) {
        return CartItem(
          cartItemId: item.cartItemId,
          userId: item.userId,
          productId: item.productId,
          quantity: newQuantity,
          selectedVariant: item.selectedVariant,
          product: item.product,
        );
      }
      return item;
    }).toList();

    // Recalculate total total
    double newTotal = updatedItems.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.product.price),
    );

    _cart = CartResponse(items: updatedItems, total: newTotal);
    _errorMessage = null;
    notifyListeners();

    try {
      await _cartService.updateCartItem(cartItemId, newQuantity);
      return true;
    } catch (e) {
      // Rollback on error
      _cart = previousCart;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  // Remove item from cart with Optimistic Updates
  Future<bool> removeFromCart(int cartItemId) async {
    if (_cart == null) return false;

    // Save previous state for rollback
    final previousCart = _cart;

    // Optimistically remove from local state
    final updatedItems = _cart!.items
        .where((item) => item.cartItemId != cartItemId)
        .toList();

    // Recalculate total total
    double newTotal = updatedItems.fold(
      0.0,
      (sum, item) => sum + (item.quantity * item.product.price),
    );

    _cart = CartResponse(items: updatedItems, total: newTotal);
    _errorMessage = null;
    notifyListeners();

    try {
      await _cartService.removeCartItem(cartItemId);
      return true;
    } catch (e) {
      // Rollback on error
      _cart = previousCart;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
