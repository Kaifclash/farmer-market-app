import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/product.dart';
import '../../core/utils/app_snack.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/marketplace_repository.dart';
import '../../repositories/product_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/product_card.dart';
import '../../core/routes/app_routes.dart';
import 'product_editor_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  late Future<List<Map<String, dynamic>>> _cartFuture;
  late MarketplaceRepository _marketplace;
  String get _uid => context.read<AuthProvider>().user!.uid;

  @override
  void initState() {
    super.initState();
    _marketplace = context.read<MarketplaceRepository>();
    _marketplace.addListener(_onMarketplaceChanged);
    _reload();
  }

  void _reload() => _cartFuture = _marketplace.getCart(_uid);

  void _onMarketplaceChanged() {
    if (mounted) setState(_reload);
  }

  @override
  void dispose() {
    _marketplace.removeListener(_onMarketplaceChanged);
    super.dispose();
  }

  Future<void> _changeQuantity(Product product, int quantity) async {
    try {
      await _marketplace.setCartQuantity(_uid, product.id, quantity);
      setState(_reload);
    } on MarketplaceException catch (error) {
      if (mounted) AppSnack.error(context, error.message);
    }
  }

  Future<void> _checkout() async {
    final addresses = await _marketplace.getAddresses(_uid);
    if (!mounted) return;
    final address = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddressPicker(
        addresses: addresses,
        onAddAddress: _addAddress,
      ),
    );
    if (!mounted || address == null) return;
    try {
      final order = await _marketplace.placeOrder(
        uid: _uid,
        customerName:
            context.read<AuthProvider>().profile?['name'] as String? ?? '',
        addressId: address['id'] as String,
      );
      if (!mounted) return;
      setState(_reload);
      AppSnack.success(
          context, 'Order ${order['id']} placed. Payment: Cash on delivery.');
    } on MarketplaceException catch (error) {
      if (mounted) AppSnack.error(context, error.message);
    }
  }

  Future<Map<String, dynamic>?> _addAddress() async {
    final fields = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _AddressFormDialog(),
    );
    if (fields == null) return null;
    await _marketplace.saveAddress(_uid, fields);
    final addresses = await _marketplace.getAddresses(_uid);
    return addresses.isEmpty ? null : addresses.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your cart'),
        actions: [
          IconButton(
            tooltip: 'Delivery addresses',
            onPressed: _manageAddresses,
            icon: const Icon(Icons.location_on_outlined),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cartFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(message: '${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Your cart is empty',
              message: 'Browse the market and add fresh products to your cart.',
            );
          }
          final total = items.fold<double>(
            0,
            (sum, item) =>
                sum +
                (item['product'] as Product).price * (item['quantity'] as int),
          );
          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = items[index]['product'] as Product;
                    final quantity = items[index]['quantity'] as int;
                    return Card(
                      child: ListTile(
                        title: Text(product.name),
                        subtitle: Text(
                            '₹${product.price.toStringAsFixed(2)} / ${product.unit}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _changeQuantity(product, quantity - 1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text('$quantity'),
                            IconButton(
                              onPressed: () =>
                                  _changeQuantity(product, quantity + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Total  ₹${total.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FilledButton(
                        onPressed: _checkout,
                        child: const Text('Checkout · COD'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _manageAddresses() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddressListScreen(
          repository: _marketplace,
          uid: _uid,
        ),
      ),
    );
  }
}

class _AddressPicker extends StatelessWidget {
  const _AddressPicker({required this.addresses, required this.onAddAddress});
  final List<Map<String, dynamic>> addresses;
  final Future<Map<String, dynamic>?> Function() onAddAddress;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Delivery address'),
        content: SizedBox(
          width: 440,
          child: addresses.isEmpty
              ? const Text('Add a delivery address to continue.')
              : ListView(
                  shrinkWrap: true,
                  children: addresses
                      .map((address) => ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(address['name'] as String),
                            subtitle: Text(
                                '${address['line']}, ${address['city']} · ${address['phone']}'),
                            onTap: () => Navigator.pop(context, address),
                          ))
                      .toList(),
                ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final address = await onAddAddress();
              if (context.mounted && address != null) {
                Navigator.pop(context, address);
              }
            },
            child: const Text('Add address'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
}

class AddressListScreen extends StatefulWidget {
  const AddressListScreen(
      {super.key, required this.repository, required this.uid});
  final MarketplaceRepository repository;
  final String uid;

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  late Future<List<Map<String, dynamic>>> _addresses;

  @override
  void initState() {
    super.initState();
    _addresses = widget.repository.getAddresses(widget.uid);
  }

  Future<void> _add() async {
    final address = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => const _AddressFormDialog(),
    );
    if (address == null) return;
    await widget.repository.saveAddress(widget.uid, address);
    setState(() => _addresses = widget.repository.getAddresses(widget.uid));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Saved addresses')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _add,
          icon: const Icon(Icons.add),
          label: const Text('Add address'),
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _addresses,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final addresses = snapshot.data!;
            if (addresses.isEmpty) {
              return const EmptyState(
                icon: Icons.location_on_outlined,
                title: 'No saved addresses',
                message: 'Add a delivery address for your next order.',
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: addresses
                  .map((item) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.home_outlined),
                          title: Text(item['name'] as String),
                          subtitle: Text(
                              '${item['line']}, ${item['city']} ${item['postalCode']} · ${item['phone']}'),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      );
}

class _AddressFormDialog extends StatefulWidget {
  const _AddressFormDialog();
  @override
  State<_AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<_AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line = TextEditingController();
  final _city = TextEditingController();
  final _postal = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _line.dispose();
    _city.dispose();
    _postal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Add delivery address'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(_name, 'Recipient name'),
                _field(_phone, 'Phone number'),
                _field(_line, 'Street address'),
                _field(_city, 'City'),
                _field(_postal, 'Postal code'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(context, {
                'name': _name.text.trim(),
                'phone': _phone.text.trim(),
                'line': _line.text.trim(),
                'city': _city.text.trim(),
                'postalCode': _postal.text.trim(),
              });
            },
            child: const Text('Save address'),
          ),
        ],
      );

  Widget _field(TextEditingController controller, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
        ),
      );
}

class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});
  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  Future<List<Product>> _load() async {
    final marketplace = context.read<MarketplaceRepository>();
    final products = context.read<ProductRepository>();
    final ids =
        await marketplace.getWishlist(context.read<AuthProvider>().user!.uid);
    final result = <Product>[];
    for (final id in ids) {
      final product = await products.getProduct(id);
      if (product != null) result.add(product);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Wishlist')),
        body: FutureBuilder<List<Product>>(
          future: _load(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorState(message: '${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = snapshot.data!;
            if (products.isEmpty) {
              return const EmptyState(
                icon: Icons.favorite_border,
                title: 'Your wishlist is empty',
                message: 'Save products you would like to find again.',
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: 290,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) => ProductCard(
                product: products[index],
                onTap: () => Navigator.of(context).pushNamed(
                  AppRoutes.productDetails,
                  arguments: products[index],
                ),
              ),
            );
          },
        ),
      );
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    final uid = context.read<AuthProvider>().user!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: repository.getOrders(uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(message: '${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Your placed orders and their status will appear here.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[orders.length - 1 - index];
              final items = order['items'] as List;
              return Card(
                child: ExpansionTile(
                  title: Text('Order #${order['id']}'),
                  subtitle: Text(
                      '${order['status']} · ₹${(order['total'] as num).toStringAsFixed(2)} · Cash on delivery'),
                  children: [
                    for (final item in items)
                      ListTile(
                        dense: true,
                        title: Text(item['name'] as String),
                        subtitle: Text(
                            '${item['quantity']} × ₹${(item['priceSnapshot'] as num).toStringAsFixed(2)} / ${item['unit']}'),
                        trailing: Text(
                            '₹${(item['lineTotal'] as num).toStringAsFixed(2)}'),
                      ),
                    if (order['status'] == 'placed')
                      TextButton(
                        onPressed: () async {
                          try {
                            await repository.cancelOrder(
                                uid, order['id'] as String);
                            if (context.mounted) setState(() {});
                          } on MarketplaceException catch (error) {
                            if (context.mounted) {
                              AppSnack.error(context, error.message);
                            }
                          }
                        },
                        child: const Text('Cancel order'),
                      ),
                    if (order['status'] == 'delivered')
                      for (final item in items)
                        TextButton.icon(
                          onPressed: () => _review(
                            repository: repository,
                            uid: uid,
                            orderId: order['id'] as String,
                            productId: item['productId'] as String,
                            productName: item['name'] as String,
                          ),
                          icon: const Icon(Icons.rate_review_outlined),
                          label: Text('Review ${item['name']}'),
                        ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _review({
    required MarketplaceRepository repository,
    required String uid,
    required String orderId,
    required String productId,
    required String productName,
  }) async {
    var rating = 5;
    final comment = TextEditingController();
    final review = await showDialog<({int rating, String comment})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Review $productName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: rating,
                decoration: const InputDecoration(labelText: 'Rating'),
                items: List.generate(
                  5,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1} star${index == 0 ? '' : 's'}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) setDialogState(() => rating = value);
                },
              ),
              TextField(
                controller: comment,
                maxLength: 500,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Comment'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                (rating: rating, comment: comment.text.trim()),
              ),
              child: const Text('Submit review'),
            ),
          ],
        ),
      ),
    );
    comment.dispose();
    if (review == null) return;
    try {
      await repository.saveReview(
        uid: uid,
        orderId: orderId,
        productId: productId,
        rating: review.rating,
        comment: review.comment,
      );
      if (mounted) AppSnack.success(context, 'Thanks for your review.');
    } on MarketplaceException catch (error) {
      if (mounted) AppSnack.error(context, error.message);
    }
  }
}

