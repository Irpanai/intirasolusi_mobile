import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../blocs/dashboard/dashboard_bloc.dart';
import '../../blocs/article/article_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../data/repositories/dashboard_repository.dart';
import '../../../data/models/article_model.dart';

class DashboardBody extends StatefulWidget {
  const DashboardBody({super.key});

  @override
  State<DashboardBody> createState() => _DashboardBodyState();
}

class _DashboardBodyState extends State<DashboardBody> {
  @override
  void initState() {
    super.initState();
    context.read<DashboardBloc>().add(DashboardLoad());
    context.read<ArticleBloc>().add(ArticleLoadLatest(count: 3));
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
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
                  // Header with Stats Card
                  _buildHeader(context, state.data),

                  // Content
                  _buildContent(context, state.data),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader(BuildContext context, DashboardData data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row - Greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat ${_getGreeting()}',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data.customer.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
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
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.textPrimary,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main Stats Card - Eye catching
            _buildMainStatsCard(data),
          ],
        ),
      ),
    );
  }

  Widget _buildMainStatsCard(DashboardData data) {
    final hasActiveTransaction = data.stats.activeTransactions > 0;
    final hasOverdue = data.stats.overdueTransactions > 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasOverdue 
              ? [const Color(0xFFFF6B6B), const Color(0xFFEE5A5A)]
              : [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (hasOverdue ? const Color(0xFFFF6B6B) : AppColors.primary).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon and label row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasOverdue ? Icons.warning_rounded : Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasOverdue ? 'Perhatian!' : 'Total Pinjaman Aktif',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasOverdue) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${data.stats.overdueTransactions} transaksi jatuh tempo',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Main message
          if (hasActiveTransaction) ...[
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(text: 'Kamu memiliki '),
                  TextSpan(
                    text: '${data.stats.activeTransactions} transaksi gadai',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' aktif'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.stats.totalLoanFormatted,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ] else ...[
            const Text(
              'Belum ada transaksi aktif',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ajukan gadai pertamamu sekarang!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Quick stats row
          // Row(
          //   children: [
          //     _buildMiniStat(
          //       icon: Icons.receipt_long_outlined,
          //       label: 'Aktif',
          //       value: '${data.stats.activeTransactions}',
          //     ),
          //     const SizedBox(width: 24),
          //     _buildMiniStat(
          //       icon: Icons.pending_actions_outlined,
          //       label: 'Pending',
          //       value: '${data.stats.pendingRequests}',
          //     ),
          //     if (hasOverdue) ...[
          //       const SizedBox(width: 24),
          //       _buildMiniStat(
          //         icon: Icons.warning_amber_outlined,
          //         label: 'Jatuh Tempo',
          //         value: '${data.stats.overdueTransactions}',
          //         isWarning: true,
          //       ),
          //     ],
          //   ],
          // ),
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
          const SizedBox(height: 8),
          
          // Quick Actions
          _buildQuickActions(context),
          const SizedBox(height: 16),

          // Financial Tools Card
          _buildFinancialToolsCard(context),
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
            const SizedBox(height: 16),
          ],

          // Latest News Section
          _buildLatestNewsSection(context),

          const SizedBox(height: 100), // Space for bottom nav
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

  Widget _buildFinancialToolsCard(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/financial-tools'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A237E).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.auto_graph_rounded, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tool Keuangan',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '9 kalkulator untuk investasi, bisnis & kredit',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withValues(alpha: 0.7), size: 18),
          ],
        ),
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
      case 'reviewing':
      case 'direview':
        return (icon: Icons.rate_review, color: Colors.orange);
      case 'approved':
      case 'disetujui':
        return (icon: Icons.check_circle, color: AppColors.success);
      case 'rejected':
      case 'ditolak':
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

  Widget _buildLatestNewsSection(BuildContext context) {
    return BlocBuilder<ArticleBloc, ArticleState>(
      builder: (context, state) {
        if (state is ArticleLatestLoaded && state.articles.isNotEmpty) {
          return Column(
            children: [
              _buildSectionHeader(
                context,
                'Berita Terbaru',
                () => Navigator.pushNamed(context, '/articles'),
              ),
              const SizedBox(height: 12),
              ...state.articles.map((article) => _buildNewsCard(context, article)),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildNewsCard(BuildContext context, ArticleModel article) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/articles/${article.slug}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 100,
                height: 90,
                child: article.featuredImageThumb != null
                    ? Image.network(
                        article.featuredImageThumb!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.background,
                          child: Icon(Icons.article_outlined, color: AppColors.textMuted, size: 28),
                        ),
                      )
                    : Container(
                        color: AppColors.background,
                        child: Icon(Icons.article_outlined, color: AppColors.textMuted, size: 28),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (article.category != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          article.category!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (article.publishedAt != null)
                      Text(
                        DateFormat('dd MMM yyyy').format(article.publishedAt!),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),
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
