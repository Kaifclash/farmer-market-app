import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.role,
    required this.child,
  });

  final UserRole role;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final allowed = auth.user != null &&
        auth.role == role &&
        auth.accountStatus == 'active' &&
        (role != UserRole.seller || auth.sellerStatus == 'approved');

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (allowed) return child;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 48),
              const SizedBox(height: 16),
              Text(
                auth.user == null
                    ? 'Sign in to access this page.'
                    : 'Your account does not have permission to access this page.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
                child: const Text('Go to sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
