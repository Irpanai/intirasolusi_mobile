import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/filter_tabs.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction_model.dart';

class TransactionBody extends StatefulWidget {
  const TransactionBody({super.key});

  @override
  State<TransactionBody> createState() => _TransactionBodyState();
}

class _TransactionBodyState extends State<TransactionBody> {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _buildHeader(),

        // Filter Tabs
        Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: FilterTabs(
            tabs: _filters,
            selectedId: _selectedFilter,
            onChanged: _onFilterChanged,
          ),
        ),

        // Content List
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
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<TransactionBloc>().add(TransactionRefresh());
                  },
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    children: [
                      // Summary Card (Screen 3 Reference Style)
                      _buildPortfolioSummaryCard(state.transactions),
                      const SizedBox(height: 16),

                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daftar Transaksi Gadai',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${state.transactions.length} Total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Transaction Cards
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
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF14532D), // Deep green 900
            Color(0xFF15803D), // Emerald 700
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Portofolio Gadai',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Monitoring status dan rincian transaksi gadai Anda.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortfolioSummaryCard(List<TransactionModel> transactions) {
    final activeCount = transactions.where((t) => t.status.toLowerCase() == 'active').length;
    final overdueCount = transactions.where((t) => t.isOverdue).length;
    final totalLoan = transactions
        .where((t) => t.status.toLowerCase() == 'active' || t.status.toLowerCase() == 'overdue')
        .fold<double>(0, (sum, t) => sum + t.loanAmount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D5428), // Deep forest
            Color(0xFF146834), // Rich emerald
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL TRANSAKSI AKTIF',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$activeCount Transaksi',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Total Modal Pinjaman
          Text(
            'Total Modal Gadai (Terkunci)',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Formatters.formatCurrency(totalLoan),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 14),

          // Bottom Info Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: overdueCount > 0
                      ? const Color(0xFFEF4444).withValues(alpha: 0.85)
                      : Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      overdueCount > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      color: Colors.white,
                      size: 13,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      overdueCount > 0
                          ? '$overdueCount Jatuh Tempo'
                          : 'Semua Status Lancar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: Colors.white.withValues(alpha: 0.75),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Agunan Tersimpan Aman',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(TransactionModel transaction) {
    final bool isOverdue = transaction.isOverdue;
    final iconData = _getCategoryIcon(transaction.collateralName);

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/transactions/${transaction.transactionCode}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0),
            width: isOverdue ? 1.2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isOverdue ? const Color(0xFFFEE2E2) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: isOverdue ? AppColors.error : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.collateralName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        transaction.transactionCode,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        transaction.loanAmountFormatted ?? Formatters.formatCurrency(transaction.loanAmount),
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOverdue
                    ? const Color(0xFFFEE2E2)
                    : (transaction.status.toLowerCase() == 'completed'
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFDCFCE7)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isOverdue
                    ? 'Jatuh Tempo'
                    : (transaction.status.toLowerCase() == 'completed'
                        ? 'Lunas'
                        : (transaction.dueDateFormatted != null
                            ? transaction.dueDateFormatted!
                            : 'Aktif')),
                style: TextStyle(
                  color: isOverdue
                      ? const Color(0xFFDC2626)
                      : (transaction.status.toLowerCase() == 'completed'
                          ? AppColors.textMuted
                          : const Color(0xFF15803D)),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Transaksi Gadai',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Anda belum memiliki transaksi gadai pada filter ini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('emas') || lower.contains('gold') || lower.contains('kalung') || lower.contains('cincin')) {
      return Icons.monetization_on_outlined;
    }
    if (lower.contains('hp') || lower.contains('phone') || lower.contains('iphone') || lower.contains('samsung') || lower.contains('ipad')) {
      return Icons.smartphone_rounded;
    }
    if (lower.contains('laptop') || lower.contains('rog') || lower.contains('macbook')) {
      return Icons.laptop_mac_rounded;
    }
    if (lower.contains('kamera') || lower.contains('sony') || lower.contains('canon')) {
      return Icons.camera_alt_outlined;
    }
    if (lower.contains('motor') || lower.contains('honda') || lower.contains('yamaha')) {
      return Icons.two_wheeler_rounded;
    }
    return Icons.devices_other_rounded;
  }
}
