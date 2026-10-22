import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/app_state_provider.dart';
import 'providers/auth_provider.dart';
import 'repositories/marketplace_repository.dart';
import 'repositories/product_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppStateProvider();
  await appState.load();
  final auth = AuthProvider();
  await auth.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AppStateProvider>.value(value: appState),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ChangeNotifierProvider<ProductRepository>(
          create: (_) => ProductRepository(),
        ),
        ChangeNotifierProvider<MarketplaceRepository>(
          create: (context) => MarketplaceRepository(
            products: context.read<ProductRepository>(),
          ),
        ),
      ],
      child: const FarmerMarketApp(),
    ),
  );
}
