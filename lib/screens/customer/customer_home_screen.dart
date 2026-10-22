import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/product.dart';
import '../../core/models/product_category.dart';
import '../../core/routes/app_routes.dart';
import '../../repositories/product_repository.dart';
import '../common/marketplace_screens.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import 'product_listing_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _searchController = TextEditingController();
  late Future<List<ProductCategory>> _categoriesFuture;
  late Future<ProductPage> _productsFuture;
  late final ProductRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = context.read<ProductRepository>();
    _repository.addListener(_onProductsChanged);
    _categoriesFuture = _repository.getCategories();
    _productsFuture = _repository.getProducts();
  }

  void _onProductsChanged() {
    if (!mounted) return;
    setState(() {
      _categoriesFuture = _repository.getCategories();
      _productsFuture = _repository.getProducts();
    });
  }

  @override
  void dispose() {
    _repository.removeListener(_onProductsChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _openSearch([String? search]) {
    final query = (search ?? _searchController.text).trim();
    Navigator.of(context).pushNamed(
      AppRoutes.products,
      arguments: ProductListArguments(search: query),
    );
  }

  void _openProduct(Product product) {
    Navigator.of(context)
        .pushNamed(AppRoutes.productDetails, arguments: product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmer Market'),
        actions: [
          IconButton(
            tooltip: 'Wishlist',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WishlistScreen(),
              ),
            ),
            icon: const Icon(Icons.favorite_border),
          ),
          IconButton(
            tooltip: 'Search products',
            onPressed: () => _openSearch(),
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _categoriesFuture = _repository.getCategories();
            _productsFuture = _repository.getProducts();
          });
          await Future.wait([_categoriesFuture, _productsFuture]);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            _buildWelcome(context),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _openSearch,
              decoration: InputDecoration(
                hintText: 'Search fresh produce',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  onPressed: () => _openSearch(),
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
            const SizedBox(height: 28),
            _sectionHeading(context, 'Shop by category'),
            const SizedBox(height: 12),
            _buildCategories(context),
            const SizedBox(height: 28),
            _sectionHeading(context, 'Fresh picks', action: 'View all'),
            const SizedBox(height: 12),
            _buildFeaturedProducts(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.forestGreen, Color(0xFF2E7D32)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good food starts at the farm',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Discover fresh produce from local sellers.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.white.withValues(alpha: .9)),
                ),
                const SizedBox(height: 14),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.forestGreen,
                    backgroundColor: AppColors.white,
                  ),
                  onPressed: () => _openSearch(),
                  icon: const Icon(Icons.storefront_outlined, size: 18),
                  label: const Text('Explore produce'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.agriculture_rounded,
            size: 64,
            color: Color(0xFFDDEFD8),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeading(
    BuildContext context,
    String title, {
    String? action,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action != null)
          TextButton(
            onPressed: () => _openSearch(),
            child: Text(action),
          ),
      ],
    );
  }

  Widget _buildCategories(BuildContext context) {
    return FutureBuilder<List<ProductCategory>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _inlineError(
            snapshot.error.toString(),
            () => setState(() {
              _categoriesFuture = _repository.getCategories();
            }),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 96,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final categories = snapshot.data!;
        if (categories.isEmpty) {
          return const Text('Categories will appear here once added.');
        }
        return SizedBox(
          height: 105,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) =>
                _CategoryChip(category: categories[index]),
          ),
        );
      },
    );
  }

  Widget _buildFeaturedProducts(BuildContext context) {
    return FutureBuilder<ProductPage>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _inlineError(
            snapshot.error.toString(),
            () => setState(() {
              _productsFuture = _repository.getProducts();
            }),
          );
        }
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final products = snapshot.data!.products;
        if (products.isEmpty) {
          return const EmptyState(
            icon: Icons.eco_outlined,
            title: 'No products available yet',
            message:
                'Published products from approved sellers will show up here.',
          );
        }
        final featured = products.where((product) => product.isFeatured);
        final visibleProducts =
            (featured.isNotEmpty ? featured : products).take(6).toList();
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 3 : 2;
            final cardWidth =
                (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: visibleProducts
                  .map(
                    (product) => SizedBox(
                      width: cardWidth,
                      height: 250,
                      child: ProductCard(
                        product: product,
                        onTap: () => _openProduct(product),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
    );
  }

  Widget _inlineError(String message, VoidCallback retry) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(message, style: const TextStyle(color: AppColors.error)),
        TextButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final ProductCategory category;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 86,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.products,
          arguments: ProductListArguments(
            categoryId: category.id,
            categoryName: category.name,
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: const BoxDecoration(
                color: AppColors.lightLeaf,
                shape: BoxShape.circle,
              ),
              child: CategoryIcon(name: category.icon),
            ),
            const SizedBox(height: 8),
            Text(
              category.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
