import 'package:flutter_test/flutter_test.dart';
import 'package:fe_pet/data/models/category_model.dart';

void main() {
  test('CategoryModel.fromJson parses lowercase JSON keys', () {
    final model = CategoryModel.fromJson({
      'categoryId': 7,
      'name': 'Thức ăn hạt',
      'description': 'Thức ăn khô, hạt dinh dưỡng cho chó mèo',
      'imageUrl': 'assets/icons/pet_category.png',
    });

    expect(model.categoryId, 7);
    expect(model.name, 'Thức ăn hạt');
    expect(model.description, 'Thức ăn khô, hạt dinh dưỡng cho chó mèo');
    expect(model.imageUrl, 'assets/icons/pet_category.png');
  });
}
