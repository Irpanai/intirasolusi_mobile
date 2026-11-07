import 'package:flutter/material.dart';
import '../../config/theme/app_colors.dart';

enum StatusType {
  pending,
  review,
  approved,
  rejected,
  cancelled,
  converted,
  active,
  completed,
  overdue,
  extended,
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final bool isSmall;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.isSmall = false,
  });

  factory StatusBadge.fromString(String status) {
    final statusLower = status.toLowerCase();
    StatusType type;
    String label;

    switch (statusLower) {
      case 'pending':
      case 'menunggu':
        type = StatusType.pending;
        label = 'Menunggu';
        break;
      case 'under_review':
      case 'reviewing':
      case 'review':
      case 'direview':
        type = StatusType.review;
        label = 'Direview';
        break;
      case 'approved':
      case 'disetujui':
        type = StatusType.approved;
        label = 'Disetujui';
        break;
      case 'rejected':
      case 'ditolak':
        type = StatusType.rejected;
        label = 'Ditolak';
        break;
      case 'cancelled':
      case 'dibatalkan':
        type = StatusType.cancelled;
        label = 'Dibatalkan';
        break;
      case 'converted':
      case 'dikonversi':
        type = StatusType.converted;
        label = 'Dikonversi';
        break;
      case 'active':
      case 'aktif':
        type = StatusType.active;
        label = 'Aktif';
        break;
      case 'completed':
      case 'selesai':
      case 'lunas':
        type = StatusType.completed;
        label = 'Lunas';
        break;
      case 'overdue':
      case 'jatuh_tempo':
        type = StatusType.overdue;
        label = 'Jatuh Tempo';
        break;
      case 'extended':
      case 'diperpanjang':
        type = StatusType.extended;
        label = 'Diperpanjang';
        break;
      default:
        type = StatusType.pending;
        label = status;
    }

    return StatusBadge(label: label, type: type);
  }

  Color get backgroundColor {
    switch (type) {
      case StatusType.pending:
        return AppColors.statusPending.withValues(alpha: 0.1);
      case StatusType.review:
        return Colors.orange.withValues(alpha: 0.1);
      case StatusType.approved:
        return AppColors.success.withValues(alpha: 0.1);
      case StatusType.rejected:
        return AppColors.error.withValues(alpha: 0.1);
      case StatusType.cancelled:
        return Colors.grey.withValues(alpha: 0.1);
      case StatusType.converted:
        return AppColors.primary.withValues(alpha: 0.1);
      case StatusType.active:
        return AppColors.statusActive.withValues(alpha: 0.1);
      case StatusType.completed:
        return AppColors.statusCompleted.withValues(alpha: 0.1);
      case StatusType.overdue:
        return AppColors.statusOverdue.withValues(alpha: 0.1);
      case StatusType.extended:
        return AppColors.statusExtended.withValues(alpha: 0.1);
    }
  }

  Color get textColor {
    switch (type) {
      case StatusType.pending:
        return AppColors.statusPending;
      case StatusType.review:
        return Colors.orange.shade700;
      case StatusType.approved:
        return AppColors.success;
      case StatusType.rejected:
        return AppColors.error;
      case StatusType.cancelled:
        return Colors.grey;
      case StatusType.converted:
        return AppColors.primary;
      case StatusType.active:
        return AppColors.statusActive;
      case StatusType.completed:
        return AppColors.statusCompleted;
      case StatusType.overdue:
        return AppColors.statusOverdue;
      case StatusType.extended:
        return AppColors.statusExtended;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 8 : 12,
        vertical: isSmall ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: isSmall ? 10 : 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
