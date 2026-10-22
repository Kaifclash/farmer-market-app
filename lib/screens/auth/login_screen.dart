import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_snack.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final auth = context.read<AuthProvider>();
      await auth.signIn(_email.text, _password.text);
      if (!mounted) return;
      final route = switch (auth.role) {
        UserRole.customer => AppRoutes.customerHome,
        UserRole.seller when auth.sellerStatus == 'approved' =>
          AppRoutes.sellerHome,
        UserRole.seller => AppRoutes.sellerPending,
        UserRole.admin => AppRoutes.adminHome,
        null => AppRoutes.login,
      };
      if (route == AppRoutes.login) {
        AppSnack.error(context, 'Unable to determine your account role.');
        return;
      }
      Navigator.of(context).pushNamedAndRemoveUntil(route, (_) => false);
    } on AuthOperationException catch (error) {
      if (mounted) AppSnack.error(context, error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeader(
                      title: 'Welcome back',
                      subtitle: 'Log in to continue to Farmer Market',
                    ),
                    const SizedBox(height: 28),
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _password,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      validator: Validators.password,
                      onSubmitted: (_) => _login(),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context)
                            .pushNamed(AppRoutes.forgotPassword),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      label: 'Log in',
                      loading: _submitting,
                      onPressed: _login,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Local admin demo: ${AuthProvider.demoAdminEmail} · '
                      '${AuthProvider.demoAdminPassword}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Don't have an account?"),
                        TextButton(
                          onPressed: () => Navigator.of(context)
                              .pushNamed(AppRoutes.register),
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
