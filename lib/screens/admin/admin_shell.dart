import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'admin_management_screens.dart';
import '../common/profile_screen.dart';

class _AdminTab {
  const _AdminTab(this.label, this.icon, this.page);
  final String label;
  final IconData icon;
  final Widget page;
}

/// Responsive admin layout: NavigationRail on wide screens (web/tablet),
/// BottomNavigationBar on phones.
class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  static const _tabs = <_AdminTab>[
    _AdminTab('Dashboard', Icons.dashboard_outlined, AdminDashboardScreen()),
    _AdminTab('Sellers', Icons.how_to_reg_outlined, AdminSellerScreen()),
    _AdminTab('Users', Icons.people_outline, AdminUsersScreen()),
    _AdminTab('Products', Icons.inventory_2_outlined, AdminProductsScreen()),
    _AdminTab('Orders', Icons.receipt_long_outlined, AdminOrdersScreen()),
    _AdminTab('Profile', Icons.person_outline, ProfileScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 800;
    final body = IndexedStack(
      index: _index,
      children: _tabs.map((t) => t.page).toList(),
    );

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: (i) => setState(() => _index = i),
              labelType: NavigationRailLabelType.all,
              backgroundColor: AppColors.white,
              selectedIconTheme:
                  const IconThemeData(color: AppColors.forestGreen),
              indicatorColor: AppColors.lightLeaf,
              leading: const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Icon(Icons.eco_rounded,
                    color: AppColors.forestGreen, size: 32),
              ),
              destinations: _tabs
                  .map((t) => NavigationRailDestination(
                      icon: Icon(t.icon), label: Text(t.label)))
                  .toList(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: body),
          ],
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: _tabs
            .map((t) =>
                BottomNavigationBarItem(icon: Icon(t.icon), label: t.label))
            .toList(),
      ),
    );
  }
}
