import 'package:flutter/material.dart';
import '../data/models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider extends ChangeNotifier {
  final ProductService _productService = ProductService();

  // State management
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  final int _limit = 10;

  // Current filters
  int? _categoryId;
  String? _filterString;
  String? _searchQuery;

  // Getters
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get total => _total;
  int? get categoryId => _categoryId;
  String? get filterString => _filterString;
  String? get searchQuery => _searchQuery;

  /// Load products with optional filters
  Future<void> loadProducts({
    int page = 1,
    int? categoryId,
    String? filters,
    String? search,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = page;
      _categoryId = categoryId;
      _filterString = filters;
      _searchQuery = search;
      notifyListeners();

      final paginatedData = await _productService.fetchProducts(
        page: page,
        limit: _limit,
        categoryId: categoryId,
        filters: filters,
        search: search,
      );

      _products = paginatedData.data;
      _totalPages = paginatedData.totalPages;
      _total = paginatedData.total;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  /// Apply filters and refresh products
  Future<void> applyFilters(String filterString) async {
    await loadProducts(
      page: 1,
      categoryId: _categoryId,
      filters: filterString,
      search: _searchQuery,
    );
  }

  /// Filter by category
  Future<void> filterByCategory(int? categoryId) async {
    await loadProducts(
      page: 1,
      categoryId: categoryId,
      filters: _filterString,
      search: _searchQuery,
    );
  }

  /// Search products
  Future<void> searchProducts(String query) async {
    await loadProducts(
      page: 1,
      categoryId: _categoryId,
      filters: _filterString,
      search: query,
    );
  }

  /// Load next page
  Future<void> loadNextPage() async {
    if (_currentPage < _totalPages) {
      await loadProducts(
        page: _currentPage + 1,
        categoryId: _categoryId,
        filters: _filterString,
        search: _searchQuery,
      );
    }
  }

  /// Load previous page
  Future<void> loadPreviousPage() async {
    if (_currentPage > 1) {
      await loadProducts(
        page: _currentPage - 1,
        categoryId: _categoryId,
        filters: _filterString,
        search: _searchQuery,
      );
    }
  }

  /// Reset filters and reload initial data
  Future<void> resetFilters() async {
    await loadProducts(page: 1);
  }

  /// Get product by ID from current list
  ProductModel? getProductById(int productId) {
    try {
      return _products.firstWhere(
        (product) => product.productId == productId,
      );
    } catch (e) {
      return null;
    }
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
