import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../blocs/transaction/transaction_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/app_network_image.dart';
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
    final bool isCompleted = tx.status.toLowerCase() == 'completed';

    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16),
            child: _buildBody(context, tx, isCompleted),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
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
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Tombol Kembali di kiri
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
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
              ),

              // Judul Detail Transaksi Gadai di tengah sejajar dengan tombol Kembali
              const Text(
                'Detail Transaksi Gadai',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TransactionDetailModel tx, bool isCompleted) {
    return Column(
      children: [
        // Kartu Baru: Ringkasan Transaksi, No. Akad, Agunan & Pinjaman
        _buildTransactionSummaryCard(tx),
        const SizedBox(height: 14),

        // Urgent Alert Banner
        _buildUrgentStatusBanner(tx),

        // Due Date Card
        if (!isCompleted) ...[
          _buildDueDateCard(tx),
          const SizedBox(height: 14),
        ],

        // Data Akad Card
        _buildAkadCard(tx),
        const SizedBox(height: 14),

        // Informasi Agunan & Foto
        _buildCollateralAndPhotosSection(context, tx),
        const SizedBox(height: 14),

        // Detail Transaksi & Keuangan
        _buildTransactionAndFinancialSection(tx),
        const SizedBox(height: 14),

        // Barcode
        if (tx.barcode != null) ...[
          _buildBarcodeSection(tx),
          const SizedBox(height: 14),
        ],

        // Catatan
        if (tx.notes != null && tx.notes!.isNotEmpty) ...[
          _buildNotesSection(tx),
          const SizedBox(height: 14),
        ],

        // Action Buttons
        if (!isCompleted) _buildActions(tx),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildTransactionSummaryCard(TransactionDetailModel tx) {
    final String akadNumber = tx.akadNumber?.replaceFirst(RegExp(r'^SBG-'), '') ?? tx.transactionCode;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Nomor Akad Pill (dengan tombol salin) & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: akadNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nomor Akad disalin'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'No. Akad: $akadNumber',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.copy_rounded,
                        size: 13,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
              ),
              StatusBadge.fromString(tx.status),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Nama Barang Agunan (Heading utama dalam kartu)
          Text(
            tx.collateralName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Row 3: Pinjaman Pokok & Informasi Kantor Cabang
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pinjaman Pokok',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tx.loanAmountFormatted ?? Formatters.formatCurrency(tx.loanAmount),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D), // Emerald 700
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              if (tx.branchName != null && tx.branchName!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.storefront_outlined,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        tx.branchName!,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollateralAndPhotosSection(BuildContext context, TransactionDetailModel tx) {
    return _buildSectionCard(
      title: 'Informasi & Foto Agunan',
      icon: Icons.inventory_2_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Nama Agunan', tx.collateralName, isBold: true),
          if (tx.collateralDescription != null && tx.collateralDescription!.isNotEmpty)
            _buildInfoRow('Deskripsi', tx.collateralDescription!),
          if (tx.appraisedValueFormatted != null)
            _buildInfoRow(
              'Nilai Taksir',
              tx.appraisedValueFormatted!,
              valueColor: AppColors.primary,
              isBold: true,
            ),

          // Foto Barang Agunan
          if (tx.collateralPhotos != null && tx.collateralPhotos!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Foto Barang Agunan',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: tx.collateralPhotos!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final photo = tx.collateralPhotos![index];
                  final displayUrl = photo.url.isNotEmpty ? photo.url : (photo.thumbUrl ?? '');
                  return GestureDetector(
                    onTap: () => _showFullImage(
                      context, 
                      displayUrl,
                      tx.collateralPhotos!,
                      index,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: AppNetworkImage(
                          imageUrl: displayUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholderIcon: Icons.image_outlined,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Dokumen Foto Akad (Foto Nasabah & KTP)
          if (tx.customerPhotoUrl != null || tx.idCardPhotoUrl != null) ...[
            const SizedBox(height: 14),
            const Text(
              'Dokumen Foto Akad (Nasabah & KTP)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (tx.customerPhotoUrl != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showSingleImage(context, tx.customerPhotoUrl!, 'Foto Nasabah'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Foto Nasabah',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AppNetworkImage(
                                imageUrl: tx.customerPhotoUrl,
                                height: 105,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholderIcon: Icons.person_outline_rounded,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (tx.customerPhotoUrl != null && tx.idCardPhotoUrl != null)
                  const SizedBox(width: 12),
                if (tx.idCardPhotoUrl != null)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showSingleImage(context, tx.idCardPhotoUrl!, 'Foto KTP Nasabah'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Foto KTP',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: AppNetworkImage(
                                imageUrl: tx.idCardPhotoUrl,
                                height: 105,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                placeholderIcon: Icons.badge_outlined,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionAndFinancialSection(TransactionDetailModel tx) {
    return _buildSectionCard(
      title: 'Detail Transaksi & Keuangan',
      icon: Icons.receipt_long_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Produk', tx.productName ?? '-'),
          _buildInfoRow('Kantor Cabang', tx.branchName ?? '-'),
          _buildInfoRow(
            'Tanggal Gadai',
            tx.transactionDateFormatted ?? tx.transactionDate ?? '-',
          ),
          if (tx.initialDueDateFormatted != null)
            _buildInfoRow('Jatuh Tempo Awal', tx.initialDueDateFormatted!),
          _buildInfoRow(
            'Jatuh Tempo Saat Ini',
            tx.dueDateFormatted ?? tx.dueDate ?? '-',
            valueColor: tx.isOverdue ? AppColors.error : null,
            isBold: tx.isOverdue,
          ),
          _buildInfoRow(
            'Perpanjangan',
            '${tx.extensionCount}x${tx.maxExtensions != null ? ' / Max ${tx.maxExtensions}x' : ''}',
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Pinjaman Pokok',
            tx.loanAmountFormatted ?? Formatters.formatCurrency(tx.loanAmount),
            valueColor: AppColors.primary,
            isBold: true,
          ),
          if (tx.adminFeeFormatted != null)
            _buildInfoRow('Biaya Admin', tx.adminFeeFormatted!),
          if (tx.initialFeeFormatted != null)
            _buildInfoRow('Biaya Sewa Modal / Ujroh', tx.initialFeeFormatted!),
          if (tx.cashDisbursedFormatted != null)
            _buildInfoRow(
              'Uang Diterima Nasabah',
              tx.cashDisbursedFormatted!,
              valueColor: const Color(0xFF15803D),
              isBold: true,
            ),
        ],
      ),
    );
  }

  Widget _buildBarcodeSection(TransactionDetailModel tx) {
    return _buildSectionCard(
      title: 'Barcode Stiker Barang',
      icon: Icons.qr_code_2_rounded,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: BarcodeWidget(
              barcode: Barcode.code128(),
              data: tx.barcode!,
              width: double.infinity,
              height: 70,
              drawText: false,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Text(
              tx.barcode!,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(TransactionDetailModel tx) {
    return _buildSectionCard(
      title: 'Catatan Transaksi',
      icon: Icons.notes_rounded,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          tx.notes!,
          style: const TextStyle(
            color: Color(0xFF475569),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: const Color(0xFF15803D), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildUrgentStatusBanner(TransactionDetailModel tx) {
    if (!tx.isAuctioned && !tx.isAuctionReady && !tx.isOverdue && !tx.isDueSoonH3) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color borderColor;
    Color iconColor;
    IconData icon;
    String title;
    String message;

    if (tx.isAuctioned) {
      bgColor = const Color(0xFF1E293B);
      borderColor = const Color(0xFF475569);
      iconColor = const Color(0xFFF87171);
      icon = Icons.gavel_rounded;
      title = 'STATUS: BARANG AGUNAN MASUK LELANG';
      message =
          'Masa toleransi pelunasan telah berakhir. Barang agunan #${tx.transactionCode} (${tx.collateralName}) telah diproses ke tahap lelang resmi perusahaan.';
    } else if (tx.isAuctionReady) {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFDC2626);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.error_rounded;
      title = 'PERINGATAN KRITIS: STATUS SIAP LELANG!';
      message =
          'Masa tenggang perpanjangan telah habis. Barang agunan #${tx.transactionCode} telah berstatus SIAP LELANG. Segera hubungi kantor cabang ${tx.branchName ?? ''} untuk proses penyelesaian sebelum lelang dilaksanakan.';
    } else if (tx.isOverdue) {
      bgColor = const Color(0xFFFFF1F2);
      borderColor = const Color(0xFFF43F5E);
      iconColor = const Color(0xFFE11D48);
      icon = Icons.alarm_on_rounded;
      final days = tx.daysOverdue ?? (tx.daysUntilDue != null ? tx.daysUntilDue!.abs() : 1);
      title = 'PERINGATAN: LEWAT JATUH TEMPO ($days HARI)';
      message =
          'Akad gadai telah melewati tanggal jatuh tempo (${tx.dueDateFormatted ?? tx.dueDate ?? '-'}). Batas toleransi sebelum lelang: ${tx.auctionDateFormatted ?? 'Segera'}. Segera lakukan perpanjangan atau pelunasan.';
    } else {
      // H-3 pengingat jatuh tempo
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFF59E0B);
      iconColor = const Color(0xFFD97706);
      icon = Icons.notifications_active_rounded;
      final days = tx.daysUntilDue ?? 3;
      title = 'PENGINGAT JATUH TEMPO (H-$days)';
      message =
          'Akad gadai #${tx.transactionCode} akan jatuh tempo pada ${tx.dueDateFormatted ?? tx.dueDate ?? '-'} ($days hari lagi). Silakan lakukan pelunasan atau perpanjangan tepat waktu.';
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                    color: tx.isAuctioned ? Colors.white : iconColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: tx.isAuctioned
                        ? Colors.white.withValues(alpha: 0.85)
                        : const Color(0xFF334155),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAkadCard(TransactionDetailModel tx) {
    final String akadNumber = tx.akadNumber?.replaceFirst(RegExp(r'^SBG-'), '') ?? tx.transactionCode;
    final bool isSharia = tx.isSharia == true;
    final String defaultAkadType = isSharia ? 'Akad Rahn & Akad Ijarah' : 'Perjanjian Gadai Konvensional';
    final String akadType = tx.akadType ?? defaultAkadType;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF16A34A).withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF16A34A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card Akad
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  color: Color(0xFF15803D),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Surat Bukti Gadai (SBG)',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          size: 13,
                          color: Color(0xFF16A34A),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isSharia ? 'Akad Syariah Resmi' : 'Gadai Resmi & Aman',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF15803D),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSharia
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSharia
                        ? const Color(0xFF86EFAC)
                        : const Color(0xFFBAE6FD),
                  ),
                ),
                child: Text(
                  isSharia ? 'SYARIAH' : 'KONVENSIONAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSharia
                        ? const Color(0xFF166534)
                        : const Color(0xFF0369A1),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // Detail rows akad
          _buildAkadRow(
            'Nomor Akad',
            akadNumber,
            isMonospace: true,
            trailing: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: akadNumber));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nomor Akad disalin'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.copy_rounded, size: 16, color: AppColors.primary),
              ),
            ),
          ),
          _buildAkadRow('Jenis Akad', akadType),
          _buildAkadRow(
            'Pemberi Pinjaman',
            'PT. Gadai Intira Nusantara (${tx.branchName ?? "Cabang"})',
          ),
          if (tx.customerName != null && tx.customerName!.isNotEmpty)
            _buildAkadRow(
              'Nasabah (Peminjam)',
              '${tx.customerName!}${tx.customerNik != null ? " (${tx.customerNik})" : ""}',
            ),
          _buildAkadRow('Barang Jaminan', tx.collateralName),
          _buildAkadRow(
            'Pokok Pinjaman',
            tx.loanAmountFormatted ?? Formatters.formatCurrency(tx.loanAmount),
            valueColor: AppColors.primary,
            isBold: true,
          ),
          _buildAkadRow(
            'Tanggal Akad',
            tx.transactionDateFormatted ?? tx.transactionDate ?? '-',
          ),
          _buildAkadRow(
            'Jatuh Tempo',
            tx.dueDateFormatted ?? tx.dueDate ?? '-',
            valueColor: tx.isOverdue ? AppColors.error : AppColors.textPrimary,
          ),
          if (tx.auctionDateFormatted != null)
            _buildAkadRow(
              'Toleransi Lelang s.d',
              tx.auctionDateFormatted!,
              valueColor: Colors.deepOrange.shade700,
              isBold: true,
            ),

          const SizedBox(height: 12),

          // Tombol Buka Lembar Akad Digital
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showDigitalAkadSheet(context, tx),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text(
                'Lihat Dokumen Akad Digital (SBG)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF15803D),
                side: const BorderSide(color: Color(0xFF16A34A), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAkadRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
    bool isMonospace = false,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                      color: valueColor ?? AppColors.textPrimary,
                      fontFamily: isMonospace ? 'monospace' : null,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDigitalAkadSheet(BuildContext context, TransactionDetailModel tx) {
    final String akadNumber = tx.akadNumber?.replaceFirst(RegExp(r'^SBG-'), '') ?? tx.transactionCode;
    final bool isSharia = tx.isSharia == true;
    final List<String> clauses = tx.akadClauses ?? [
      'Pemberi Gadai (Rahin) secara sah menyerahkan barang jaminan (${tx.collateralName}) kepada Penerima Gadai (Murtahin) sebagai agunan pinjaman pokok sesuai nilai taksir resmi.',
      'Penerima Gadai berhak menyimpan dan memelihara barang agunan serta mengenakan biaya sewa tempat/pemeliharaan (Ujroh) sesuai ketentuan resmi yang disepakati bersama.',
      'Pemberi Gadai berkewajiban melunasi seluruh pinjaman pokok beserta ujroh/biaya administrasi selambat-lambatnya pada tanggal jatuh tempo yang telah disepakati.',
      'Apabila pada tanggal jatuh tempo Pemberi Gadai belum dapat melunasi pinjaman pokok, Pemberi Gadai dapat mengajukan perpanjangan akad dengan melunasi kewajiban ujroh berjalan sesuai ketentuan.',
      'Apabila Pemberi Gadai tidak melunasi pinjaman dan masa toleransi lelang terlewati, Penerima Gadai berhak melakukan penjualan/lelang atas barang jaminan untuk pelunasan kewajiban pinjaman sesuai ketentuan perjanjian gadai dan peraturan perundang-undangan yang berlaku.',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Lembar Akad Digital (SBG)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable Legal Contract Document
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Legal Entity Header
                        Center(
                          child: Column(
                            children: [
                              Text(
                                isSharia
                                    ? 'SURAT BUKTI GADAI (SBG) SYARIAH'
                                    : 'SURAT BUKTI GADAI (SBG) RESMI',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: Color(0xFF14532D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'PT. GADAI INTIRA NUSANTARA',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'DOKUMEN AKAD ELEKTRONIK RESMI',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Nomor Akad: $akadNumber',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Divider(thickness: 1.5),
                        const SizedBox(height: 12),

                        // Section 1: Para Pihak
                        const Text(
                          'I. IDENTITAS PARA PIHAK',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDocRow(
                          'Pihak Pertama (Murtahin)',
                          'PT. Gadai Intira Nusantara - Cabang ${tx.branchName ?? "Utama"}',
                        ),
                        _buildDocRow(
                          'Pihak Kedua (Rahin)',
                          tx.customerName ?? 'Nasabah Terdaftar',
                        ),
                        if (tx.customerNik != null)
                          _buildDocRow('NIK Nasabah', tx.customerNik!),
                        if (tx.customerCode != null)
                          _buildDocRow('Nomor Nasabah', tx.customerCode!),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Section 2: Agunan & Fasilitas
                        const Text(
                          'II. OBJEK AGUNAN & FASILITAS PINJAMAN',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildDocRow('Barang Jaminan (Marhun)', tx.collateralName),
                        if (tx.collateralDescription != null)
                          _buildDocRow('Keterangan Agunan', tx.collateralDescription!),
                        if (tx.appraisedValueFormatted != null)
                          _buildDocRow('Nilai Taksiran', tx.appraisedValueFormatted!),
                        _buildDocRow(
                          'Uang Pinjaman (Marhun Bih)',
                          tx.loanAmountFormatted ??
                              Formatters.formatCurrency(tx.loanAmount),
                          isBold: true,
                        ),
                        if (tx.adminFeeFormatted != null)
                          _buildDocRow('Biaya Administrasi', tx.adminFeeFormatted!),
                        if (tx.initialFeeFormatted != null)
                          _buildDocRow('Biaya Sewa / Ujroh', tx.initialFeeFormatted!),
                        _buildDocRow(
                          'Tanggal Akad',
                          tx.transactionDateFormatted ?? tx.transactionDate ?? '-',
                        ),
                        _buildDocRow(
                          'Tanggal Jatuh Tempo',
                          tx.dueDateFormatted ?? tx.dueDate ?? '-',
                          isBold: true,
                        ),
                        if (tx.auctionDateFormatted != null)
                          _buildDocRow(
                            'Batas Toleransi Lelang',
                            tx.auctionDateFormatted!,
                            color: Colors.red.shade700,
                          ),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 12),

                        // Section 3: Klausul Perjanjian
                        const Text(
                          'III. KETENTUAN DAN KLAUSUL AKAD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...clauses.asMap().entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key + 1}. ',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.45,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),

                        const SizedBox(height: 16),
                        const Divider(height: 1),
                        const SizedBox(height: 16),

                        // Section 4: Pengesahan Dokumen Elektronik
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.shield_outlined,
                                    size: 16,
                                    color: Color(0xFF15803D),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'PENGESAHAN DOKUMEN ELEKTRONIK',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Dokumen ini merupakan salinan digital sah dari Surat Bukti Gadai (SBG) yang diterbitkan melalui sistem elektronik PT. Gadai Intira Nusantara dan memiliki kekuatan hukum yang mengikat Para Pihak sesuai perjanjian gadai serta regulasi UU ITE yang berlaku.',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Status: ${tx.displayStatusLabel.toUpperCase()}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF14532D),
                                    ),
                                  ),
                                  Text(
                                    tx.transactionDateFormatted ?? '',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom Sheet Actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: akadNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Nomor Akad berhasil disalin'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Salin Nomor Akad'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text('Tutup Dokumen'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                color: color ?? const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDueDateCard(TransactionDetailModel tx) {
    final bool isOverdue = tx.isOverdue;
    final int? daysUntilDue = tx.daysUntilDue;

    Color cardBg;
    Color borderColor;
    Color iconBg;
    Color iconColor;
    IconData icon;
    String statusTitle;
    String statusSubtitle;
    String badgeText;
    Color badgeBg;

    if (tx.isAuctioned) {
      cardBg = const Color(0xFFF1F5F9);
      borderColor = const Color(0xFFCBD5E1);
      iconBg = const Color(0xFFE2E8F0);
      iconColor = const Color(0xFF475569);
      icon = Icons.gavel_rounded;
      statusTitle = 'Barang Masuk Lelang';
      statusSubtitle = 'Masa toleransi lelang telah berakhir';
      badgeText = 'DILELANG';
      badgeBg = const Color(0xFF64748B);
    } else if (tx.isAuctionReady) {
      cardBg = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFCA5A5);
      iconBg = const Color(0xFFFEE2E2);
      iconColor = const Color(0xFFDC2626);
      icon = Icons.error_outline_rounded;
      statusTitle = 'Status: Siap Lelang';
      statusSubtitle = tx.auctionDateFormatted != null
          ? 'Tenggang berakhir: ${tx.auctionDateFormatted}'
          : 'Masa tenggang telah berakhir';
      badgeText = 'SIAP LELANG';
      badgeBg = const Color(0xFFDC2626);
    } else if (isOverdue) {
      cardBg = AppColors.error.withValues(alpha: 0.08);
      borderColor = AppColors.error.withValues(alpha: 0.35);
      iconBg = AppColors.error.withValues(alpha: 0.15);
      iconColor = AppColors.error;
      icon = Icons.warning_rounded;
      final days = tx.daysOverdue ?? (daysUntilDue != null ? daysUntilDue.abs() : 1);
      statusTitle = 'Lewat Jatuh Tempo ($days Hari)';
      statusSubtitle = tx.auctionDateFormatted != null
          ? 'Toleransi lelang s.d: ${tx.auctionDateFormatted}'
          : 'Jatuh tempo: ${tx.dueDateFormatted ?? tx.dueDate ?? '-'}';
      badgeText = '$days hari lewat';
      badgeBg = AppColors.error;
    } else if (daysUntilDue != null && daysUntilDue <= 3) {
      cardBg = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFCD34D);
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
      icon = Icons.notifications_active_rounded;
      statusTitle = 'Segera Jatuh Tempo';
      statusSubtitle = tx.dueDateFormatted ?? tx.dueDate ?? '-';
      badgeText = 'H-$daysUntilDue ($daysUntilDue hari lagi)';
      badgeBg = const Color(0xFFD97706);
    } else {
      cardBg = Colors.white;
      borderColor = AppColors.border;
      iconBg = AppColors.primary.withValues(alpha: 0.1);
      iconColor = AppColors.primary;
      icon = Icons.calendar_today_rounded;
      statusTitle = 'Jatuh Tempo';
      statusSubtitle = tx.dueDateFormatted ?? tx.dueDate ?? '-';
      badgeText = daysUntilDue != null ? '$daysUntilDue hari lagi' : 'Aktif';
      badgeBg = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusTitle,
                  style: TextStyle(
                    color: isOverdue || tx.isAuctionReady
                        ? AppColors.error
                        : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  statusSubtitle,
                  style: TextStyle(
                    color: isOverdue || tx.isAuctionReady
                        ? const Color(0xFF991B1B)
                        : AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
    if (tx.isAuctioned) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blueGrey.shade300),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.gavel_rounded, color: Color(0xFF475569), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Barang Agunan Telah Masuk Lelang',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Masa toleransi pelunasan telah berakhir dan agunan telah dialihkan ke proses lelang resmi. Silakan hubungi kantor cabang terkait untuk informasi lebih lanjut.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (tx.isAuctionReady) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF87171)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Status SIAP LELANG: Segera tebus atau hubungi cabang sebelum pelaksanaan lelang.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showRedeemModal(tx),
                icon: const Icon(Icons.redeem_rounded),
                label: const Text('Tebus & Ambil Barang Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
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

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (tx.canExtend) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showExtendModal(tx),
                icon: const Icon(Icons.refresh),
                label: const Text('Perpanjang Masa Gadai'),
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
              onPressed: () => _showRedeemModal(tx),
              icon: const Icon(Icons.redeem),
              label: const Text('Tebus & Ambil Barang'),
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

  void _showExtendModal(TransactionDetailModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.refresh, color: AppColors.primary, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Perpanjang Gadai',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildModalRow('Kode Kontrak', tx.transactionCode, isBold: true),
                        const SizedBox(height: 8),
                        _buildModalRow('Barang Jaminan', tx.collateralName),
                        const SizedBox(height: 8),
                        _buildModalRow('Pokok Pinjaman', Formatters.formatCurrency(tx.loanAmount)),
                        const SizedBox(height: 8),
                        _buildModalRow('Jatuh Tempo Saat Ini', tx.dueDateFormatted ?? tx.dueDate ?? '-'),
                        const SizedBox(height: 8),
                        _buildModalRow('Cabang Pengelola', tx.branch?.name ?? 'Kantor Cabang Terdaftar'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Prosedur Perpanjangan:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          '1. Perpanjangan dilakukan dengan membayar biaya sewa modal (bunga) berjalan.\n'
                          '2. Tenor pinjaman akan otomatis diperpanjang sesuai ketentuan produk.\n'
                          '3. Pembayaran dapat dilakukan via transfer bank / kasir cabang resmi Intira.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tx.transactionCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Kode transaksi ${tx.transactionCode} disalin'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Salin Nomor Transaksi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/branches');
                    },
                    icon: const Icon(Icons.store_outlined, size: 18),
                    label: const Text('Lihat Lokasi & Kontak Cabang'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRedeemModal(TransactionDetailModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.redeem, color: AppColors.success, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Tebus & Ambil Agunan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        _buildModalRow('Kode Transaksi', tx.transactionCode, isBold: true),
                        const SizedBox(height: 8),
                        _buildModalRow('Barang Ditebus', tx.collateralName),
                        const SizedBox(height: 8),
                        _buildModalRow('Pokok Pelunasan', Formatters.formatCurrency(tx.loanAmount)),
                        const SizedBox(height: 8),
                        _buildModalRow('Cabang Penyimpanan', tx.branch?.name ?? 'Kantor Cabang Terdaftar'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.checklist_rounded, color: AppColors.success, size: 18),
                            SizedBox(width: 6),
                            Text(
                              'Persyaratan Pengambilan Barang:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success),
                            ),
                          ],
                        ),
                        SizedBox(height: 6),
                        Text(
                          '1. Datang langsung ke kantor cabang penyimpanan barang di atas.\n'
                          '2. Bawa identitas KTP Asli sesuai yang terdaftar pada akun ini.\n'
                          '3. Tunjukkan layar Surat Bukti Gadai / Barcode transaksi di aplikasi ini.\n'
                          '4. Pelunasan tagihan pokok dan sewa modal dilakukan di kasir cabang.\n'
                          '5. Periksa fisik agunan sebelum menandatangani bukti serah terima.',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushNamed(context, '/branches');
                    },
                    icon: const Icon(Icons.navigation_outlined, size: 18),
                    label: const Text('Buka Lokasi Cabang & Jam Operasional'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: tx.transactionCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Kode transaksi ${tx.transactionCode} disalin'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Salin Nomor Transaksi'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModalRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
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

  void _showSingleImage(BuildContext context, String imageUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            centerTitle: true,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: AppNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholderIcon: Icons.image_outlined,
              ),
            ),
          ),
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
          final resolvedUrl = ImageUtils.resolveImageUrl(photo.url);
          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: AppNetworkImage(
                imageUrl: resolvedUrl,
                fit: BoxFit.contain,
                placeholderIcon: Icons.image_outlined,
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
