import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/product.dart';
import '../../core/routes/app_routes.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';

class ProductListArguments {
  const ProductListArguments({
    this.categoryId,
    this.categoryName,
    this.search = '',
  });

  final String? categoryId;
  final String? categoryName;
  final String search;
}

class ProductListingScreen extends StatefulWidget {
  const ProductListingScreen({super.key, required this.arguments});

  final ProductListArguments arguments;

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final List<Product> _products = [];

  late final ProductRepository _repository;
  int? _cursor;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _availableOnly = true;
  double? _minPrice;
  double? _maxPrice;
  String? _error;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _repository = context.read<ProductRepository>();
    _repository.addListener(_onProductsChanged);
    _search = widget.arguments.search.trim();
    _searchController.text = _search;
    _scrollController.addListener(_handleScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _repository.removeListener(_onProductsChanged);
    _searchController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  void _onProductsChanged() {
    if (mounted) _loadInitial();
  }

  void _handleScroll() {
    if (_scrollController.position.extentAfter < 360) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _loadingMore = false;
      _error = null;
      _products.clear();
      _cursor = null;
      _hasMore = true;
    });
    try {
      final page = await _repository.getProducts(
        categoryId: widget.arguments.categoryId,
        search: _search,
        availableOnly: _availableOnly,
      );
      if (!mounted) return;
      setState(() {
        _products.addAll(page.products);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
      });
    } on ProductRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore || _error != null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repository.getProducts(
        categoryId: widget.arguments.categoryId,
        search: _search,
        availableOnly: _availableOnly,
        after: _cursor,
      );
      if (!mounted) return;
      setState(() {
        _products.addAll(page.products);
        _cursor = page.cursor;
        _hasMore = page.hasMore;
      });
    } on ProductRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _submitSearch(String value) {
    final normalized = value.trim();
    if (normalized == _search) return;
    setState(() => _search = normalized);
    _loadInitial();
  }

  Future<void> _showFilters() async {
    _minPriceController.text = _minPrice?.toStringAsFixed(2) ?? '';
    _maxPriceController.text = _maxPrice?.toStringAsFixed(2) ?? '';
    final formKey = GlobalKey<FormState>();
    final filters = await showModalBottomSheet<
        ({double? min, double? max, bool available})>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _minPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Minimum price',
                          prefixText: '₹ ',
                        ),
                        validator: _validatePrice,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _maxPriceController,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Maximum price',
                          prefixText: '₹ ',
                        ),
                        validator: _validatePrice,
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available products only'),
                  value: _availableOnly,
                  onChanged: (value) =>
                      setModalState(() => _availableOnly = value),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final minimum =
                        double.tryParse(_minPriceController.text.trim());
                    final maximum =
                        double.tryParse(_maxPriceController.text.trim());
                    if (minimum != null &&
                        maximum != null &&
                        minimum > maximum) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                              'Minimum price must not exceed maximum price.'),
                        ),
                      );
                      return;
                    }
                    Navigator.of(context).pop((
                      min: minimum,
                      max: maximum,
                      available: _availableOnly,
                    ));
                  },
                  child: const Text('Apply filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (filters != null) {
      setState(() {
        _minPrice = filters.min;
        _maxPrice = filters.max;
        _availableOnly = filters.available;
      });
      _loadInitial();
    }
  }

  String? _validatePrice(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null;
    final amount = double.tryParse(input);
    if (amount == null || amount < 0) return 'Enter a valid price';
    return null;
  }

  List<Product> get _filteredProducts => _products.where((product) {
        if (_minPrice != null && product.price < _minPrice!) return false;
        if (_maxPrice != null && product.price > _maxPrice!) return false;
        return true;
      }).toList();

  @override
  Widget build(BuildContext context) {
    final title = widget.arguments.categoryName ?? 'Products';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _submitSearch,
                    decoration: InputDecoration(
                      hintText: 'Search product names',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Search',
                        onPressed: () => _submitSearch(_searchController.text),
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Filter products',
                  onPressed: _showFilters,
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadInitial,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final products = _filteredProducts;
    if (products.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: EmptyState(
              icon: Icons.search_off,
              title: 'No matching products',
              message: _products.isEmpty
                  ? 'Try another search or category. New listings appear here after sellers publish them.'
                  : 'Try adjusting your search or price filters.',
            ),
          ),
          if (_hasMore && !_loadingMore)
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: TextButton.icon(
                onPressed: _loadMore,
                icon: const Icon(Icons.expand_more),
                label: const Text('Load more products'),
              ),
            ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _loadInitial,
      child: Column(
        children: [
          if (_error != null)
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() => _error = null);
                    _loadMore();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 4
                    : constraints.maxWidth >= 600
                        ? 3
                        : 2;
                return GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: constraints.maxWidth >= 600 ? 0.82 : 0.70,
                  ),
                  itemCount: products.length + (_loadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == products.length) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.productDetails,
                        arguments: product,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
