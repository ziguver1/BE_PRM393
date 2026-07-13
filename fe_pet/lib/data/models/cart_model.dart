class CartResponse {
  final List<CartItem> items;
  final double total;

  CartResponse({
    required this.items,
    required this.total,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    var itemsList = json['items'] as List? ?? [];
    List<CartItem> parsedItems = itemsList.map((i) => CartItem.fromJson(i)).toList();

    // Handle double conversion safely
    double parsedTotal = 0.0;
    if (json['total'] != null) {
      parsedTotal = (json['total'] as num).toDouble();
    }

    return CartResponse(
      items: parsedItems,
      total: parsedTotal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((i) => i.toJson()).toList(),
      'total': total,
    };
  }
}

class CartItem {
  final int cartItemId;
  final int userId;
  final int productId;
  final int quantity;
  final String selectedVariant;
  final CartProduct product;

  CartItem({
    required this.cartItemId,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.selectedVariant,
    required this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartItemId: json['CartItemId'] as int? ?? 0,
      userId: json['UserId'] as int? ?? 0,
      productId: json['ProductId'] as int? ?? 0,
      quantity: json['Quantity'] as int? ?? 0,
      selectedVariant: json['SelectedVariant'] as String? ?? '',
      product: CartProduct.fromJson(json['Product'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'CartItemId': cartItemId,
      'UserId': userId,
      'ProductId': productId,
      'Quantity': quantity,
      'SelectedVariant': selectedVariant,
      'Product': product.toJson(),
    };
  }
}

class CartProduct {
  final int productId;
  final int categoryId;
  final String name;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;

  CartProduct({
    required this.productId,
    required this.categoryId,
    required this.name,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
  });

  factory CartProduct.fromJson(Map<String, dynamic> json) {
    return CartProduct(
      productId: json['ProductId'] as int? ?? 0,
      categoryId: json['CategoryId'] as int? ?? 0,
      name: json['Name'] as String? ?? 'Sản phẩm',
      description: json['Description'] as String?,
      price: (json['Price'] as num? ?? 0.0).toDouble(),
      stock: json['Stock'] as int? ?? 0,
      imageUrl: json['ImageUrl'] as String?,
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
    };
  }
}