class SellerProductsScreen extends StatefulWidget {
  const SellerProductsScreen({super.key});
  @override
  State<SellerProductsScreen> createState() => _SellerProductsScreenState();
}

class _SellerProductsScreenState extends State<SellerProductsScreen> {
  late Future<List<Product>> _products;
  late ProductRepository _repository;
  String get _uid => context.read<AuthProvider>().user!.uid;
  Map<String, dynamic> get _profile =>
      context.read<AuthProvider>().profile ?? const {};

  @override
  void initState() {
    super.initState();
    _repository = context.read<ProductRepository>();
    _repository.addListener(_onProductsChanged);
    _reload();
  }

  void _reload() => _products = _repository.getSellerProducts(_uid);

  void _onProductsChanged() {
    if (mounted) setState(_reload);
  }

  @override
  void dispose() {
    _repository.removeListener(_onProductsChanged);
    super.dispose();
  }

  Future<void> _create() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProductEditorScreen(
          repository: _repository,
          sellerId: _uid,
          sellerName: _profile['name'] as String? ?? 'Local seller',
        ),
      ),
    );
    if (saved == true) setState(_reload);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My products')),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _create,
          icon: const Icon(Icons.add),
          label: const Text('Add product'),
        ),
        body: FutureBuilder<List<Product>>(
          future: _products,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _ErrorState(message: '${snapshot.error}');
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final products = snapshot.data!;
            if (products.isEmpty) {
              return const EmptyState(
                icon: Icons.inventory_2_outlined,
                title: 'No listings yet',
                message: 'Add your first product to start your local catalog.',
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
                        '${product.categoryName} · ${product.stock} ${product.unit} · ${product.status}'),
                    trailing: PopupMenuButton<String>(
                      onSelected: (action) async {
                        if (action == 'edit') {
                          final saved = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => ProductEditorScreen(
                                repository: _repository,
                                sellerId: _uid,
                                sellerName: _profile['name'] as String? ??
                                    'Local seller',
                                product: product,
                              ),
                            ),
                          );
                          if (saved == true) setState(_reload);
                        } else if (action == 'delete') {
                          await _repository.deleteProduct(product.id);
                          setState(_reload);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
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

class SellerDashboardScreen extends StatelessWidget {
  const SellerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.read<ProductRepository>();
    final orders = context.read<MarketplaceRepository>();
    final sellerId = context.read<AuthProvider>().user!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Seller dashboard')),
      body: FutureBuilder<List<Object>>(
        future: Future.wait<Object>([
          products.getSellerProducts(sellerId),
          orders.getOrders(sellerId, sellerId: sellerId),
        ]),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(message: '${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final listings = snapshot.data![0] as List<Product>;
          final sellerOrders = snapshot.data![1] as List<Map<String, dynamic>>;
          final earnings = sellerOrders
              .where((order) => order['status'] == 'delivered')
              .fold<double>(0, (sum, order) {
            final lines = (order['items'] as List)
                .where((item) => item['sellerId'] == sellerId);
            return sum +
                lines.fold<double>(
                  0,
                  (lineSum, item) =>
                      lineSum + (item['lineTotal'] as num).toDouble(),
                );
          });
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Your farm at a glance',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _MetricCard(label: 'Listings', value: '${listings.length}'),
                  _MetricCard(label: 'Orders', value: '${sellerOrders.length}'),
                  _MetricCard(
                      label: 'Delivered sales',
                      value: '₹${earnings.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 24),
              const Card(
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Local demo data'),
                  subtitle: Text(
                      'Listings and orders are saved on this device and are not shared with customers on other devices.'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 175,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(label),
              ],
            ),
          ),
        ),
      );
}

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MarketplaceRepository>();
    final uid = context.read<AuthProvider>().user!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming orders')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: repository.getOrders(uid, sellerId: uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(message: '${snapshot.error}');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = snapshot.data!;
          if (orders.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No incoming orders',
              message: 'Orders containing your products will appear here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: orders.map((order) {
              final items = (order['items'] as List)
                  .where((item) => item['sellerId'] == uid)
                  .toList();
              return Card(
                child: ExpansionTile(
                  title: Text('Order #${order['id']}'),
                  subtitle:
                      Text('${order['status']} · ${items.length} line items'),
                  children: [
                    for (final item in items)
                      ListTile(
                        title: Text(item['name'] as String),
                        subtitle: Text(
                            '${item['quantity']} × ₹${(item['priceSnapshot'] as num).toStringAsFixed(2)}'),
                      ),
                    DropdownButton<String>(
                      value: _sellerStatus(order['status'] as String),
                      items: const [
                        DropdownMenuItem(
                            value: 'rejected', child: Text('Reject order')),
                        DropdownMenuItem(
                            value: 'confirmed', child: Text('Confirmed')),
                        DropdownMenuItem(
                            value: 'processing', child: Text('Processing')),
                        DropdownMenuItem(
                            value: 'shipped', child: Text('Shipped')),
                        DropdownMenuItem(
                            value: 'delivered', child: Text('Delivered')),
                      ],
                      onChanged: const {
                        'cancelled',
                        'rejected',
                        'delivered',
                      }.contains(order['status'])
                          ? null
                          : (status) async {
                              if (status == null) return;
                              try {
                                await repository.updateSellerOrderStatus(
                                    uid, order['id'] as String, status);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Order status updated.')),
                                  );
                                }
                              } on MarketplaceException catch (error) {
                                if (context.mounted) {
                                  AppSnack.error(context, error.message);
                                }
                              }
                            },
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _sellerStatus(String status) => switch (status) {
        'rejected' ||
        'confirmed' ||
        'processing' ||
        'shipped' ||
        'delivered' =>
          status,
        _ => 'confirmed',
      };
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}
