import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/transaction_model.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String transactionCode;

  const TransactionDetailScreen({
    super.key,
    required this.transactionCode,
  });

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TransactionBloc>().add(
      TransactionLoadDetail(code: widget.transactionCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<TransactionBloc, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const LoadingWidget(message: 'Memuat detail transaksi...');
          }

          if (state is TransactionError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: () => context.read<TransactionBloc>().add(
                TransactionLoadDetail(code: widget.transactionCode),
              ),
            );
          }

          if (state is TransactionDetailLoaded) {
            return _buildContent(context, state.transaction);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, TransactionDetailModel tx) {
    final bool isOverdue = tx.isOverdue;
    final bool isActive = tx.status.toLowerCase() == 'active';
    final bool isCompleted = tx.status.toLowerCase() == 'completed';

    return CustomScrollView(
      slivers: [
        // App Bar - Simple header
        SliverAppBar(
          pinned: true,
          backgroundColor: AppColors.primary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Detail Transaksi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),

        // Content
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Transaction Summary Card
              _buildTransactionSummaryCard(tx),
              const SizedBox(height: 16),

              // Due Date Card
              if (!isCompleted) ...[
                _buildDueDateCard(tx),
                const SizedBox(height: 16),
              ],

              // Collateral Info
              _buildSection(
                title: 'Informasi Agunan',
                child: Column(
                  children: [
                    _buildInfoRow('Nama Agunan', tx.collateralName),
                    if (tx.collateralDescription != null)
                      _buildInfoRow('Deskripsi', tx.collateralDescription!),
                    if (tx.appraisedValueFormatted != null)
                      _buildInfoRow('Nilai Taksir', tx.appraisedValueFormatted!),
                  ],
                ),
              ),

              // Photos
              if (tx.collateralPhotos != null && tx.collateralPhotos!.isNotEmpty)
                _buildSection(
                  title: 'Foto Agunan',
                  child: SizedBox(
                    height: 100,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: tx.collateralPhotos!.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final photo = tx.collateralPhotos![index];
                        return GestureDetector(
                          onTap: () => _showFullImage(
                            context, 
                            photo.url,
                            tx.collateralPhotos!,
                            index,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: photo.url,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                              memCacheWidth: 200, // Cache smaller version for thumbnail
                              memCacheHeight: 200,
                              placeholder: (context, url) => Container(
                                width: 100,
                                height: 100,
                                color: AppColors.border,
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 100,
                                height: 100,
                                color: AppColors.border,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image_outlined,
                                      color: AppColors.textMuted,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Lihat',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

              // Transaction Details
              _buildSection(
                title: 'Detail Transaksi',
                child: Column(
                  children: [
                    _buildInfoRow('Produk', tx.productName ?? '-'),
                    _buildInfoRow('Cabang', tx.branchName ?? '-'),
                    _buildInfoRow(
                      'Tanggal Gadai',
                      tx.transactionDateFormatted ?? tx.transactionDate ?? '-',
                    ),
                    if (tx.initialDueDateFormatted != null)
                      _buildInfoRow('Jatuh Tempo Awal', tx.initialDueDateFormatted!),
                    _buildInfoRow(
                      'Jatuh Tempo Saat Ini',
                      tx.dueDateFormatted ?? tx.dueDate ?? '-',
                    ),
                    _buildInfoRow(
                      'Perpanjangan',
                      '${tx.extensionCount}x${tx.maxExtensions != null ? ' / Max ${tx.maxExtensions}x' : ''}',
                    ),
                  ],
                ),
              ),

              // Financial Details
              _buildSection(
                title: 'Detail Keuangan',
                child: Column(
                  children: [
                    _buildInfoRow(
                      'Nilai Pinjaman',
                      tx.loanAmountFormatted ?? Formatters.formatCurrency(tx.loanAmount),
                      valueColor: AppColors.primary,
                      isBold: true,
                    ),
                    if (tx.adminFeeFormatted != null)
                      _buildInfoRow('Biaya Admin', tx.adminFeeFormatted!),
                    if (tx.initialFeeFormatted != null)
                      _buildInfoRow('Biaya Awal', tx.initialFeeFormatted!),
                    if (tx.cashDisbursedFormatted != null)
                      _buildInfoRow(
                        'Uang Diterima',
                        tx.cashDisbursedFormatted!,
                        valueColor: AppColors.success,
                        isBold: true,
                      ),
                  ],
                ),
              ),

              // Barcode
              if (tx.barcode != null)
                _buildSection(
                  title: 'Barcode',
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: BarcodeWidget(
                          barcode: Barcode.code128(),
                          data: tx.barcode!,
                          width: double.infinity,
                          height: 80,
                          drawText: false,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        tx.barcode!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

              // Notes
              if (tx.notes != null && tx.notes!.isNotEmpty)
                _buildSection(
                  title: 'Catatan',
                  child: Text(
                    tx.notes!,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),

              // Actions
              if (isActive || isOverdue) _buildActions(tx),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionSummaryCard(TransactionDetailModel tx) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
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
        children: [
          // Transaction Code
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kode Transaksi',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                tx.transactionCode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Divider
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          
          // Loan Amount - Large & Centered
          Text(
            'Nilai Pinjaman',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            tx.loanAmountFormatted ?? Formatters.formatCurrency(tx.loanAmount),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          
          // Divider
          Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          
          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              StatusBadge.fromString(tx.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateCard(TransactionDetailModel tx) {
    final bool isOverdue = tx.isOverdue;
    final int? daysUntilDue = tx.daysUntilDue;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOverdue
            ? AppColors.error.withValues(alpha: 0.1)
            : daysUntilDue != null && daysUntilDue <= 7
                ? AppColors.warning.withValues(alpha: 0.1)
                : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOverdue
              ? AppColors.error.withValues(alpha: 0.3)
              : daysUntilDue != null && daysUntilDue <= 7
                  ? AppColors.warning.withValues(alpha: 0.3)
                  : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isOverdue
                  ? AppColors.error.withValues(alpha: 0.2)
                  : daysUntilDue != null && daysUntilDue <= 7
                      ? AppColors.warning.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isOverdue ? Icons.warning_rounded : Icons.calendar_today,
              color: isOverdue
                  ? AppColors.error
                  : daysUntilDue != null && daysUntilDue <= 7
                      ? AppColors.warning
                      : AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOverdue ? 'Sudah Jatuh Tempo' : 'Jatuh Tempo',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tx.dueDateFormatted ?? tx.dueDate ?? '-',
                  style: TextStyle(
                    color: isOverdue ? AppColors.error : AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (daysUntilDue != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isOverdue
                    ? AppColors.error
                    : daysUntilDue <= 7
                        ? AppColors.warning
                        : AppColors.success,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOverdue
                    ? '${daysUntilDue.abs()} hari lewat'
                    : '$daysUntilDue hari lagi',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          child,
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
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(TransactionDetailModel tx) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (tx.canExtend) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Navigate to extend screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur perpanjangan segera hadir')),
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Perpanjang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // TODO: Navigate to redeem screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fitur tebus segera hadir')),
                );
              },
              icon: const Icon(Icons.redeem),
              label: const Text('Tebus Barang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.success,
                side: const BorderSide(color: AppColors.success),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage(
    BuildContext context, 
    String imageUrl,
    List<CollateralPhotoModel> photos,
    int initialIndex,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullImageViewer(
          photos: photos,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _FullImageViewer extends StatefulWidget {
  final List<CollateralPhotoModel> photos;
  final int initialIndex;

  const _FullImageViewer({
    required this.photos,
    required this.initialIndex,
  });

  @override
  State<_FullImageViewer> createState() => _FullImageViewerState();
}

class _FullImageViewerState extends State<_FullImageViewer> {
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Foto ${_currentIndex + 1} dari ${widget.photos.length}',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: photo.url,
                fit: BoxFit.contain,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                errorWidget: (context, url, error) => Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.white54,
                      size: 64,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Gagal memuat gambar',
                      style: TextStyle(color: Colors.white54),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: widget.photos.length > 1
          ? Container(
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.photos.length,
                  (index) => Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.white24,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
