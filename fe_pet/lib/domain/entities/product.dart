import 'category.dart';

class Product {
  final int productId;
  final int categoryId;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;
  final DateTime createdAt;
  final Category? category;

  const Product({
    required this.productId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.createdAt,
    this.category,
  });

  bool get isOutOfStock => stock <= 0;
}
