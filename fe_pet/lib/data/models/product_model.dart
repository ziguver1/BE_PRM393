import '../../domain/entities/product.dart';
import 'category_model.dart';

// Product Image Model
class ProductImageModel {
  final int productImageId;
  final int productId;
  final String imageUrl;
  final bool isPrimary;

  ProductImageModel({
    required this.productImageId,
    required this.productId,
    required this.imageUrl,
    this.isPrimary = false,
  });

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      productImageId: json['ProductImageId'] as int,
      productId: json['ProductId'] as int,
      imageUrl: json['ImageUrl'] as String,
      isPrimary: json['IsPrimary'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ProductImageId': productImageId,
      'ProductId': productId,
      'ImageUrl': imageUrl,
      'IsPrimary': isPrimary,
    };
  }
}

// Product Variant Model
class ProductVariantModel extends ProductVariant {
  final int productVariantId;
  final int productId;
  final String? unit;
  final Map<String, dynamic>? attributes;

  ProductVariantModel({
    required this.productVariantId,
    required this.productId,
    required String name,
    required double price,
    required int stock,
    this.unit,
    this.attributes,
  }) : super(name: name, price: price, stock: stock);

  factory ProductVariantModel.fromJson(Map<String, dynamic> json) {
    return ProductVariantModel(
      productVariantId: json['ProductVariantId'] as int,
      productId: json['ProductId'] as int,
      name: json['Name'] as String? ?? 'Biến thể',
      price: (json['Price'] as num).toDouble(),
      stock: json['Stock'] as int,
      unit: json['Unit'] as String?,
      attributes: json['Attributes'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ProductVariantId': productVariantId,
      'ProductId': productId,
      'Name': name,
      'Price': price,
      'Stock': stock,
      if (unit != null) 'Unit': unit,
      if (attributes != null) 'Attributes': attributes,
    };
  }
}

// Filter Option Model
class FilterOptionModel {
  final int filterOptionId;
  final String value;
  final FilterGroupModel? group;

  FilterOptionModel({
    required this.filterOptionId,
    required this.value,
    this.group,
  });

  factory FilterOptionModel.fromJson(Map<String, dynamic> json) {
    return FilterOptionModel(
      filterOptionId: json['FilterOptionId'] as int,
      value: json['Value'] as String,
      group: json['Group'] != null
          ? FilterGroupModel.fromJson(json['Group'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'FilterOptionId': filterOptionId,
      'Value': value,
      if (group != null) 'Group': group!.toJson(),
    };
  }
}

// Filter Group Model
class FilterGroupModel {
  final int filterGroupId;
  final String name;
  final String? description;

  FilterGroupModel({
    required this.filterGroupId,
    required this.name,
    this.description,
  });

  factory FilterGroupModel.fromJson(Map<String, dynamic> json) {
    return FilterGroupModel(
      filterGroupId: json['FilterGroupId'] as int,
      name: json['Name'] as String,
      description: json['Description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'FilterGroupId': filterGroupId,
      'Name': name,
      if (description != null) 'Description': description,
    };
  }
}

// Product Filter Model
class ProductFilterModel {
  final int productId;
  final FilterOptionModel filterOption;

  ProductFilterModel({
    required this.productId,
    required this.filterOption,
  });

  factory ProductFilterModel.fromJson(Map<String, dynamic> json) {
    return ProductFilterModel(
      productId: json['ProductId'] as int,
      filterOption: FilterOptionModel.fromJson(
        json['FilterOption'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ProductId': productId,
      'FilterOption': filterOption.toJson(),
    };
  }
}

class ProductModel extends Product {
  final List<ProductImageModel>? images;
  final List<ProductVariantModel>? productVariants;
  final List<ProductFilterModel>? productFilters;

  ProductModel({
    required int productId,
    required int categoryId,
    required String name,
    String? description,
    required double price,
    required int stock,
    String? imageUrl,
    required DateTime createdAt,
    CategoryModel? category,
    List<ProductVariant>? variants,
    String? variantLabel,
    String unit = 'cái',
    this.images,
    this.productVariants,
    this.productFilters,
  }) : super(
    productId: productId,
    categoryId: categoryId,
    name: name,
    description: description,
    price: price,
    stock: stock,
    imageUrl: imageUrl,
    createdAt: createdAt,
    category: category,
    variants: variants,
    variantLabel: variantLabel,
    unit: unit,
  );

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
      variants: json['Variants'] != null
          ? (json['Variants'] as List)
              .map((v) => ProductVariant.fromJson(v as Map<String, dynamic>))
              .toList()
          : null,
      variantLabel: json['VariantLabel'] as String?,
      unit: json['Unit'] as String? ?? 'cái',
      images: json['Images'] != null
          ? (json['Images'] as List)
              .map((img) => ProductImageModel.fromJson(img as Map<String, dynamic>))
              .toList()
          : null,
      productVariants: json['ProductVariants'] != null
          ? (json['ProductVariants'] as List)
              .map((v) => ProductVariantModel.fromJson(v as Map<String, dynamic>))
              .toList()
          : null,
      productFilters: json['ProductFilters'] != null
          ? (json['ProductFilters'] as List)
              .map((pf) => ProductFilterModel.fromJson(pf as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  @override
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
      'Unit': unit,
      if (variantLabel != null) 'VariantLabel': variantLabel,
      if (category != null && category is CategoryModel)
        'Category': (category as CategoryModel).toJson(),
      if (variants != null)
        'Variants': variants!.map((v) => v.toJson()).toList(),
      if (images != null)
        'Images': images!.map((img) => img.toJson()).toList(),
      if (productVariants != null)
        'ProductVariants': productVariants!.map((v) => v.toJson()).toList(),
      if (productFilters != null)
        'ProductFilters': productFilters!.map((pf) => pf.toJson()).toList(),
    };
  }

  // Get primary image or fallback to ImageUrl
  String? getPrimaryImageUrl() {
    if (images != null && images!.isNotEmpty) {
      final primaryImage = images!.firstWhere(
        (img) => img.isPrimary,
        orElse: () => images!.first,
      );
      return primaryImage.imageUrl;
    }
    return imageUrl;
  }

  // Get all image URLs
  List<String> getAllImageUrls() {
    final urls = <String>[];
    if (images != null) {
      urls.addAll(images!.map((img) => img.imageUrl));
    }
    if (imageUrl != null && !urls.contains(imageUrl)) {
      urls.add(imageUrl!);
    }
    return urls;
  }

  // Get display price (from first variant or base price)
  double getDisplayPrice() {
    if (productVariants != null && productVariants!.isNotEmpty) {
      return productVariants!.first.price;
    }
    return price;
  }

  // Get filters grouped by group name
  Map<String, List<FilterOptionModel>> getFiltersByGroup() {
    final result = <String, List<FilterOptionModel>>{};
    if (productFilters == null) return result;

    for (final filter in productFilters!) {
      final groupName = filter.filterOption.group?.name ?? 'Khác';
      if (!result.containsKey(groupName)) {
        result[groupName] = [];
      }
      result[groupName]!.add(filter.filterOption);
    }
    return result;
  }
}
