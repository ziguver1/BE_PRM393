import '../../domain/entities/product.dart';
import 'category_model.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.productId,
    required super.categoryId,
    required super.name,
    super.description,
    required super.price,
    required super.stock,
    super.imageUrl,
    required super.createdAt,
    super.category,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['ProductId'] as int,
      categoryId: json['CategoryId'] as int,
      name: json['Name'] as String,
      description: json['Description'] as String?,
      price: (json['Price'] as num).toDouble(),
      stock: json['Stock'] as int,
      imageUrl: json['ImageUrl'] as String?,
      createdAt: DateTime.parse(json['CreatedAt'] as String),
      category: json['Category'] != null
          ? CategoryModel.fromJson(json['Category'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ProductId': productId,
      'CategoryId': categoryId,
      'Name': name,
      'Description': description,
      'Price': price,
      'Stock': stock,
      'ImageUrl': imageUrl,
      'CreatedAt': createdAt.toIso8601String(),
      if (category != null && category is CategoryModel)
        'Category': (category as CategoryModel).toJson(),
    };
  }
}
