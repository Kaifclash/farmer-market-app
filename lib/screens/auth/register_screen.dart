import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_snack.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/auth_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _shopName = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  // Only customer and seller can be chosen. Admin is never selectable.
  bool _isSeller = false;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _shopName.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await context.read<AuthProvider>().register(
            name: _name.text,
            email: _email.text,
            phone: _phone.text,
            password: _password.text,
            asSeller: _isSeller,
            shopName: _shopName.text,
          );
      if (!mounted) return;
      AppSnack.success(
        context,
        _isSeller
            ? 'Account created. Your seller application is pending approval.'
            : 'Your account has been created.',
      );
      Navigator.of(context).pushNamedAndRemoveUntil(
        _isSeller ? AppRoutes.sellerPending : AppRoutes.customerHome,
        (_) => false,
      );
    } on AuthOperationException catch (error) {
      if (mounted) AppSnack.error(context, error.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
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
                      title: 'Join Farmer Market',
                      subtitle: 'Buy fresh produce or sell your harvest',
                    ),
                    const SizedBox(height: 24),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.shopping_basket_outlined),
                          label: Text('Customer'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.storefront_outlined),
                          label: Text('Seller'),
                        ),
                      ],
                      selected: {_isSeller},
                      onSelectionChanged: (s) =>
                          setState(() => _isSeller = s.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppColors.lightLeaf,
                        selectedForegroundColor: AppColors.forestGreen,
                      ),
                    ),
                    if (_isSeller)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Sellers must be approved by an admin before they can list products.',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    if (_isSeller) ...[
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _shopName,
                        label: 'Farm or shop name',
                        icon: Icons.storefront_outlined,
                        validator: (value) => _isSeller
                            ? Validators.required(value, 'Farm or shop name')
                            : null,
                      ),
                    ],
                    const SizedBox(height: 20),
                    AppTextField(
                      controller: _name,
                      label: 'Full name',
                      icon: Icons.person_outline,
                      validator: (v) => Validators.required(v, 'Name'),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _email,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _phone,
                      label: 'Phone',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: Validators.phone,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _password,
                      label: 'Password',
                      icon: Icons.lock_outline,
                      obscure: true,
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _confirm,
                      label: 'Confirm password',
                      icon: Icons.lock_outline,
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      validator:
                          Validators.confirmPassword(() => _password.text),
                      onSubmitted: (_) => _submit(),
                    ),
                    const SizedBox(height: 24),
                    AppButton(
                      label: 'Create account',
                      loading: _submitting,
                      onPressed: _submit,
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
