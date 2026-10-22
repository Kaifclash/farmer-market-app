import 'package:farmer_market/core/models/product.dart';
import 'package:farmer_market/core/constants/app_constants.dart';
import 'package:farmer_market/providers/auth_provider.dart';
import 'package:farmer_market/repositories/marketplace_repository.dart';
import 'package:farmer_market/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('local account sign-in, reset and session survive provider reload',
      () async {
    final auth = AuthProvider();
    await auth.initialize();
    await auth.register(
      name: 'Customer',
      email: 'customer@example.com',
      phone: '1234567890',
      password: 'password123',
      asSeller: false,
    );
    expect(auth.role, UserRole.customer);
    await auth.signOut();
    await auth.resetPassword('customer@example.com', 'newpassword123');
    await auth.signIn('customer@example.com', 'newpassword123');

    final restored = AuthProvider();
    await restored.initialize();
    expect(restored.user?.email, 'customer@example.com');
    expect(restored.profile?['name'], 'Customer');
  });

  test('demo admin can approve a locally registered seller', () async {
    final auth = AuthProvider();
    await auth.initialize();
    await auth.register(
      name: 'Seller',
      email: 'seller@example.com',
      phone: '1234567890',
      password: 'password123',
      asSeller: true,
      shopName: 'Green Farm',
    );
    expect(auth.role, UserRole.seller);
    expect(auth.sellerStatus, 'pending');
    expect(auth.profile?['shopName'], 'Green Farm');
    final sellerUid = auth.user!.uid;

    await auth.signOut();
    await auth.signIn(
      AuthProvider.demoAdminEmail,
      AuthProvider.demoAdminPassword,
    );
    expect(auth.role, UserRole.admin);
    await auth.updateAccount(uid: sellerUid, sellerStatus: 'approved');

    await auth.signOut();
    await auth.signIn('seller@example.com', 'password123');
    expect(auth.role, UserRole.seller);
    expect(auth.sellerStatus, 'approved');
  });

  test('checkout preserves price snapshot and cancellation restores stock',
      () async {
    final products = ProductRepository();
    final marketplace = MarketplaceRepository(products: products);
    const product = Product(
      id: 'rice-1',
      sellerId: 'seller-1',
      sellerName: 'Farm',
      name: 'Rice',
      nameLower: 'rice',
      categoryId: 'grains',
      categoryName: 'Grains',
      description: '',
      price: 72.5,
      unit: 'kg',
      stock: 4,
      available: true,
      status: 'published',
      imageUrls: [],
      isFeatured: false,
    );
    await products.saveProduct(product);
    await marketplace.saveAddress('customer-1', {
      'name': 'Customer',
      'phone': '1234567890',
      'line': 'Farm Road',
      'city': 'Pune',
      'postalCode': '411001',
    });
    final address = (await marketplace.getAddresses('customer-1')).single;
    await marketplace.addToCart('customer-1', product, quantity: 2);
    final order = await marketplace.placeOrder(
      uid: 'customer-1',
      customerName: 'Customer',
      addressId: address['id'] as String,
    );
    expect(order['total'], 145);
    expect((order['items'] as List).single['priceSnapshot'], 72.5);
    expect((await products.getProduct(product.id))?.stock, 2);
    await marketplace.cancelOrder('customer-1', order['id'] as String);
    expect((await products.getProduct(product.id))?.stock, 4);
    expect((await marketplace.getOrders('customer-1')).single['status'],
        'cancelled');
  });

  test('product changes refresh listeners and cart product data', () async {
    final products = ProductRepository();
    final marketplace = MarketplaceRepository(products: products);
    var productNotifications = 0;
    var marketplaceNotifications = 0;
    products.addListener(() => productNotifications++);
    marketplace.addListener(() => marketplaceNotifications++);

    const product = Product(
      id: 'tomato-1',
      sellerId: 'seller-1',
      sellerName: 'Farm',
      name: 'Tomatoes',
      nameLower: 'tomatoes',
      categoryId: 'vegetables',
      categoryName: 'Vegetables',
      description: '',
      price: 40,
      unit: 'kg',
      stock: 5,
      available: true,
      status: 'published',
      imageUrls: [],
      isFeatured: false,
    );

    await products.saveProduct(product);
    expect(productNotifications, 1);
    expect(marketplaceNotifications, 1);

    await marketplace.addToCart('customer-1', product);
    expect(marketplaceNotifications, 2);

    await products.saveProduct(Product(
      id: product.id,
      sellerId: product.sellerId,
      sellerName: product.sellerName,
      name: product.name,
      nameLower: product.nameLower,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      description: product.description,
      price: 55,
      unit: product.unit,
      stock: product.stock,
      available: product.available,
      status: product.status,
      imageUrls: product.imageUrls,
      isFeatured: product.isFeatured,
    ));
    final cart = await marketplace.getCart('customer-1');
    expect((cart.single['product'] as Product).price, 55);
    expect(marketplaceNotifications, 3);

    await products.deleteProduct(product.id);
    expect(productNotifications, 3);
    expect(marketplaceNotifications, 4);
    expect(await marketplace.getCart('customer-1'), isEmpty);
  });
}
