import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';
import '../utils/navigation_helper.dart';

enum NavItem {
  home,
  transactions,
  pawnRequest,
  profile,
}

class CustomBottomNav extends StatelessWidget {
  final NavItem currentItem;
  final Function(NavItem) onItemTapped;

  const CustomBottomNav({
    super.key,
    required this.currentItem,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: Colors.white,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.2),
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              icon: Icons.home_outlined,
              activeIcon: Icons.home,
              item: NavItem.home,
            ),
            _buildNavItem(
              context,
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
              item: NavItem.transactions,
            ),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(
              context,
              icon: Icons.description_outlined,
              activeIcon: Icons.description,
              item: NavItem.pawnRequest,
            ),
            _buildNavItem(
              context,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
              item: NavItem.profile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required NavItem item,
  }) {
    final isActive = currentItem == item;

    return GestureDetector(
      onTap: () => onItemTapped(item),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? AppColors.primary : AppColors.textMuted,
          size: 26,
        ),
      ),
    );
  }

  /// Build FAB widget - call this separately in Scaffold's floatingActionButton
  static Widget buildFAB(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => NavigationHelper.goToPawnRequestCreate(context),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 6,
      shape: const CircleBorder(),
      child: const Icon(Icons.add, size: 28),
    );
  }
}
