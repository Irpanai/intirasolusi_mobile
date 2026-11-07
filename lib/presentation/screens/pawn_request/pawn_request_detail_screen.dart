import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/pawn_request_model.dart';
import '../../blocs/pawn_request/pawn_request_bloc.dart';

class PawnRequestDetailScreen extends StatefulWidget {
  final String requestCode;

  const PawnRequestDetailScreen({
    super.key,
    required this.requestCode,
  });

  @override
  State<PawnRequestDetailScreen> createState() => _PawnRequestDetailScreenState();
}

class _PawnRequestDetailScreenState extends State<PawnRequestDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PawnRequestBloc>().add(PawnRequestLoadDetail(code: widget.requestCode));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<PawnRequestBloc, PawnRequestState>(
        listener: (context, state) {
          if (state is PawnRequestCancelSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Pengajuan berhasil dibatalkan'),
                backgroundColor: AppColors.success,
              ),
            );
          } else if (state is PawnRequestError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PawnRequestLoading) {
            return const LoadingWidget(message: 'Memuat detail...');
          }

          if (state is PawnRequestError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<PawnRequestBloc>().add(
                    PawnRequestLoadDetail(code: widget.requestCode),
                  ),
            );
          }

          if (state is PawnRequestDetailLoaded) {
            return _buildContent(context, state.request);
          }

          return const LoadingWidget(message: 'Memuat...');
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, PawnRequestModel request) {
    return Column(
      children: [
        _buildHeader(context, request),
        Expanded(
          child: SingleChildScrollView(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: _buildBody(context, request),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, PawnRequestModel request) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 14, bottom: 44, left: 20, right: 20),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Kembali',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: request.code));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kode disalin'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              child: Row(
                children: [
                  Text(
                    request.code,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.copy,
                    color: Colors.white.withValues(alpha: 0.6),
                    size: 14,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.collateralName,
              style: const TextStyle(
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

  Widget _buildBody(BuildContext context, PawnRequestModel request) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 40),

          // Status Card
          _buildStatusCard(request),
          const SizedBox(height: 16),

          // Admin Notes (if any)
          if (request.adminNotes != null && request.adminNotes!.isNotEmpty) ...[
            _buildAdminNotesCard(request.adminNotes!),
            const SizedBox(height: 16),
          ],

          // Rejection Reason (if rejected)
          if (request.status.toUpperCase() == 'REJECTED' &&
              request.rejectionReason != null) ...[
            _buildRejectionCard(request.rejectionReason!),
            const SizedBox(height: 16),
          ],

          // Collateral Info Card
          _buildCollateralCard(request),
          const SizedBox(height: 16),

          // Loan Info Card
          _buildLoanCard(request),
          const SizedBox(height: 16),

          // Photos Card
          if (request.photos != null && request.photos!.isNotEmpty) ...[
            _buildPhotosCard(request.photos!),
            const SizedBox(height: 16),
          ],

          // Timeline Card
          _buildTimelineCard(request),
          const SizedBox(height: 16),

          // Action Buttons
          if (_canCancel(request.status)) ...[
            _buildActionButtons(context, request),
            const SizedBox(height: 16),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatusCard(PawnRequestModel request) {
    final statusInfo = _getStatusInfo(request.status);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusInfo.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      statusInfo.icon,
                      size: 16,
                      color: statusInfo.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      request.statusLabel ?? _getStatusLabel(request.status),
                      style: TextStyle(
                        color: statusInfo.color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress Tracker
          _buildProgressTracker(request.status),
        ],
      ),
    );
  }

  Widget _buildProgressTracker(String status) {
    final currentStep = _getProgressStep(status);
    
    return Row(
      children: [
        _buildProgressStep(1, 'Dikirim', currentStep >= 1),
        _buildProgressLine(currentStep >= 2),
        _buildProgressStep(2, 'Review', currentStep >= 2),
        _buildProgressLine(currentStep >= 3),
        _buildProgressStep(3, 'Keputusan', currentStep >= 3),
        _buildProgressLine(currentStep >= 4),
        _buildProgressStep(4, 'Selesai', currentStep >= 4),
      ],
    );
  }

  Widget _buildProgressStep(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    '$step',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? AppColors.textPrimary : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? AppColors.primary : Colors.grey.shade200,
      ),
    );
  }

  Widget _buildAdminNotesCard(String notes) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.amber.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catatan dari Admin',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.amber.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notes,
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectionCard(String reason) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cancel_outlined, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alasan Penolakan',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollateralCard(PawnRequestModel request) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.diamond, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Informasi Barang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Nama Barang', request.collateralName),
          if (request.collateralDescription != null)
            _buildInfoRow('Deskripsi', request.collateralDescription!),
          if (request.categoryName != null)
            _buildInfoRow('Kategori', request.categoryName!),
          if (request.estimatedValue != null)
            _buildInfoRow(
              'Estimasi Nilai',
              Formatters.formatCurrency(request.estimatedValue!),
            ),
        ],
      ),
    );
  }

  Widget _buildLoanCard(PawnRequestModel request) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Informasi Pinjaman',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (request.productName != null)
            _buildInfoRow('Produk', request.productName!),
          _buildInfoRow(
            'Pinjaman Diajukan',
            Formatters.formatCurrency(request.loanAmount),
            valueColor: AppColors.primary,
            isBold: true,
          ),
          if (request.branchName != null)
            _buildInfoRow('Cabang Preferensi', request.branchName!),
          if (request.notes != null && request.notes!.isNotEmpty)
            _buildInfoRow('Catatan', request.notes!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosCard(List<String> photos) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.photo_library, color: Colors.purple, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Foto Barang',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showPhotoViewer(context, photos, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photos[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade200,
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade400,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(PawnRequestModel request) {
    final timeline = _buildTimelineData(request);

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Riwayat',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...timeline.map((item) => _buildTimelineItem(item)),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(_TimelineItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: item.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.date,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, PawnRequestModel request) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showCancelConfirmation(context, request.code),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel, size: 18),
            SizedBox(width: 8),
            Text(
              'Batalkan Pengajuan',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Batalkan Pengajuan?'),
        content: const Text(
          'Pengajuan yang dibatalkan tidak dapat dikembalikan. Anda yakin ingin membatalkan pengajuan ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<PawnRequestBloc>().add(CancelPawnRequest(code: code));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Ya, Batalkan'),
          ),
        ],
      ),
    );
  }

  void _showPhotoViewer(BuildContext context, List<String> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoViewerScreen(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // Helper methods
  ({IconData icon, Color color}) _getStatusInfo(String status) {
    final statusUpper = status.toUpperCase();
    switch (statusUpper) {
      case 'PENDING':
        return (icon: Icons.hourglass_empty, color: Colors.amber);
      case 'REVIEWING':
      case 'UNDER_REVIEW':
        return (icon: Icons.rate_review, color: Colors.orange);
      case 'DOCUMENT_REQUIRED':
        return (icon: Icons.description, color: Colors.blue);
      case 'APPROVED':
        return (icon: Icons.check_circle, color: AppColors.success);
      case 'REJECTED':
        return (icon: Icons.cancel, color: Colors.red);
      case 'CANCELLED':
        return (icon: Icons.block, color: Colors.grey);
      case 'CONVERTED':
        return (icon: Icons.swap_horiz, color: Colors.blue);
      default:
        return (icon: Icons.help_outline, color: AppColors.textMuted);
    }
  }

  String _getStatusLabel(String status) {
    final statusUpper = status.toUpperCase();
    switch (statusUpper) {
      case 'PENDING':
        return 'Menunggu';
      case 'REVIEWING':
      case 'UNDER_REVIEW':
        return 'Sedang Direview';
      case 'DOCUMENT_REQUIRED':
        return 'Dokumen Diperlukan';
      case 'APPROVED':
        return 'Disetujui';
      case 'REJECTED':
        return 'Ditolak';
      case 'CANCELLED':
        return 'Dibatalkan';
      case 'CONVERTED':
        return 'Dikonversi';
      default:
        return status;
    }
  }

  int _getProgressStep(String status) {
    final statusUpper = status.toUpperCase();
    switch (statusUpper) {
      case 'PENDING':
        return 1;
      case 'REVIEWING':
      case 'UNDER_REVIEW':
      case 'DOCUMENT_REQUIRED':
        return 2;
      case 'APPROVED':
      case 'REJECTED':
        return 3;
      case 'CONVERTED':
      case 'CANCELLED':
        return 4;
      default:
        return 1;
    }
  }

  bool _canCancel(String status) {
    final statusUpper = status.toUpperCase();
    return statusUpper == 'PENDING' || statusUpper == 'REVIEWING' || statusUpper == 'UNDER_REVIEW';
  }

  List<_TimelineItem> _buildTimelineData(PawnRequestModel request) {
    final timeline = <_TimelineItem>[];

    if (request.createdAt != null) {
      timeline.add(_TimelineItem(
        title: 'Pengajuan Dibuat',
        date: Formatters.formatDateTime(request.createdAt!),
        color: AppColors.primary,
      ));
    }

    if (request.approvedAt != null) {
      timeline.add(_TimelineItem(
        title: 'Pengajuan Disetujui',
        date: Formatters.formatDateTime(request.approvedAt!),
        color: AppColors.success,
      ));
    }

    if (request.rejectedAt != null) {
      timeline.add(_TimelineItem(
        title: 'Pengajuan Ditolak',
        date: Formatters.formatDateTime(request.rejectedAt!),
        color: Colors.red,
      ));
    }

    return timeline;
  }
}

class _TimelineItem {
  final String title;
  final String date;
  final Color color;

  _TimelineItem({
    required this.title,
    required this.date,
    required this.color,
  });
}

// Photo Viewer Screen
class _PhotoViewerScreen extends StatefulWidget {
  final List<String> photos;
  final int initialIndex;

  const _PhotoViewerScreen({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<_PhotoViewerScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_currentIndex + 1} / ${widget.photos.length}'),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.photos[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white54,
                      size: 64,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
