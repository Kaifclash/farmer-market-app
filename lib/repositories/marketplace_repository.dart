import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/product.dart';
import 'product_repository.dart';

class MarketplaceRepository extends ChangeNotifier {
  MarketplaceRepository({required ProductRepository products})
      : _products = products {
    _products.addListener(_onProductsChanged);
  }

  final ProductRepository _products;
  static const _key = 'local_marketplace_data';

  void _onProductsChanged() => notifyListeners();

  @override
  void dispose() {
    _products.removeListener(_onProductsChanged);
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List ||
          decoded.any((item) => item is! Map<String, dynamic>)) {
        throw const FormatException('Expected marketplace records.');
      }
      return decoded.cast<Map<String, dynamic>>();
    } on FormatException catch (error) {
      throw MarketplaceException(
        'Saved marketplace data is unreadable. Clear app data and try again. (${error.message})',
      );
    }
  }

  Future<void> _write(List<Map<String, dynamic>> records) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_key, jsonEncode(records))) {
      throw const MarketplaceException(
          'Could not save marketplace data on this device.');
    }
  }

  Future<List<Map<String, dynamic>>> getCart(String uid) async {
    final records = await _read();
    final cart = _cart(records, uid);
    final result = <Map<String, dynamic>>[];
    for (final item in cart) {
      final product = await _products.getProduct(item['productId'] as String);
      if (product != null) {
        result.add({'product': product, 'quantity': item['quantity'] as int});
      }
    }
    return result;
  }

  Future<void> addToCart(String uid, Product product,
      {int quantity = 1}) async {
    if (!product.canPurchase || quantity < 1 || quantity > product.stock) {
      throw const MarketplaceException('Choose a valid quantity in stock.');
    }
    final records = await _read();
    final cart = _cart(records, uid);
    final index = cart.indexWhere((item) => item['productId'] == product.id);
    if (index < 0) {
      cart.add({'productId': product.id, 'quantity': quantity});
    } else {
      final next = (cart[index]['quantity'] as int) + quantity;
      if (next > product.stock) {
        throw const MarketplaceException(
            'The requested quantity exceeds available stock.');
      }
      cart[index]['quantity'] = next;
    }
    await _saveCart(records, uid, cart);
  }

  Future<void> setCartQuantity(
      String uid, String productId, int quantity) async {
    final records = await _read();
    final cart = _cart(records, uid);
    final index = cart.indexWhere((item) => item['productId'] == productId);
    if (index < 0) return;
    if (quantity < 1) {
      cart.removeAt(index);
    } else {
      final product = await _products.getProduct(productId);
      if (product == null || !product.canPurchase || quantity > product.stock) {
        throw const MarketplaceException(
            'The requested quantity exceeds available stock.');
      }
      cart[index]['quantity'] = quantity;
    }
    await _saveCart(records, uid, cart);
  }

  Future<List<String>> getWishlist(String uid) async {
    final record = _record(await _read(), 'wishlist', uid);
    return List<String>.from(record?['productIds'] as List? ?? const []);
  }

  Future<void> toggleWishlist(String uid, String productId) async {
    final records = await _read();
    final record = _record(records, 'wishlist', uid);
    final ids = List<String>.from(record?['productIds'] as List? ?? const []);
    if (!ids.remove(productId)) ids.add(productId);
    _upsert(records, {'type': 'wishlist', 'ownerId': uid, 'productIds': ids});
    await _write(records);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getAddresses(String uid) async {
    final record = _record(await _read(), 'addresses', uid);
    return List<Map<String, dynamic>>.from(
      record?['items'] as List? ?? const [],
    );
  }

  Future<void> saveAddress(String uid, Map<String, dynamic> address) async {
    final records = await _read();
    final record = _record(records, 'addresses', uid);
    final items = List<Map<String, dynamic>>.from(
      record?['items'] as List? ?? const [],
    );
    items.add({
      ...address,
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    _upsert(records, {'type': 'addresses', 'ownerId': uid, 'items': items});
    await _write(records);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getOrders(String uid,
      {String? sellerId}) async {
    final records = await _read();
    return records
        .where((record) =>
            record['type'] == 'order' &&
            (sellerId == null
                ? record['ownerId'] == uid
                : (record['sellerIds'] as List).contains(sellerId)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async =>
      (await _read()).where((record) => record['type'] == 'order').toList();

  Future<Map<String, dynamic>> placeOrder({
    required String uid,
    required String customerName,
    required String addressId,
  }) async {
    final records = await _read();
    final cart = _cart(records, uid);
    if (cart.isEmpty) throw const MarketplaceException('Your cart is empty.');
    final addresses = await getAddresses(uid);
    Map<String, dynamic>? address;
    for (final item in addresses) {
      if (item['id'] == addressId) address = item;
    }
    if (address == null) {
      throw const MarketplaceException('Select a saved delivery address.');
    }

    final products = <Product>[];
    final quantities = <int>[];
    for (final item in cart) {
      final product = await _products.getProduct(item['productId'] as String);
      final quantity = item['quantity'] as int;
      if (product == null || !product.canPurchase || product.stock < quantity) {
        throw MarketplaceException(
            '${product?.name ?? 'A cart item'} is no longer available in that quantity.');
      }
      products.add(product);
      quantities.add(quantity);
    }

    final items = <Map<String, dynamic>>[];
    var totalCents = 0;
    for (var index = 0; index < products.length; index++) {
      final product = products[index];
      final quantity = quantities[index];
      final priceCents = (product.price * 100).round();
      final lineCents = priceCents * quantity;
      totalCents += lineCents;
      items.add({
        'productId': product.id,
        'sellerId': product.sellerId,
        'sellerName': product.sellerName,
        'name': product.name,
        'unit': product.unit,
        'priceSnapshot': priceCents / 100,
        'quantity': quantity,
        'lineTotal': lineCents / 100,
        'availableSnapshot': product.available,
      });
    }
    for (var index = 0; index < products.length; index++) {
      await _products.updateStock(
        products[index].id,
        products[index].stock - quantities[index],
      );
    }

    final now = DateTime.now().toIso8601String();
    final order = <String, dynamic>{
      'type': 'order',
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'ownerId': uid,
      'customerName': customerName,
      'sellerIds': products.map((product) => product.sellerId).toSet().toList(),
      'productIds': products.map((product) => product.id).toList(),
      'items': items,
      'deliveryAddress': address,
      'paymentMethod': 'cash_on_delivery',
      'status': 'placed',
      'total': totalCents / 100,
      'createdAt': now,
      'updatedAt': now,
    };
    records.add(order);
    _upsert(records, {'type': 'cart', 'ownerId': uid, 'items': []});
    await _write(records);
    notifyListeners();
    return order;
  }

  Future<void> cancelOrder(String uid, String orderId) async {
    final records = await _read();
    final order = _findOrder(records, orderId);
    if (order == null || order['ownerId'] != uid) {
      throw const MarketplaceException('Order not found for this account.');
    }
    if (order['status'] != 'placed') {
      throw const MarketplaceException(
          'Only newly placed orders can be cancelled.');
    }
    await _restoreStock(order['items'] as List);
    order['status'] = 'cancelled';
    order['updatedAt'] = DateTime.now().toIso8601String();
    await _write(records);
    notifyListeners();
  }

  Future<void> updateSellerOrderStatus(
      String sellerId, String orderId, String status) async {
    const transitions = {
      'placed': {'confirmed', 'rejected'},
      'confirmed': {'processing'},
      'processing': {'shipped'},
      'shipped': {'delivered'},
    };
    final records = await _read();
    final order = _findOrder(records, orderId);
    if (order == null || !(order['sellerIds'] as List).contains(sellerId)) {
      throw const MarketplaceException('Order not found for this seller.');
    }
    final current = order['status'] as String;
    if (!(transitions[current]?.contains(status) ?? false)) {
      throw const MarketplaceException(
          'That order status transition is not allowed.');
    }
    if (status == 'rejected') {
      await _restoreStock(order['items'] as List);
    }
    order['status'] = status;
    order['updatedAt'] = DateTime.now().toIso8601String();
    await _write(records);
    notifyListeners();
  }

  Future<void> saveReview({
    required String uid,
    required String orderId,
    required String productId,
    required int rating,
    required String comment,
  }) async {
    if (rating < 1 || rating > 5) {
      throw const MarketplaceException('Choose a rating from 1 to 5.');
    }
    final records = await _read();
    final order = _findOrder(records, orderId);
    if (order == null ||
        order['ownerId'] != uid ||
        order['status'] != 'delivered' ||
        !(order['productIds'] as List).contains(productId)) {
      throw const MarketplaceException(
          'Only products from delivered orders can be reviewed.');
    }
    if (records.any((record) =>
        record['type'] == 'review' &&
        record['orderId'] == orderId &&
        record['productId'] == productId)) {
      throw const MarketplaceException(
          'You have already reviewed this purchase.');
    }
    records.add({
      'type': 'review',
      'ownerId': uid,
      'orderId': orderId,
      'productId': productId,
      'rating': rating,
      'comment': comment.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    await _write(records);
    notifyListeners();
  }

  Future<void> _restoreStock(List<dynamic> items) async {
    for (final item in items) {
      final product = await _products.getProduct(item['productId'] as String);
      if (product == null) continue;
      await _products.updateStock(
        product.id,
        product.stock + (item['quantity'] as int),
        available: item['availableSnapshot'] as bool? ?? product.available,
      );
    }
  }

  List<Map<String, dynamic>> _cart(
          List<Map<String, dynamic>> records, String uid) =>
      List<Map<String, dynamic>>.from(
          _record(records, 'cart', uid)?['items'] as List? ?? const []);

  Future<void> _saveCart(List<Map<String, dynamic>> records, String uid,
      List<Map<String, dynamic>> cart) async {
    _upsert(records, {'type': 'cart', 'ownerId': uid, 'items': cart});
    await _write(records);
    notifyListeners();
  }

  Map<String, dynamic>? _record(
      List<Map<String, dynamic>> records, String type, String uid) {
    for (final record in records) {
      if (record['type'] == type && record['ownerId'] == uid) return record;
    }
    return null;
  }

  Map<String, dynamic>? _findOrder(
      List<Map<String, dynamic>> records, String orderId) {
    for (final record in records) {
      if (record['type'] == 'order' && record['id'] == orderId) return record;
    }
    return null;
  }

  void _upsert(List<Map<String, dynamic>> records, Map<String, dynamic> next) {
    final index = records.indexWhere((record) =>
        record['type'] == next['type'] && record['ownerId'] == next['ownerId']);
    if (index < 0) {
      records.add(next);
    } else {
      records[index] = next;
    }
  }
}

class MarketplaceException implements Exception {
  const MarketplaceException(this.message);
  final String message;
  @override
  String toString() => message;
}
