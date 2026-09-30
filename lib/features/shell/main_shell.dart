import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// پوسته اصلی اپ — Bottom Navigation برای موبایل
class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/products')) return 1;
    if (location.startsWith('/articles')) return 2;
    if (location.startsWith('/orders')) return 3;
    if (location.startsWith('/more')) return 4;
    return 0;
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/products');
        break;
      case 2:
        context.go('/articles');
        break;
      case 3:
        context.go('/orders');
        break;
      case 4:
        context.go('/more');
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _calculateSelectedIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _NavItem(
                    icon: Icons.dashboard_outlined,
                    activeIcon: Icons.dashboard_rounded,
                    label: 'داشبورد',
                    isSelected: selectedIndex == 0,
                    onTap: () => _onItemTapped(context, 0),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.inventory_2_outlined,
                    activeIcon: Icons.inventory_2_rounded,
                    label: 'محصولات',
                    isSelected: selectedIndex == 1,
                    onTap: () => _onItemTapped(context, 1),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.article_outlined,
                    activeIcon: Icons.article_rounded,
                    label: 'مقالات',
                    isSelected: selectedIndex == 2,
                    onTap: () => _onItemTapped(context, 2),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.shopping_bag_outlined,
                    activeIcon: Icons.shopping_bag_rounded,
                    label: 'سفارش‌ها',
                    isSelected: selectedIndex == 3,
                    onTap: () => _onItemTapped(context, 3),
                  ),
                ),
                Expanded(
                  child: _NavItem(
                    icon: Icons.more_horiz_rounded,
                    activeIcon: Icons.more_horiz_rounded,
                    label: 'بیشتر',
                    isSelected: selectedIndex == 4,
                    onTap: () => _onItemTapped(context, 4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: color,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}