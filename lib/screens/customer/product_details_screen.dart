import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/product.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/marketplace_repository.dart';
import '../../core/utils/app_snack.dart';
import '../../widgets/empty_state.dart';

class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (product.status != 'published') {
      return Scaffold(
        appBar: AppBar(title: const Text('Product')),
        body: const EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Product unavailable',
          message: 'This listing is no longer available.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product details'),
        actions: [
          IconButton(
            tooltip: 'Add to wishlist',
            onPressed: () async {
              final marketplace = context.read<MarketplaceRepository>();
              final uid = context.read<AuthProvider>().user!.uid;
              try {
                await marketplace.toggleWishlist(uid, product.id);
                if (context.mounted) {
                  AppSnack.success(context, 'Wishlist updated.');
                }
              } on MarketplaceException catch (error) {
                if (context.mounted) AppSnack.error(context, error.message);
              }
            },
            icon: const Icon(Icons.favorite_border),
          ),
        ],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 300,
            child: product.imageUrls.isEmpty
                ? const _ImageFallback()
                : PageView.builder(
                    itemCount: product.imageUrls.length,
                    itemBuilder: (context, index) => Image.network(
                      product.imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const _ImageFallback(),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.categoryName,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${product.price.toStringAsFixed(2)} / ${product.unit}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.lightLeaf,
                      child: Icon(Icons.storefront_outlined,
                          color: AppColors.forestGreen),
                    ),
                    title: Text(product.sellerName),
                    subtitle: const Text('Local seller'),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      product.canPurchase
                          ? '${product.stock} ${product.unit} available'
                          : 'Currently unavailable',
                      style: TextStyle(
                        color: product.canPurchase
                            ? AppColors.success
                            : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('About this product',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  product.description.isEmpty
                      ? 'The seller has not added a description yet.'
                      : product.description,
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: product.canPurchase
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () async {
                    try {
                      await context.read<MarketplaceRepository>().addToCart(
                            context.read<AuthProvider>().user!.uid,
                            product,
                          );
                      if (context.mounted) {
                        AppSnack.success(context, 'Added to your cart.');
                      }
                    } on MarketplaceException catch (error) {
                      if (context.mounted) {
                        AppSnack.error(context, error.message);
                      }
                    }
                  },
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('Add to cart'),
                ),
              ),
            )
          : null,
    );
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.lightLeaf,
      child: Center(
        child: Icon(Icons.eco_outlined, size: 72, color: AppColors.forestGreen),
      ),
    );
  }
}
