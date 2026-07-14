import 'product_model.dart';

class PaginatedProductsModel {
  final List<ProductModel> data;
  final int total;
  final int page;
  final int totalPages;

  PaginatedProductsModel({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  /// Auto-detect both API formats:
  /// - New format (with filters param): `{ "data": [...], "total", "page", "totalPages" }`
  /// - Legacy format (without filters): `{ "items": [...], "total", "page", "limit", "totalPages" }`
  factory PaginatedProductsModel.fromJson(Map<String, dynamic> json) {
    // Prefer 'data' key (new format), fall back to 'items' key (legacy format)
    final rawList = (json['data'] as List<dynamic>?) ?? (json['items'] as List<dynamic>?) ?? [];
    return PaginatedProductsModel(
      data: rawList
          .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  // Keep legacy factory for backward compatibility
  factory PaginatedProductsModel.fromJsonLegacy(Map<String, dynamic> json) =>
      PaginatedProductsModel.fromJson(json);
}

