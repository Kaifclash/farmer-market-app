import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/app_snack.dart';
import '../../providers/auth_provider.dart';

class SellerPendingScreen extends StatefulWidget {
  const SellerPendingScreen({super.key});

  @override
  State<SellerPendingScreen> createState() => _SellerPendingScreenState();
}

class _SellerPendingScreenState extends State<SellerPendingScreen> {
  bool _signingOut = false;

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await context.read<AuthProvider>().signOut();
      if (mounted) {
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      }
    } on AuthOperationException catch (error) {
      if (mounted) AppSnack.error(context, error.message);
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().sellerStatus;
    final rejected = status == 'rejected';
    return Scaffold(
      appBar: AppBar(title: const Text('Seller application')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  rejected ? Icons.cancel_outlined : Icons.hourglass_top,
                  size: 64,
                  color: rejected
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  rejected ? 'Application not approved' : 'Application pending',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  rejected
                      ? 'Your seller application was not approved. Please contact support for details.'
                      : 'Your account is registered as a seller. Product listing will be available after admin approval.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: _signingOut ? null : _signOut,
                  child: _signingOut
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
