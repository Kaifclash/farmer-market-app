import 'package:flutter_test/flutter_test.dart';
import 'package:farmer_market/core/models/product.dart';

void main() {
  group('Product.fromMap', () {
    test('parses local product fields and keeps sale eligibility', () {
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
        'imageUrls': ['https://example.com/tomatoes.jpg', 42],
        'isFeatured': true,
        'createdAt': '2026-10-21T10:00:00.000Z',
      });

      expect(product.id, 'tomato-1');
      expect(product.price, 48);
      expect(product.imageUrls, ['https://example.com/tomatoes.jpg']);
      expect(product.canPurchase, isTrue);
      expect(product.createdAt, DateTime.utc(2026, 10, 21, 10));
    });

    test('does not allow purchasing unavailable or out-of-stock products', () {
      final outOfStock = Product.fromMap('rice-1', {
        'name': 'Rice',
        'price': 72.5,
        'unit': 'kg',
        'stock': 0,
        'available': true,
        'status': 'published',
      });
      final unpublished = Product.fromMap('rice-2', {
        'name': 'Rice',
        'price': 72.5,
        'unit': 'kg',
        'stock': 10,
        'available': true,
        'status': 'draft',
      });

      expect(outOfStock.canPurchase, isFalse);
      expect(unpublished.canPurchase, isFalse);
    });
  });
}
