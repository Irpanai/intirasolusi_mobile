import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/pawn_request/pawn_request_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/filter_tabs.dart';
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
          color: AppColors.background,
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
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    _loadRequests();
                  },
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    children: [
                      // Summary Card
                      _buildSummaryCard(state.requests),
                      const SizedBox(height: 16),

                      // Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Daftar Permohonan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${state.requests.length} Total',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Request Cards
                      ...state.requests.map((req) => _buildRequestCard(req)),
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
                    'Pengajuan Gadai',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => NavigationHelper.goToPawnRequestCreate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Ajukan Baru',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Monitoring status dan verifikasi taksiran barang Anda.',
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

  Widget _buildSummaryCard(List<PawnRequestModel> requests) {
    final pendingCount = requests.where((r) => r.status.toLowerCase() == 'pending').length;
    final approvedCount = requests.where((r) => r.status.toLowerCase() == 'approved').length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D5428),
            Color(0xFF146834),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TOTAL PENGAJUAN ONLINE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${requests.length} Permohonan',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Menunggu: $pendingCount',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Disetujui: $approvedCount',
                      style: const TextStyle(
                        color: Color(0xFF4ADE80),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              color: Colors.white,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(PawnRequestModel request) {
    final iconData = _getCategoryIcon(request.collateralName);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/pawn-requests/${request.code}').then((_) {
          _loadRequests();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                iconData,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.collateralName,
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
                        request.code,
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
                        Formatters.formatCurrency(request.loanAmount),
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
            StatusBadge.fromString(request.status),
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
                Icons.description_outlined,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum Ada Pengajuan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pengajuan gadai online Anda akan muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => NavigationHelper.goToPawnRequestCreate(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Ajukan Gadai Sekarang'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
