import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/product.dart';
import '../../../core/configs/providers.dart';

class SearchState {
  final String query;
  final int? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;
  final String sortOrder;
  final List<Product> products;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadMore;
  final String? errorMessage;

  SearchState({
    this.query = '',
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'createdAt',
    this.sortOrder = 'desc',
    this.products = const [],
    this.page = 1,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadMore = false,
    this.errorMessage,
  });

  SearchState copyWith({
    String? query,
    int? Function()? categoryId,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    String? sortBy,
    String? sortOrder,
    List<Product>? products,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadMore,
    String? Function()? errorMessage,
  }) {
    return SearchState(
      query: query ?? this.query,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      products: products ?? this.products,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() {
    return SearchState();
  }

  Future<void> executeSearch({bool loadMore = false}) async {
    if (loadMore) {
      if (state.page >= state.totalPages || state.isLoadMore) return;
      state = state.copyWith(isLoadMore: true);
    } else {
      state = state.copyWith(isLoading: true, page: 1, products: [], errorMessage: () => null);
    }

    try {
      final repository = ref.read(productRepositoryProvider);
      final currentPage = loadMore ? state.page + 1 : 1;
      
      final result = await repository.searchProducts(
        page: currentPage,
        limit: 10,
        search: state.query.isNotEmpty ? state.query : null,
        categoryId: state.categoryId,
        minPrice: state.minPrice,
        maxPrice: state.maxPrice,
        sortBy: state.sortBy,
        sortOrder: state.sortOrder,
      );

      final updatedProducts = loadMore
          ? [...state.products, ...result.items]
          : result.items;

      state = state.copyWith(
        products: updatedProducts,
        page: currentPage,
        totalPages: result.totalPages,
        isLoading: false,
        isLoadMore: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadMore: false,
        errorMessage: () => e.toString(),
      );
    }
  }

  void updateQuery(String query) {
    state = state.copyWith(query: query);
    executeSearch();
  }

  void updateCategory(int? categoryId) {
    state = state.copyWith(categoryId: () => categoryId);
    executeSearch();
  }

  void updateFilters({
    double? minPrice,
    double? maxPrice,
    String? sortBy,
    String? sortOrder,
  }) {
    state = state.copyWith(
      minPrice: () => minPrice,
      maxPrice: () => maxPrice,
      sortBy: sortBy,
      sortOrder: sortOrder,
    );
    executeSearch();
  }

  void clearFilters() {
    state = state.copyWith(
      categoryId: () => null,
      minPrice: () => null,
      maxPrice: () => null,
      sortBy: 'createdAt',
      sortOrder: 'desc',
    );
    executeSearch();
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(() {
  return SearchNotifier();
});
