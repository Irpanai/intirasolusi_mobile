import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/custom_bottom_nav.dart';
import '../../../core/widgets/filter_tabs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction_model.dart';

class TransactionListScreen extends StatefulWidget {
  const TransactionListScreen({super.key});

  @override
  State<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  String _selectedFilter = 'all';
  final List<FilterTab> _filters = [
    const FilterTab(id: 'all', label: 'Semua'),
    const FilterTab(id: 'active', label: 'Aktif'),
    const FilterTab(id: 'overdue', label: 'Jatuh Tempo'),
    const FilterTab(id: 'completed', label: 'Selesai'),
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    final status = _selectedFilter == 'all' ? null : _selectedFilter;
    context.read<TransactionBloc>().add(TransactionLoadList(status: status));
  }

  void _onFilterChanged(String filterId) {
    setState(() {
      _selectedFilter = filterId;
    });
    _loadTransactions();
  }

  void _handleNavTap(NavItem item) {
    switch (item) {
      case NavItem.home:
        Navigator.pushReplacementNamed(context, '/dashboard');
        break;
      case NavItem.transactions:
        // Already on transactions
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
      body: Column(
        children: [
          // Header
          _buildHeader(),

          // Filter Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: FilterTabs(
              tabs: _filters,
              selectedId: _selectedFilter,
              onChanged: _onFilterChanged,
            ),
          ),

          // Content
          Expanded(
            child: BlocBuilder<TransactionBloc, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const LoadingWidget(message: 'Memuat transaksi...');
                }

                if (state is TransactionError) {
                  return AppErrorWidget(
                    message: state.message,
                    onRetry: _loadTransactions,
                  );
                }

                if (state is TransactionListLoaded) {
                  if (state.transactions.isEmpty) {
                    return const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Belum Ada Transaksi',
                      subtitle: 'Transaksi Anda akan muncul di sini',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<TransactionBloc>().add(TransactionRefresh());
                    },
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Summary Cards
                        _buildSummaryCards(state.transactions),
                        const SizedBox(height: 16),

                        // Transaction List
                        ...state.transactions.map((tx) => _buildTransactionCard(tx)),
                      ],
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: CustomBottomNav.buildFAB(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: CustomBottomNav(
        currentItem: NavItem.transactions,
        onItemTapped: _handleNavTap,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, bottom: 20, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Icon(
                Icons.arrow_back,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Transaksi Saya',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(List<TransactionModel> transactions) {
    final activeCount = transactions.where((t) => t.status == 'active').length;
    final totalLoan = transactions
        .where((t) => t.status == 'active')
        .fold<double>(0, (sum, t) => sum + t.loanAmount);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.receipt_long, color: AppColors.primary),
                const SizedBox(height: 8),
                Text(
                  'Transaksi Aktif',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$activeCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.account_balance_wallet, color: AppColors.success),
                const SizedBox(height: 8),
                Text(
                  'Total Pinjaman',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(totalLoan),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final bool isOverdue = transaction.isOverdue;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/transactions/${transaction.transactionCode}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    transaction.transactionCode,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  StatusBadge.fromString(transaction.status),
                ],
              ),
              const SizedBox(height: 12),

              // Collateral Name
              Text(
                transaction.collateralName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              if (transaction.productName != null) ...[
                const SizedBox(height: 4),
                Text(
                  transaction.productName!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Amount and Due Date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pinjaman',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        transaction.loanAmountFormatted ?? Formatters.formatCurrency(transaction.loanAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (transaction.dueDate != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Jatuh Tempo',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          transaction.dueDateFormatted ?? transaction.dueDate ?? '-',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isOverdue ? AppColors.error : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Branch info
              if (transaction.branchName != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      transaction.branchName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
