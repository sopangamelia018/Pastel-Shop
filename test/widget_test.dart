import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/product_model.dart';

void main() {
  test('Product.fromJson memetakan respons DummyJSON', () {
    final p = Product.fromJson({
      'id': 1,
      'title': 'Essence Mascara Lash Princess',
      'category': 'beauty',
      'price': 9.99,
      'discountPercentage': 7.17,
      'rating': 4.94,
      'stock': 5,
      'brand': 'Essence',
    });
    expect(p.id, 1);
    expect(p.title, 'Essence Mascara Lash Princess');
    expect(p.price, 9.99);
    expect(p.stock, 5);
  });

  test('statusFromStock', () {
    expect(statusFromStock(0), 'Out of Stock');
    expect(statusFromStock(3), 'Low Stock');
    expect(statusFromStock(50), 'In Stock');
  });
}
