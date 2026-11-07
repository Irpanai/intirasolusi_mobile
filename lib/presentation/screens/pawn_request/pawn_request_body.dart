import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/pawn_request/pawn_request_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/filter_tabs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/pawn_request_model.dart';

class PawnRequestBody extends StatefulWidget {
  const PawnRequestBody({super.key});

  @override
  State<PawnRequestBody> createState() => _PawnRequestBodyState();
}

class _PawnRequestBodyState extends State<PawnRequestBody> {
  String _selectedFilter = 'all';
  final List<FilterTab> _filters = [
    const FilterTab(id: 'all', label: 'Semua'),
    const FilterTab(id: 'pending', label: 'Menunggu'),
    const FilterTab(id: 'under_review', label: 'Direview'),
    const FilterTab(id: 'approved', label: 'Disetujui'),
    const FilterTab(id: 'converted', label: 'Dikonversi'),
    const FilterTab(id: 'rejected', label: 'Ditolak'),
    const FilterTab(id: 'cancelled', label: 'Dibatalkan'),
  ];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    final status = _selectedFilter == 'all' ? null : _selectedFilter;
    context.read<PawnRequestBloc>().add(PawnRequestLoadList(status: status));
  }

  void _onFilterChanged(String filterId) {
    setState(() {
      _selectedFilter = filterId;
    });
    _loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
          child: BlocBuilder<PawnRequestBloc, PawnRequestState>(
            builder: (context, state) {
              if (state is PawnRequestLoading) {
                return const LoadingWidget(message: 'Memuat pengajuan...');
              }

              if (state is PawnRequestError) {
                return AppErrorWidget(
                  message: state.message,
                  onRetry: _loadRequests,
                );
              }

              if (state is PawnRequestListLoaded) {
                if (state.requests.isEmpty) {
                  return EmptyState(
                    icon: Icons.description_outlined,
                    title: 'Belum Ada Pengajuan',
                    subtitle: 'Pengajuan gadai Anda akan muncul di sini',
                    actionLabel: 'Ajukan Sekarang',
                    onAction: () {
                      NavigationHelper.goToPawnRequestCreate(context);
                    },
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadRequests();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.requests.length + 1, // +1 for bottom padding
                    itemBuilder: (context, index) {
                      if (index == state.requests.length) {
                        return const SizedBox(height: 80); // Space for bottom nav
                      }
                      return _buildRequestCard(state.requests[index]);
                    },
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pengajuan Gadai',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () {
                NavigationHelper.goToPawnRequestCreate(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    const Text(
                      'Ajukan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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

  Widget _buildRequestCard(PawnRequestModel request) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/pawn-requests/${request.code}').then((_) {
          // Reload list when returning from detail screen
          _loadRequests();
        });
      },
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
                    request.code,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  StatusBadge.fromString(request.status),
                ],
              ),
              const SizedBox(height: 12),

              // Collateral Name
              Text(
                request.collateralName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              if (request.categoryName != null) ...[
                const SizedBox(height: 4),
                Text(
                  request.categoryName!,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pinjaman Diajukan',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatCurrency(request.loanAmount),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  if (request.createdAt != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Tanggal Ajuan',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatDate(request.createdAt!),
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Branch info
              if (request.branchName != null) ...[
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
                      request.branchName!,
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
