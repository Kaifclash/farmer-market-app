class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final String icon;
  final int sortOrder;

  factory ProductCategory.fromMap(String id, Map<String, dynamic> data) {
    return ProductCategory(
      id: id,
      name: data['name'] as String? ?? id,
      icon: data['icon'] as String? ?? '',
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'icon': icon,
        'sortOrder': sortOrder,
      };
}
