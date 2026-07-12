import 'package:flutter/material.dart';

class CategoryDetailScreen extends StatelessWidget {
  final int categoryId;
  final String categoryName;
  
  const CategoryDetailScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(categoryName),
      ),
      body: Center(
        child: Text('Category Detail for ID: $categoryId ($categoryName)'),
      ),
    );
  }
}
