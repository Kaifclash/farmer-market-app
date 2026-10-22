import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import '../models/product.dart';
import '../../screens/admin/admin_shell.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/onboarding_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/seller_pending_screen.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/customer/customer_shell.dart';
import '../../screens/customer/product_details_screen.dart';
import '../../screens/customer/product_listing_screen.dart';
import '../../screens/common/role_guard.dart';
import '../../screens/seller/seller_shell.dart';
import 'app_routes.dart';

class AppRouter {
  AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final Widget page;
    switch (settings.name) {
      case AppRoutes.splash:
        page = const SplashScreen();
      case AppRoutes.onboarding:
        page = const OnboardingScreen();
      case AppRoutes.login:
        page = const LoginScreen();
      case AppRoutes.register:
        page = const RegisterScreen();
      case AppRoutes.forgotPassword:
        page = const ForgotPasswordScreen();
      case AppRoutes.sellerPending:
        page = const SellerPendingScreen();
      case AppRoutes.customerHome:
        page = const RoleGuard(role: UserRole.customer, child: CustomerShell());
      case AppRoutes.sellerHome:
        page = const RoleGuard(role: UserRole.seller, child: SellerShell());
      case AppRoutes.adminHome:
        page = const RoleGuard(role: UserRole.admin, child: AdminShell());
      case AppRoutes.products:
        final arguments = settings.arguments;
        page = arguments is ProductListArguments
            ? RoleGuard(
                role: UserRole.customer,
                child: ProductListingScreen(arguments: arguments),
              )
            : const LoginScreen();
      case AppRoutes.productDetails:
        final product = settings.arguments;
        page = product is Product
            ? RoleGuard(
                role: UserRole.customer,
                child: ProductDetailsScreen(product: product),
              )
            : const LoginScreen();
      default:
        page = const LoginScreen();
    }
    return MaterialPageRoute<dynamic>(builder: (_) => page, settings: settings);
  }
}
