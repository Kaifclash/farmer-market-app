import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/app_button.dart';

class _Page {
  const _Page(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    _Page(Icons.agriculture_rounded, 'Buy direct from farmers',
        'Fresh vegetables, fruits, grains and more from sellers near you.'),
    _Page(Icons.storefront_rounded, 'Sell your harvest',
        'List products, manage stock and track orders from one place.'),
    _Page(Icons.local_shipping_rounded, 'Simple, trusted delivery',
        'Pay on delivery and follow every order from farm to doorstep.'),
  ];

  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await context.read<AppStateProvider>().completeOnboarding();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _pages.length - 1;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(36),
                          decoration: const BoxDecoration(
                            color: AppColors.lightLeaf,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(p.icon,
                              size: 88, color: AppColors.forestGreen),
                        ),
                        const SizedBox(height: 40),
                        Text(p.title,
                            textAlign: TextAlign.center,
                            style: text.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.forestGreen)),
                        const SizedBox(height: 12),
                        Text(p.body,
                            textAlign: TextAlign.center,
                            style: text.bodyLarge
                                ?.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 8,
                  width: i == _index ? 24 : 8,
                  decoration: BoxDecoration(
                    color:
                        i == _index ? AppColors.forestGreen : AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: AppButton(
                label: last ? 'Get started' : 'Next',
                onPressed: last
                    ? _finish
                    : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
