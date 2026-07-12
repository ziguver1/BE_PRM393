class Category {
  final int categoryId;
  final String name;
  final String? description;
  final String? imageUrl;

  const Category({
    required this.categoryId,
    required this.name,
    this.description,
    this.imageUrl,
  });
}
