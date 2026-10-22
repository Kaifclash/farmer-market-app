import 'package:flutter/material.dart';

import '../../core/models/product.dart';
import '../../core/models/product_category.dart';
import '../../repositories/product_repository.dart';

class ProductEditorScreen extends StatefulWidget {
  const ProductEditorScreen({
    super.key,
    required this.repository,
    required this.sellerId,
    required this.sellerName,
    this.product,
  });

  final ProductRepository repository;
  final String sellerId;
  final String sellerName;
  final Product? product;

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _description =
      TextEditingController(text: widget.product?.description ?? '');
  late final _price =
      TextEditingController(text: widget.product?.price.toString() ?? '');
  late final _stock =
      TextEditingController(text: widget.product?.stock.toString() ?? '');
  late final _unit = TextEditingController(text: widget.product?.unit ?? 'kg');
  late final _image = TextEditingController(
      text: widget.product == null || widget.product!.imageUrls.isEmpty
          ? ''
          : widget.product!.imageUrls.first);
  late Future<List<ProductCategory>> _categories;
  String? _categoryId;
  bool _available = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.product?.categoryId;
    _available = widget.product?.available ?? true;
    _categories = widget.repository.getCategories();
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _unit.dispose();
    _image.dispose();
    super.dispose();
  }

  Future<void> _save(List<ProductCategory> categories) async {
    if (!_formKey.currentState!.validate()) return;
    final category = categories.where((item) => item.id == _categoryId);
    if (category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a product category.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final current = widget.product;
      final imageUrl = _image.text.trim();
      await widget.repository.saveProduct(Product(
        id: current?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        sellerId: widget.sellerId,
        sellerName: widget.sellerName,
        name: name,
        nameLower: name.toLowerCase(),
        categoryId: category.first.id,
        categoryName: category.first.name,
        description: _description.text.trim(),
        price: double.parse(_price.text.trim()),
        unit: _unit.text.trim(),
        stock: int.parse(_stock.text.trim()),
        available: _available,
        status: _available ? 'published' : 'draft',
        imageUrls: imageUrl.isEmpty ? [] : [imageUrl],
        isFeatured: current?.isFeatured ?? false,
        createdAt: current?.createdAt ?? DateTime.now(),
      ));
      if (mounted) Navigator.of(context).pop(true);
    } on ProductRepositoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.product == null ? 'Add product' : 'Edit product'),
        ),
        body: FutureBuilder<List<ProductCategory>>(
          future: _categories,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final categories = snapshot.data!;
            if (_categoryId == null ||
                !categories.any((item) => item.id == _categoryId)) {
              _categoryId = categories.first.id;
            }
            return SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        _input(_name, 'Product name'),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _categoryId,
                          decoration:
                              const InputDecoration(labelText: 'Category'),
                          items: categories
                              .map((item) => DropdownMenuItem(
                                    value: item.id,
                                    child: Text(item.name),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _categoryId = value),
                        ),
                        const SizedBox(height: 14),
                        _input(_description, 'Description', maxLines: 4),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _input(
                                _price,
                                'Price (₹)',
                                numeric: true,
                                allowDecimal: true,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _input(
                                _stock,
                                'Stock quantity',
                                numeric: true,
                                integer: true,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _input(_unit, 'Unit (kg, piece, bag...)'),
                        const SizedBox(height: 14),
                        _input(_image, 'Product image URL (optional)'),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Available for sale'),
                          value: _available,
                          onChanged: (value) =>
                              setState(() => _available = value),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _saving ? null : () => _save(categories),
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_saving ? 'Saving...' : 'Save listing'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

  Widget _input(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    bool numeric = false,
    bool allowDecimal = false,
    bool integer = false,
  }) =>
      TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: numeric
            ? TextInputType.numberWithOptions(decimal: allowDecimal)
            : TextInputType.text,
        decoration: InputDecoration(labelText: label),
        validator: (value) {
          final text = value?.trim() ?? '';
          if (text.isEmpty && label != 'Product image URL (optional)') {
            return 'Required';
          }
          if (integer && int.tryParse(text) == null) {
            return 'Enter a whole number';
          }
          if (allowDecimal) {
            final amount = double.tryParse(text);
            if (amount == null || amount <= 0) return 'Enter a price above 0';
          }
          if (integer && int.tryParse(text)! < 0) {
            return 'Enter zero or more';
          }
          return null;
        },
      );
}
