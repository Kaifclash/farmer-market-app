import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/product.dart';
import '../../core/models/product_category.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/marketplace_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/empty_state.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final products = context.read<ProductRepository>();
    final marketplace = context.read<MarketplaceRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('Admin overview')),
      body: FutureBuilder<List<dynamic>>(
        future: _load(auth, products, marketplace),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _ErrorView('${snapshot.error}');
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          final accounts = items[0] as List<Map<String, dynamic>>;
          final listings = items[1] as List<Product>;
          final orders = items[2] as List<Map<String, dynamic>>;
          final customers =
              accounts.where((account) => account['role'] == 'customer').length;
          final sellers =
              accounts.where((account) => account['role'] == 'seller').length;
          final pendingSellers = accounts
              .where((account) =>
                  account['role'] == 'seller' &&
                  account['sellerStatus'] == 'pending')
              .length;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text('Platform summary',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Summary(label: 'Customers', value: '$customers'),
                  _Summary(label: 'Sellers', value: '$sellers'),
                  _Summary(label: 'Pending requests', value: '$pendingSellers'),
                  _Summary(label: 'Products', value: '${listings.length}'),
                  _Summary(label: 'Orders', value: '${orders.length}'),
                ],
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Future<List<dynamic>> _load(
    AuthProvider auth,
    ProductRepository products,
    MarketplaceRepository marketplace,
  ) async {
    final accounts = await auth.getAccounts();
    final listings = await products.getAllProducts();
    final orders = await marketplace.getAllOrders();
    return [accounts, listings, orders];
  }
}

class AdminSellerScreen extends StatefulWidget {
  const AdminSellerScreen({super.key});
  @override
  State<AdminSellerScreen> createState() => _AdminSellerScreenState();
}

class _AdminSellerScreenState extends State<AdminSellerScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Seller applications')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: auth.getAccounts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _ErrorView('${snapshot.error}');
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final sellers = snapshot.data!
              .where((account) => account['role'] == 'seller')
              .toList();
          if (sellers.isEmpty) {
            return const EmptyState(
              icon: Icons.storefront_outlined,
              title: 'No seller applications',
              message: 'Seller applications will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sellers.length,
            itemBuilder: (context, index) {
              final seller = sellers[index];
              final uid = seller['uid'] as String;
              final status = seller['sellerStatus'] as String? ?? 'pending';
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seller['shopName'] as String? ??
                            seller['name'] as String,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text('${seller['name']} · ${seller['email']}'),
                      if ((seller['phone'] as String? ?? '').isNotEmpty)
                        Text(seller['phone'] as String),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Chip(label: Text(status.toUpperCase())),
                          const Spacer(),
                          if (status != 'approved')
                            TextButton(
                              onPressed: () =>
                                  _setSellerStatus(auth, uid, 'rejected'),
                              child: const Text('Reject'),
                            ),
                          if (status != 'approved') const SizedBox(width: 8),
                          if (status != 'approved')
                            FilledButton(
                              onPressed: () =>
                                  _setSellerStatus(auth, uid, 'approved'),
                              child: const Text('Approve'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _setSellerStatus(
      AuthProvider auth, String uid, String status) async {
    try {
      await auth.updateAccount(uid: uid, sellerStatus: status);
      if (mounted) setState(() {});
    } on AuthOperationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }
}

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: auth.getAccounts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _ErrorView('${snapshot.error}');
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snapshot.data!;
          if (accounts.isEmpty) {
            return const EmptyState(
              icon: Icons.people_outline,
              title: 'No accounts',
              message: 'Registered accounts will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: accounts.length,
            itemBuilder: (context, index) {
              final account = accounts[index];
              final uid = account['uid'] as String;
              final suspended = account['status'] == 'suspended';
              return Card(
                child: SwitchListTile(
                  title: Text(account['name'] as String),
                  subtitle: Text(
                      '${account['email']} · ${account['role']} · ${suspended ? 'suspended' : 'active'}'),
                  value: !suspended,
                  onChanged: (active) async {
                    try {
                      await auth.updateAccount(
                        uid: uid,
                        accountStatus: active ? 'active' : 'suspended',
                      );
                      if (context.mounted) setState(() {});
                    } on AuthOperationException catch (error) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message)));
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});
  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  late Future<List<Product>> _products;
  late ProductRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = context.read<ProductRepository>();
    _reload();
  }

  void _reload() => _products = _repository.getAllProducts();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Product listings'),
          actions: [
            IconButton(
              tooltip: 'Manage categories',
              onPressed: _manageCategories,
              icon: const Icon(Icons.category_outlined),
            ),
          ],
        ),
        body: FutureBuilder<List<Product>>(
          future: _products,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _ErrorView('${snapshot.error}');
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = snapshot.data!;
            if (products.isEmpty) {
              return const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No listings',
                message: 'Local catalog listings appear here.',
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                        '${product.sellerName} · ${product.status} · ₹${product.price}'),
                    trailing: IconButton(
                      tooltip: 'Remove listing',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await _repository.deleteProduct(product.id);
                        if (mounted) setState(_reload);
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      );

  Future<void> _manageCategories() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _CategoryManagementScreen(repository: _repository),
      ),
    );
  }
}

class _CategoryManagementScreen extends StatefulWidget {
  const _CategoryManagementScreen({required this.repository});
  final ProductRepository repository;
  @override
  State<_CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<_CategoryManagementScreen> {
  late Future<List<ProductCategory>> _categories;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _categories = widget.repository.getCategories();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Categories')),
        floatingActionButton: FloatingActionButton(
          onPressed: _addCategory,
          child: const Icon(Icons.add),
        ),
        body: FutureBuilder<List<ProductCategory>>(
          future: _categories,
          builder: (context, snapshot) {
            if (snapshot.hasError) return _ErrorView('${snapshot.error}');
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return ListView(
              children: snapshot.data!
                  .map((category) => ListTile(
                        leading: const Icon(Icons.category_outlined),
                        title: Text(category.name),
                        subtitle: Text(category.id),
                      ))
                  .toList(),
            );
          },
        ),
      );

  Future<void> _addCategory() async {
    final name = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add category'),
        content: TextField(
          controller: name,
          decoration: const InputDecoration(labelText: 'Category name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, name.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    name.dispose();
    if (value == null || value.isEmpty) return;
    final id = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    await widget.repository.saveCategory(ProductCategory(
      id: id,
      name: value,
      icon: id,
      sortOrder: DateTime.now().millisecondsSinceEpoch,
    ));
    if (mounted) setState(_reload);
  }
}

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    return Scaffold(
      appBar: AppBar(title: const Text('All orders')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: repository.getAllOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _ErrorView('${snapshot.error}');
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders',
              message: 'Local marketplace orders appear here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: orders
                .map((order) => Card(
                      child: ListTile(
                        title: Text('Order #${order['id']}'),
                        subtitle: Text(
                            '${order['status']} · ₹${(order['total'] as num).toStringAsFixed(2)} · ${order['ownerId']}'),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 170,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                Text(label),
              ],
            ),
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}
