import 'package:farmer_market/core/models/product.dart';
import 'package:farmer_market/core/models/product_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Local models', () {
    test('product map preserves catalog fields and purchase rules', () {
      final product = Product.fromMap('tomato-1', {
        'sellerId': 'seller-1',
        'sellerName': 'Green Valley Farm',
        'name': 'Tomatoes',
        'nameLower': 'tomatoes',
        'categoryId': 'vegetables',
        'categoryName': 'Vegetables',
        'description': 'Freshly harvested tomatoes.',
        'price': 48,
        'unit': 'kg',
        'stock': 12,
        'available': true,
        'status': 'published',
        'imageUrls': ['https://example.com/tomatoes.jpg'],
      });

      expect(product.id, 'tomato-1');
      expect(product.sellerId, 'seller-1');
      expect(product.price, 48);
      expect(product.canPurchase, isTrue);
      expect(Product.fromMap(product.id, product.toMap()).name, 'Tomatoes');
    });

    test('product sale eligibility checks stock and status', () {
      final unavailable = Product.fromMap('rice-1', {
        'name': 'Rice',
        'price': 72.5,
        'unit': 'kg',
        'stock': 0,
        'available': true,
        'status': 'published',
      });
      expect(unavailable.canPurchase, isFalse);
    });

    test('category map retains category identifiers and sort order', () {
      final category = ProductCategory.fromMap('grains', {
        'name': 'Grains',
        'icon': 'grains',
        'sortOrder': 3,
      });
      expect(category.id, 'grains');
      expect(category.toMap()['sortOrder'], 3);
    });
  });
}
