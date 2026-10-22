import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/models/product.dart';
import '../core/models/product_category.dart';

class ProductRepository extends ChangeNotifier {
  static const pageSize = 20;
  static const _categoriesKey = 'local_catalog_categories';
  static const _productsKey = 'local_catalog_products';
  static const _defaultCategories = [
    ProductCategory(
        id: 'vegetables', name: 'Vegetables', icon: 'vegetables', sortOrder: 1),
    ProductCategory(id: 'fruits', name: 'Fruits', icon: 'fruits', sortOrder: 2),
    ProductCategory(id: 'grains', name: 'Grains', icon: 'grains', sortOrder: 3),
    ProductCategory(id: 'pulses', name: 'Pulses', icon: 'pulses', sortOrder: 4),
    ProductCategory(id: 'seeds', name: 'Seeds', icon: 'seeds', sortOrder: 5),
    ProductCategory(
        id: 'fertilizers',
        name: 'Fertilizers',
        icon: 'fertilizers',
        sortOrder: 6),
    ProductCategory(id: 'other', name: 'Other', icon: 'other', sortOrder: 7),
  ];

  Future<List<ProductCategory>> getCategories() async {
    final records = await _readRecords(_categoriesKey);
    final categoryMap = {
      for (final category in _defaultCategories) category.id: category,
    };
    for (final record in records) {
      if (record['data']['active'] != false) {
        final category =
            ProductCategory.fromMap(record['id'] as String, record['data']);
        categoryMap[category.id] = category;
      } else {
        categoryMap.remove(record['id']);
      }
    }
    final categories = categoryMap.values.toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return categories;
  }

  Future<void> saveCategory(ProductCategory category) =>
      _saveRecord(_categoriesKey, category.id, {
        ...category.toMap(),
        'active': true,
      });

  Future<void> deleteCategory(String id) async {
    final records = await _readRecords(_categoriesKey);
    final index = records.indexWhere((record) => record['id'] == id);
    if (index < 0) {
      if (_defaultCategories.any((category) => category.id == id)) {
        records.add({
          'id': id,
          'data': {'name': id, 'active': false},
        });
      }
    } else {
      records[index]['data']['active'] = false;
    }
    await _writeRecords(_categoriesKey, records);
  }

  Future<void> saveProduct(Product product) async {
    await _saveRecord(_productsKey, product.id, product.toMap());
    notifyListeners();
  }

  Future<List<Product>> getSellerProducts(String sellerId) async =>
      (await getAllProducts())
          .where((product) => product.sellerId == sellerId)
          .toList();

  Future<List<Product>> getAllProducts() async => (await _readRecords(
        _productsKey,
      ))
          .map((record) => Product.fromMap(
                record['id'] as String,
                record['data'],
              ))
          .toList();

  Future<void> deleteProduct(String id) async {
    final records = await _readRecords(_productsKey);
    records.removeWhere((record) => record['id'] == id);
    await _writeRecords(_productsKey, records);
    notifyListeners();
  }

  Future<void> updateStock(String id, int stock, {bool? available}) async {
    final product = await getProduct(id);
    if (product == null) {
      throw const ProductRepositoryException('This product no longer exists.');
    }
    await saveProduct(Product(
      id: product.id,
      sellerId: product.sellerId,
      sellerName: product.sellerName,
      name: product.name,
      nameLower: product.nameLower,
      categoryId: product.categoryId,
      categoryName: product.categoryName,
      description: product.description,
      price: product.price,
      unit: product.unit,
      stock: stock,
      available: available ?? (product.available && stock > 0),
      status: product.status,
      imageUrls: product.imageUrls,
      isFeatured: product.isFeatured,
      createdAt: product.createdAt,
    ));
  }

  Future<ProductPage> getProducts({
    String? categoryId,
    String? search,
    bool availableOnly = true,
    int? after,
  }) async {
    final normalizedSearch = search?.trim().toLowerCase() ?? '';
    final products = (await getAllProducts())
        .where((product) => product.status == 'published')
        .where((product) => !availableOnly || product.available)
        .where((product) =>
            categoryId == null ||
            categoryId.isEmpty ||
            product.categoryId == categoryId)
        .where((product) =>
            normalizedSearch.isEmpty ||
            product.nameLower.startsWith(normalizedSearch))
        .toList();
    if (normalizedSearch.isEmpty) {
      products.sort((a, b) => (b.createdAt?.millisecondsSinceEpoch ?? 0)
          .compareTo(a.createdAt?.millisecondsSinceEpoch ?? 0));
    } else {
      products.sort((a, b) => a.nameLower.compareTo(b.nameLower));
    }
    final start = (after ?? 0).clamp(0, products.length).toInt();
    final end = (start + pageSize).clamp(0, products.length).toInt();
    return ProductPage(
      products: products.sublist(start, end),
      cursor: end < products.length ? end : null,
      hasMore: end < products.length,
    );
  }

  Future<Product?> getProduct(String id) async {
    final records = await _readRecords(_productsKey);
    for (final record in records) {
      if (record['id'] == id) {
        return Product.fromMap(record['id'] as String, record['data']);
      }
    }
    return null;
  }

  Future<void> _saveRecord(
    String key,
    String id,
    Map<String, dynamic> data,
  ) async {
    final records = await _readRecords(key);
    final index = records.indexWhere((record) => record['id'] == id);
    final record = {'id': id, 'data': data};
    if (index < 0) {
      records.add(record);
    } else {
      records[index] = record;
    }
    await _writeRecords(key, records);
  }

  Future<void> _writeRecords(
      String key, List<Map<String, dynamic>> records) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(key, jsonEncode(records))) {
      throw const ProductRepositoryException(
          'Could not save catalog data on this device.');
    }
  }

  Future<List<Map<String, dynamic>>> _readRecords(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(key);
    if (stored == null || stored.isEmpty) return [];
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! List ||
          decoded.any((record) =>
              record is! Map<String, dynamic> ||
              record['id'] is! String ||
              record['data'] is! Map<String, dynamic>)) {
        throw const FormatException('A saved catalog record is invalid.');
      }
      return decoded.cast<Map<String, dynamic>>();
    } on FormatException catch (error) {
      throw ProductRepositoryException(
        'Saved local catalog data is unreadable. Clear app data and try again. (${error.message})',
      );
    }
  }
}

class ProductPage {
  const ProductPage({
    required this.products,
    required this.cursor,
    required this.hasMore,
  });

  final List<Product> products;
  final int? cursor;
  final bool hasMore;
}

class ProductRepositoryException implements Exception {
  const ProductRepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}
