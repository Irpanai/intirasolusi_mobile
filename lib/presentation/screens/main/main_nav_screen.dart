import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/custom_bottom_nav.dart';
import '../dashboard/dashboard_body.dart';
import '../transaction/transaction_body.dart';
import '../pawn_request/pawn_request_body.dart';
import '../profile/profile_body.dart';

class MainNavScreen extends StatefulWidget {
  final int initialIndex;

  const MainNavScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavTap(NavItem item) {
    final newIndex = _getIndexFromNavItem(item);
    if (newIndex != _currentIndex) {
      setState(() {
        _currentIndex = newIndex;
      });
    }
  }

  int _getIndexFromNavItem(NavItem item) {
    switch (item) {
      case NavItem.home:
        return 0;
      case NavItem.transactions:
        return 1;
      case NavItem.pawnRequest:
        return 2;
      case NavItem.profile:
        return 3;
    }
  }

  NavItem _getNavItemFromIndex(int index) {
    switch (index) {
      case 0:
        return NavItem.home;
      case 1:
        return NavItem.transactions;
      case 2:
        return NavItem.pawnRequest;
      case 3:
        return NavItem.profile;
      default:
        return NavItem.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          DashboardBody(),
          TransactionBody(),
          PawnRequestBody(),
          ProfileBody(),
        ],
      ),
      floatingActionButton: CustomBottomNav.buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNav(
        currentItem: _getNavItemFromIndex(_currentIndex),
        onItemTapped: _onNavTap,
      ),
    );
  }
}
