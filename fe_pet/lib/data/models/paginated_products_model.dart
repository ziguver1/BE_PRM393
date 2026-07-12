import 'product_model.dart';

class PaginatedProductsModel {
  final List<ProductModel> items;
  final int total;
  final int page;
  final int limit;
  final int totalPages;

  PaginatedProductsModel({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
  });

  factory PaginatedProductsModel.fromJson(Map<String, dynamic> json) {
    return PaginatedProductsModel(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      limit: json['limit'] as int? ?? 10,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }
}
