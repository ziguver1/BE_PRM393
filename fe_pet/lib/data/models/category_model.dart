import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.categoryId,
    required super.name,
    super.description,
    super.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: (json['CategoryId'] ?? json['categoryId']) as int,
      name: (json['Name'] ?? json['name']) as String,
      description: (json['Description'] ?? json['description']) as String?,
      imageUrl: (json['ImageUrl'] ?? json['imageUrl']) as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CategoryId': categoryId,
      'Name': name,
      'Description': description,
      'ImageUrl': imageUrl,
    };
  }
}
