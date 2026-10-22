import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/product_category.dart';
import '../../core/routes/app_routes.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/category_icon.dart';
import '../../widgets/empty_state.dart';
import 'product_listing_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late Future<List<ProductCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = context.read<ProductRepository>().getCategories();
  }

  Future<void> _reload() async {
    setState(() {
      _categoriesFuture = context.read<ProductRepository>().getCategories();
    });
    await _categoriesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      body: FutureBuilder<List<ProductCategory>>(
        future: _categoriesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _reload,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;
          if (categories.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              message: 'Product categories will be available here soon.',
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 240,
                mainAxisExtent: 150,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) =>
                  _CategoryCard(category: categories[index]),
            ),
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category});

  final ProductCategory category;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(
          AppRoutes.products,
          arguments: ProductListArguments(
            categoryId: category.id,
            categoryName: category.name,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CategoryIcon(name: category.icon, size: 36),
              const SizedBox(height: 10),
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              const Text('Browse products'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
