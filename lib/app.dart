import 'package:flutter/material.dart';

import 'core/routes/app_router.dart';
import 'core/routes/app_routes.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

class FarmerMarketApp extends StatelessWidget {
  const FarmerMarketApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
