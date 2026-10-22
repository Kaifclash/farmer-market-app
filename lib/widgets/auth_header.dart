import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.lightLeaf,
            borderRadius: BorderRadius.circular(AppConstants.radius),
          ),
          child: const Icon(Icons.eco_rounded,
              size: 32, color: AppColors.forestGreen),
        ),
        const SizedBox(height: 20),
        Text(title,
            style: text.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.forestGreen,
            )),
        const SizedBox(height: 6),
        Text(subtitle,
            style: text.bodyMedium?.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
