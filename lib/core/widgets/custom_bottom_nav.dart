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
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      padding: EdgeInsets.zero,
      child: SizedBox(
        height: 62,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Beranda',
              item: NavItem.home,
            ),
            _buildNavItem(
              context,
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long_rounded,
              label: 'Transaksi',
              item: NavItem.transactions,
            ),
            const SizedBox(width: 52), // Space for FAB
            _buildNavItem(
              context,
              icon: Icons.description_outlined,
              activeIcon: Icons.description_rounded,
              label: 'Pengajuan',
              item: NavItem.pawnRequest,
            ),
            _buildNavItem(
              context,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
              label: 'Profil',
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
    required String label,
    required NavItem item,
  }) {
    final isActive = currentItem == item;

    return Expanded(
      child: GestureDetector(
        onTap: () => onItemTapped(item),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? const Color(0xFF15803D) : AppColors.textMuted,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? const Color(0xFF15803D) : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build FAB widget - call this separately in Scaffold's floatingActionButton
  static Widget buildFAB(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF14532D), // Pine green
            Color(0xFF16A34A), // Emerald green
          ],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF15803D).withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => NavigationHelper.goToPawnRequestCreate(context),
          customBorder: const CircleBorder(),
          child: const Center(
            child: Icon(
              Icons.add_rounded,
              size: 30,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
