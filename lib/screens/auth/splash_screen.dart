import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_state_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(AppConstants.splashDuration, _next);
  }

  Future<void> _next() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    await auth.waitUntilReady();
    if (!mounted) return;
    final done = context.read<AppStateProvider>().onboardingDone;
    if (auth.user != null) {
      final route = switch (auth.role) {
        UserRole.customer => AppRoutes.customerHome,
        UserRole.seller when auth.sellerStatus == 'approved' =>
          AppRoutes.sellerHome,
        UserRole.seller => AppRoutes.sellerPending,
        UserRole.admin => AppRoutes.adminHome,
        null => AppRoutes.login,
      };
      Navigator.of(context).pushReplacementNamed(route);
      return;
    }
    Navigator.of(context).pushReplacementNamed(
      done ? AppRoutes.login : AppRoutes.onboarding,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return Scaffold(
      backgroundColor: AppColors.forestGreen,
      body: Center(
        child: FadeTransition(
          opacity: fade,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1).animate(fade),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(
                    color: AppColors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded,
                      size: 64, color: AppColors.forestGreen),
                ),
                const SizedBox(height: 24),
                Text(
                  AppConstants.appName,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConstants.tagline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: AppColors.lightLeaf),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
