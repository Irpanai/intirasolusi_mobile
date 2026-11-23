import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/theme/app_colors.dart';
import '../../../config/routes/app_routes.dart';
import '../../../data/repositories/dashboard_repository.dart';

enum NotificationCategory { all, transaction, pawnRequest, account }

enum NotificationType { danger, warning, success, info }

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationCategory category;
  final String timeAgo;
  final String? actionRoute;
  final String? actionLabel;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.category,
    required this.timeAgo,
    this.actionRoute,
    this.actionLabel,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      title: title,
      message: message,
      type: type,
      category: category,
      timeAgo: timeAgo,
      actionRoute: actionRoute,
      actionLabel: actionLabel,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationScreen extends StatefulWidget {
  final DashboardData? initialData;

  const NotificationScreen({super.key, this.initialData});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final DashboardRepository _repository = DashboardRepository();
  static const String _readKey = 'gaspol_read_notifications_v1';

  DashboardData? _dashboardData;
  bool _isLoading = false;
  Set<String> _readIds = {};
  NotificationCategory _selectedCategory = NotificationCategory.all;

  @override
  void initState() {
    super.initState();
    _dashboardData = widget.initialData;
    _initData();
  }

  Future<void> _initData() async {
    await _loadReadStatus();
    if (_dashboardData == null) {
      await _fetchDashboardData(forceRefresh: false);
    }
  }

  Future<void> _loadReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_readKey) ?? [];
      if (mounted) {
        setState(() {
          _readIds = list.toSet();
        });
      }
    } catch (_) {}
  }

  Future<void> _saveReadStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readKey, _readIds.toList());
    } catch (_) {}
  }

  Future<void> _fetchDashboardData({bool forceRefresh = false}) async {
    setState(() => _isLoading = true);
    try {
      if (!forceRefresh) {
        final cached = await _repository.getCachedDashboard();
        if (cached != null && mounted) {
          setState(() {
            _dashboardData = cached;
            _isLoading = false;
          });
        }
      }

      final fresh = await _repository.getDashboard(forceRefresh: forceRefresh);
      if (mounted) {
        setState(() {
          _dashboardData = fresh;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _markAsRead(String id) {
    if (!_readIds.contains(id)) {
      setState(() {
        _readIds.add(id);
      });
      _saveReadStatus();
    }
  }

  void _markAllAsRead() {
    final allItems = _generateNotifications();
    setState(() {
      for (final item in allItems) {
        _readIds.add(item.id);
      }
    });
    _saveReadStatus();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi telah ditandai sebagai dibaca'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<NotificationItem> _generateNotifications() {
    final List<NotificationItem> items = [];
    final data = _dashboardData;

    if (data != null) {
      // 1. Overdue transactions alert
      if (data.stats.overdueTransactions > 0) {
        items.add(
          NotificationItem(
            id: 'overdue_transactions',
            title: 'Peringatan Jatuh Tempo',
            message:
                'Anda memiliki ${data.stats.overdueTransactions} transaksi yang telah lewat jatuh tempo. Harap segera lakukan pelunasan atau perpanjangan agunan Anda.',
            type: NotificationType.danger,
            category: NotificationCategory.transaction,
            timeAgo: 'Segera',
            actionRoute: AppRoutes.transactions,
            actionLabel: 'Lihat Transaksi',
            isRead: _readIds.contains('overdue_transactions'),
          ),
        );
      }

      // 2. Profile completion notice
      if (!data.customer.isProfileComplete) {
        items.add(
          NotificationItem(
            id: 'profile_incomplete',
            title: 'Profil Belum Lengkap',
            message:
                'Lengkapi data profil dan identitas KTP Anda untuk kemudahan serta verifikasi pengajuan gadai online.',
            type: NotificationType.warning,
            category: NotificationCategory.account,
            timeAgo: 'Penting',
            actionRoute: AppRoutes.completeProfile,
            actionLabel: 'Lengkapi Sekarang',
            isRead: _readIds.contains('profile_incomplete'),
          ),
        );
      }

      // 3. Backend alerts
      final Set<String> processedTxAlertCodes = {};

      for (int i = 0; i < data.alerts.length; i++) {
        final alert = data.alerts[i];
        final alertId = alert.id ?? 'backend_alert_${alert.type}_$i';

        NotificationType type = NotificationType.info;
        NotificationCategory cat = NotificationCategory.account;

        if (alert.type == 'danger' || alert.type == 'error') {
          type = NotificationType.danger;
          cat = NotificationCategory.transaction;
        } else if (alert.type == 'warning') {
          type = NotificationType.warning;
          cat = NotificationCategory.transaction;
        } else if (alert.type == 'success') {
          type = NotificationType.success;
          cat = NotificationCategory.pawnRequest;
        }

        String? route;
        String? label;
        if (alert.action == 'complete_profile' || alert.actionUrl == '/complete-profile') {
          route = AppRoutes.completeProfile;
          label = 'Lengkapi Profil';
          cat = NotificationCategory.account;
        } else if (alert.action == 'view_transactions' || alert.actionUrl == '/transactions') {
          route = AppRoutes.transactions;
          label = 'Lihat Transaksi';
          cat = NotificationCategory.transaction;
        } else if (alert.action == 'view_requests' || alert.actionUrl == '/pawn-requests') {
          route = AppRoutes.pawnRequests;
          label = 'Lihat Pengajuan';
          cat = NotificationCategory.pawnRequest;
        } else if (alert.action == 'view_transaction' ||
            (alert.actionUrl != null && alert.actionUrl!.startsWith('/transactions/'))) {
          route = alert.actionUrl;
          label = 'Lihat Akad & Transaksi';
          cat = NotificationCategory.transaction;

          final txCode = alert.actionUrl!.replaceFirst('/transactions/', '');
          if (txCode.isNotEmpty) {
            processedTxAlertCodes.add(txCode);
          }
        }

        String timeLabel = 'Hari ini';
        if (alertId.startsWith('h3_')) {
          timeLabel = 'Pengingat';
        } else if (alertId.startsWith('overdue_')) {
          timeLabel = 'Jatuh Tempo';
        } else if (alertId.startsWith('auction_ready_')) {
          timeLabel = 'Kritis';
        } else if (alertId.startsWith('auctioned_')) {
          timeLabel = 'Lelang';
        }

        items.add(
          NotificationItem(
            id: alertId,
            title: alert.title ?? _defaultTitleForType(alert.type),
            message: alert.message,
            type: type,
            category: cat,
            timeAgo: timeLabel,
            actionRoute: route,
            actionLabel: label,
            isRead: _readIds.contains(alertId),
          ),
        );
      }

      // 4. Recent Pawn Requests updates
      for (final req in data.recentRequests) {
        final reqId = 'pawn_request_${req.code}';
        final collateral = req.collateralName.isNotEmpty ? req.collateralName : 'barang agunan';
        if (req.status == 'approved') {
          items.add(
            NotificationItem(
              id: reqId,
              title: 'Pengajuan Gadai Disetujui',
              message:
                  'Pengajuan gadai #$reqId ($collateral) telah disetujui. Silakan kunjungi cabang terdekat untuk proses verifikasi fisik dan pencairan dana.',
              type: NotificationType.success,
              category: NotificationCategory.pawnRequest,
              timeAgo: 'Terbaru',
              actionRoute: '/pawn-requests/${req.code}',
              actionLabel: 'Detail Pengajuan',
              isRead: _readIds.contains(reqId),
            ),
          );
        } else if (req.status == 'pending') {
          items.add(
            NotificationItem(
              id: reqId,
              title: 'Pengajuan Sedang Diverifikasi',
              message:
                  'Pengajuan gadai #${req.code} ($collateral) sedang ditinjau oleh analis penaksir kami.',
              type: NotificationType.info,
              category: NotificationCategory.pawnRequest,
              timeAgo: 'Dalam Proses',
              actionRoute: '/pawn-requests/${req.code}',
              actionLabel: 'Cek Status',
              isRead: _readIds.contains(reqId),
            ),
          );
        }
      }

      // 5. Active Transactions updates
      for (final tx in data.activeTransactions) {
        final collateral = tx.collateralName.isNotEmpty ? tx.collateralName : 'barang agunan';

        if (tx.isAuctioned && !processedTxAlertCodes.contains(tx.code)) {
          final txId = 'tx_auctioned_${tx.code}';
          items.add(
            NotificationItem(
              id: txId,
              title: 'Barang Agunan Masuk Lelang: #${tx.code}',
              message:
                  'Barang agunan $collateral (#${tx.code}) telah dialihkan ke proses lelang resmi karena melewati batas toleransi.',
              type: NotificationType.info,
              category: NotificationCategory.transaction,
              timeAgo: 'Lelang',
              actionRoute: '/transactions/${tx.code}',
              actionLabel: 'Lihat Akad & Transaksi',
              isRead: _readIds.contains(txId),
            ),
          );
        } else if (tx.isAuctionReady && !processedTxAlertCodes.contains(tx.code)) {
          final txId = 'tx_auction_ready_${tx.code}';
          items.add(
            NotificationItem(
              id: txId,
              title: '⛔ PERINGATAN: Barang Siap Lelang: #${tx.code}',
              message:
                  'Masa perpanjangan agunan $collateral (#${tx.code}) telah habis. Segera lakukan pelunasan di cabang sebelum pelaksanaan lelang!',
              type: NotificationType.danger,
              category: NotificationCategory.transaction,
              timeAgo: 'Kritis',
              actionRoute: '/transactions/${tx.code}',
              actionLabel: 'Tebus Sekarang',
              isRead: _readIds.contains(txId),
            ),
          );
        } else if (tx.isOverdue && !processedTxAlertCodes.contains(tx.code)) {
          final txId = 'tx_overdue_${tx.code}';
          final days = tx.daysOverdue ?? (tx.daysUntilDue != null ? tx.daysUntilDue!.abs() : 1);
          items.add(
            NotificationItem(
              id: txId,
              title: '⚠️ Agunan Lewat Jatuh Tempo ($days Hari): #${tx.code}',
              message:
                  'Transaksi $collateral telah jatuh tempo pada ${tx.dueDate ?? "tanggal jatuh tempo"}. Batas toleransi lelang: ${tx.auctionDate ?? "segera"}. Segera lunasi atau perpanjang.',
              type: NotificationType.danger,
              category: NotificationCategory.transaction,
              timeAgo: 'Jatuh Tempo',
              actionRoute: '/transactions/${tx.code}',
              actionLabel: 'Tebus / Perpanjang',
              isRead: _readIds.contains(txId),
            ),
          );
        } else if (tx.isDueSoonH3 && !processedTxAlertCodes.contains(tx.code)) {
          final txId = 'tx_h3_${tx.code}';
          final days = tx.daysUntilDue ?? 3;
          items.add(
            NotificationItem(
              id: txId,
              title: '🔔 Pengingat Jatuh Tempo (H-$days): #${tx.code}',
              message:
                  'Akad gadai $collateral (#${tx.code}) akan jatuh tempo dalam $days hari (${tx.dueDate ?? "-"}). Harap siapkan dana atau lakukan perpanjangan.',
              type: NotificationType.warning,
              category: NotificationCategory.transaction,
              timeAgo: 'H-$days',
              actionRoute: '/transactions/${tx.code}',
              actionLabel: 'Lihat Akad',
              isRead: _readIds.contains(txId),
            ),
          );
        }
      }
    }

    // 6. Welcome & System info notification (always present)
    items.add(
      NotificationItem(
        id: 'system_welcome',
        title: 'Selamat Datang di GASPOL by INTIRA',
        message:
            'Aplikasi gadai online resmi & terpercaya. Seluruh transaksi gadai aman, berizin dan diawasi oleh Otoritas Jasa Keuangan (OJK).',
        type: NotificationType.info,
        category: NotificationCategory.account,
        timeAgo: 'Informasi',
        actionRoute: AppRoutes.help,
        actionLabel: 'Pusat Bantuan',
        isRead: _readIds.contains('system_welcome'),
      ),
    );

    return items;
  }

  String _defaultTitleForType(String type) {
    switch (type) {
      case 'danger':
      case 'error':
        return 'Peringatan Penting';
      case 'warning':
        return 'Pemberitahuan Akun';
      case 'success':
        return 'Kabar Baik!';
      default:
        return 'Info GASPOL';
    }
  }

  List<NotificationItem> _getFilteredNotifications() {
    final all = _generateNotifications();
    if (_selectedCategory == NotificationCategory.all) {
      return all;
    }
    return all.where((item) => item.category == _selectedCategory).toList();
  }

  int get _unreadCount {
    return _generateNotifications().where((n) => !n.isRead).length;
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _getFilteredNotifications();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(context),
          _buildCategoryTabs(),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => _fetchDashboardData(forceRefresh: true),
              child: _isLoading && _dashboardData == null
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : notifications.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          itemCount: notifications.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            return _buildNotificationCard(
                                context, notifications[index]);
                          },
                        ),
            ),
          ),
        ],
      ),
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
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top actions: Back & Mark all read
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_ios_new,
                              size: 13, color: Colors.white),
                          SizedBox(width: 6),
                          Text(
                            'Kembali',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_unreadCount > 0)
                    GestureDetector(
                      onTap: _markAllAsRead,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.done_all_rounded,
                                size: 14, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Tandai Dibaca',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              // Title & Counter
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Notifikasi',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_unreadCount Baru',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Pemberitahuan aktivitas, jatuh tempo, & pengajuan Anda',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'cat': NotificationCategory.all, 'label': 'Semua'},
      {'cat': NotificationCategory.transaction, 'label': 'Transaksi'},
      {'cat': NotificationCategory.pawnRequest, 'label': 'Pengajuan'},
      {'cat': NotificationCategory.account, 'label': 'Akun & Info'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((c) {
            final cat = c['cat'] as NotificationCategory;
            final label = c['label'] as String;
            final isSelected = _selectedCategory == cat;

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade200,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationItem notif) {
    Color iconColor;
    Color iconBg;
    IconData icon;
    String badgeText;

    final String titleUpper = notif.title.toUpperCase();
    final String idLower = notif.id.toLowerCase();

    if (idLower.startsWith('auction_ready') ||
        titleUpper.contains('SIAP LELANG') ||
        titleUpper.contains('SIAP DILELANG')) {
      iconColor = const Color(0xFFDC2626);
      iconBg = const Color(0xFFFEE2E2);
      icon = Icons.error_rounded;
      badgeText = 'SIAP LELANG';
    } else if (idLower.startsWith('auctioned') ||
        titleUpper.contains('LELANG') ||
        titleUpper.contains('DILELANG')) {
      iconColor = const Color(0xFF475569);
      iconBg = const Color(0xFFF1F5F9);
      icon = Icons.gavel_rounded;
      badgeText = 'LELANG';
    } else if (idLower.startsWith('h3') ||
        titleUpper.contains('H-3') ||
        titleUpper.contains('H-2') ||
        titleUpper.contains('H-1')) {
      iconColor = const Color(0xFFD97706);
      iconBg = const Color(0xFFFEF3C7);
      icon = Icons.notifications_active_rounded;
      badgeText = 'PENGINGAT H-3';
    } else {
      switch (notif.type) {
        case NotificationType.danger:
          iconColor = const Color(0xFFEF4444);
          iconBg = const Color(0xFFFEE2E2);
          icon = Icons.warning_rounded;
          badgeText = 'JATUH TEMPO';
          break;
        case NotificationType.warning:
          iconColor = const Color(0xFFF59E0B);
          iconBg = const Color(0xFFFEF3C7);
          icon = Icons.info_rounded;
          badgeText = 'PENTING';
          break;
        case NotificationType.success:
          iconColor = const Color(0xFF10B981);
          iconBg = const Color(0xFFD1FAE5);
          icon = Icons.check_circle_rounded;
          badgeText = 'DISETUJUI';
          break;
        case NotificationType.info:
          iconColor = const Color(0xFF0284C7);
          iconBg = const Color(0xFFE0F2FE);
          icon = Icons.notifications_rounded;
          badgeText = 'INFO';
          break;
      }
    }

    return GestureDetector(
      onTap: () {
        _markAsRead(notif.id);
        _showDetailBottomSheet(context, notif, icon, iconColor, iconBg, badgeText);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white : const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notif.isRead
                ? Colors.grey.shade200
                : AppColors.primary.withValues(alpha: 0.35),
            width: notif.isRead ? 1 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: TextStyle(
                            color: iconColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            notif.timeAgo,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!notif.isRead) ...[
                            const SizedBox(width: 6),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notif.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          notif.isRead ? FontWeight.w600 : FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: notif.isRead
                          ? AppColors.textSecondary
                          : const Color(0xFF334155),
                      height: 1.4,
                    ),
                  ),
                  if (notif.actionLabel != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          notif.actionLabel!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailBottomSheet(
    BuildContext context,
    NotificationItem notif,
    IconData icon,
    Color iconColor,
    Color iconBg,
    String badgeText,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: iconColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notif.timeAgo,
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 22),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  notif.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  notif.message,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                if (notif.actionRoute != null && notif.actionLabel != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pushNamed(context, notif.actionRoute!);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            notif.actionLabel!,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak Ada Notifikasi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _selectedCategory == NotificationCategory.all
                  ? 'Semua transaksi dan pengajuan Anda dalam kondisi baik. Pemberitahuan penting akan ditampilkan di sini.'
                  : 'Tidak ada notifikasi dalam kategori ini.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => _fetchDashboardData(forceRefresh: true),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Muat Ulang'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
