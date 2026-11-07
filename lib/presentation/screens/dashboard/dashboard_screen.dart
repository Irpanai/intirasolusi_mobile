import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/custom_bottom_nav.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../data/repositories/dashboard_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardLoad());
  }

  void _handleNavTap(NavItem item) {
    switch (item) {
      case NavItem.home:
        // Already on home
        break;
      case NavItem.transactions:
        Navigator.pushNamed(context, '/transactions');
        break;
      case NavItem.pawnRequest:
        Navigator.pushNamed(context, '/pawn-requests');
        break;
      case NavItem.profile:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          if (state is DashboardLoading) {
            return const LoadingWidget(message: 'Memuat dashboard...');
          }

          if (state is DashboardError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<DashboardBloc>().add(DashboardLoad()),
            );
          }

          if (state is DashboardLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<DashboardBloc>().add(DashboardRefresh());
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Gradient Header
                    _buildHeader(context, state.data),

                    // Content
                    Transform.translate(
                      offset: const Offset(0, -32),
                      child: _buildContent(context, state.data),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: CustomBottomNav.buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNav(
        currentItem: NavItem.home,
        onItemTapped: _handleNavTap,
      ),
    );
  }

  Widget _buildHeader(BuildContext context, DashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, bottom: 56, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat ${_getGreeting()}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.customer.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Show notifications
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.account_balance_wallet,
                    label: 'Total Pinjaman Aktif',
                    value: data.stats.totalLoanFormatted,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.receipt_long,
                    label: 'Transaksi Aktif',
                    value: '${data.stats.activeTransactions}',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, DashboardData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          _buildQuickActions(context),
          const SizedBox(height: 20),

          // Profile Incomplete Alert
          if (!data.customer.isProfileComplete) ...[
            _buildProfileAlert(context),
            const SizedBox(height: 16),
          ],

          // Alerts (filter out profile-related alerts since _buildProfileAlert already handles it)
          ...data.alerts
              .where((alert) =>
                  !alert.message.toLowerCase().contains('lengkapi') &&
                  !alert.message.toLowerCase().contains('profil'))
              .map((alert) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAlertBanner(context, alert),
                  )),

          // Recent Requests Section
          if (data.recentRequests.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Pengajuan Terbaru',
              () => Navigator.pushNamed(context, '/pawn-requests'),
            ),
            const SizedBox(height: 12),
            ...data.recentRequests
                .take(3)
                .map((req) => _buildRequestCard(context, req)),
            const SizedBox(height: 16),
          ],

          // Active Transactions Section
          if (data.activeTransactions.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Transaksi Aktif',
              () => Navigator.pushNamed(context, '/transactions'),
            ),
            const SizedBox(height: 12),
            ...data.activeTransactions
                .take(3)
                .map((tx) => _buildTransactionCard(context, tx)),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menu Cepat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickActionItem(
                icon: Icons.add_box_rounded,
                label: 'Pengajuan',
                color: AppColors.primary,
                onTap: () => NavigationHelper.goToPawnRequestCreate(context),
              ),
              _buildQuickActionItem(
                icon: Icons.calculate_rounded,
                label: 'Kalkulator',
                color: AppColors.secondary,
                onTap: () => Navigator.pushNamed(context, '/calculator'),
              ),
              _buildQuickActionItem(
                icon: Icons.receipt_long_rounded,
                label: 'Transaksi',
                color: Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/transactions'),
              ),
              _buildQuickActionItem(
                icon: Icons.location_on_rounded,
                label: 'Cabang',
                color: Colors.purple,
                onTap: () => Navigator.pushNamed(context, '/branches'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAlert(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.warning_rounded,
              color: AppColors.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lengkapi Profil Anda',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lengkapi data untuk mengajukan gadai',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/complete-profile'),
            style: TextButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Lengkapi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner(BuildContext context, DashboardAlert alert) {
    Color color;
    IconData icon;

    switch (alert.type) {
      case 'warning':
        color = AppColors.warning;
        icon = Icons.warning_amber_rounded;
        break;
      case 'error':
        color = AppColors.error;
        icon = Icons.error_outline;
        break;
      default:
        color = AppColors.info;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              alert.message,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    VoidCallback onViewAll,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Row(
            children: [
              Text(
                'Lihat Semua',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequestCard(BuildContext context, RecentRequest request) {
    final statusInfo = _getStatusInfo(request.status);
    
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/pawn-requests/${request.code}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusInfo.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                statusInfo.icon,
                color: statusInfo.color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.code,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.collateralName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    request.loanAmountFormatted.isNotEmpty 
                        ? request.loanAmountFormatted 
                        : Formatters.formatCurrency(request.loanAmount),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  ({IconData icon, Color color}) _getStatusInfo(String status) {
    final statusLower = status.toLowerCase();
    
    switch (statusLower) {
      case 'pending':
      case 'menunggu':
        return (icon: Icons.hourglass_empty, color: Colors.amber);
      case 'under_review':
      case 'review':
      case 'direview':
        return (icon: Icons.rate_review, color: Colors.orange);
      case 'approved':
      case 'disetujui':
        return (icon: Icons.check_circle, color: AppColors.success);
      case 'rejected':
        return (icon: Icons.cancel, color: Colors.red);
      case 'cancelled':
        return (icon: Icons.cancel, color: Colors.grey);
      case 'converted':
      case 'dikonversi':
        return (icon: Icons.swap_horiz, color: Colors.blue);
      default:
        return (icon: Icons.pending_actions, color: AppColors.primary);
    }
  }

  Widget _buildTransactionCard(BuildContext context, ActiveTransaction transaction) {
    final bool isOverdue = transaction.isOverdue;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/transactions/${transaction.code}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isOverdue
              ? Border.all(color: AppColors.error.withValues(alpha: 0.3))
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isOverdue
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.receipt_long,
                color: isOverdue ? AppColors.error : AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction.code,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                      if (isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'JATUH TEMPO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else if (transaction.daysUntilDue != null)
                        Text(
                          '${transaction.daysUntilDue} hari lagi',
                          style: TextStyle(
                            fontSize: 12,
                            color: transaction.daysUntilDue! <= 7
                                ? AppColors.warning
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.collateralName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    transaction.loanAmountFormatted.isNotEmpty 
                        ? transaction.loanAmountFormatted 
                        : Formatters.formatCurrency(transaction.loanAmount),
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Pagi';
    if (hour < 15) return 'Siang';
    if (hour < 18) return 'Sore';
    return 'Malam';
  }
}
