import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({
    super.key,
    required this.name,
    this.size = 28,
  });

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(_iconFor(name), size: size, color: AppColors.forestGreen);
  }
}

IconData _iconFor(String name) {
  switch (name.toLowerCase()) {
    case 'vegetables':
    case 'vegetable':
      return Icons.eco_outlined;
    case 'fruits':
    case 'fruit':
      return Icons.apple_outlined;
    case 'grains':
    case 'grain':
      return Icons.grass;
    case 'pulses':
    case 'pulse':
      return Icons.spa_outlined;
    case 'seeds':
    case 'seed':
      return Icons.grain;
    case 'fertilizers':
    case 'fertilizer':
      return Icons.science_outlined;
    default:
      return Icons.category_outlined;
  }
}
