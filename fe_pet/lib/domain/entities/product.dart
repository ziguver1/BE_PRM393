import 'category.dart';

class ProductVariant {
  final String name;
  final double price;
  final int stock;

  const ProductVariant({
    required this.name,
    required this.price,
    required this.stock,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'price': price,
      'stock': stock,
    };
  }
}

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
  final List<ProductVariant>? variants;
  final String? variantLabel;
  final String unit;
  final bool isWishlisted;

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
    this.variants,
    this.variantLabel,
    this.unit = 'cái',
    this.isWishlisted = false,
  });

  bool get isOutOfStock => stock <= 0;
}
