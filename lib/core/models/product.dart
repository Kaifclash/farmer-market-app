class Product {
  const Product({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.name,
    required this.nameLower,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    required this.price,
    required this.unit,
    required this.stock,
    required this.available,
    required this.status,
    required this.imageUrls,
    required this.isFeatured,
    this.createdAt,
  });

  final String id;
  final String sellerId;
  final String sellerName;
  final String name;
  final String nameLower;
  final String categoryId;
  final String categoryName;
  final String description;
  final double price;
  final String unit;
  final int stock;
  final bool available;
  final String status;
  final List<String> imageUrls;
  final bool isFeatured;
  final DateTime? createdAt;

  bool get canPurchase => status == 'published' && available && stock > 0;

  factory Product.fromMap(String id, Map<String, dynamic> data) {
    final rawImages = data['imageUrls'];
    final createdAt = data['createdAt'];
    return Product(
      id: id,
      sellerId: data['sellerId'] as String? ?? '',
      sellerName: data['sellerName'] as String? ?? 'Local farmer',
      name: data['name'] as String? ?? 'Unnamed product',
      nameLower: data['nameLower'] as String? ??
          (data['name'] as String? ?? '').toLowerCase(),
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? 'Other',
      description: data['description'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      unit: data['unit'] as String? ?? 'unit',
      stock: (data['stock'] as num?)?.toInt() ?? 0,
      available: data['available'] as bool? ?? false,
      status: data['status'] as String? ?? 'draft',
      imageUrls: rawImages is List
          ? rawImages.whereType<String>().toList(growable: false)
          : const [],
      isFeatured: data['isFeatured'] as bool? ?? false,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
        'sellerName': sellerName,
        'name': name,
        'nameLower': nameLower,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'description': description,
        'price': price,
        'unit': unit,
        'stock': stock,
        'available': available,
        'status': status,
        'imageUrls': imageUrls,
        'isFeatured': isFeatured,
        'createdAt': createdAt?.toIso8601String(),
      };
}
