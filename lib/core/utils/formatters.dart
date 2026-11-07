import 'package:intl/intl.dart';

class Formatters {
  // Currency formatter for Indonesian Rupiah
  static String formatCurrency(double amount, {bool showSymbol = true}) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: showSymbol ? 'Rp ' : '',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Date formatter
  static String formatDate(DateTime date, {String format = 'dd MMMM yyyy'}) {
    return DateFormat(format, 'id_ID').format(date);
  }

  // DateTime formatter
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMMM yyyy HH:mm', 'id_ID').format(dateTime);
  }

  // Phone formatter
  static String formatPhone(String phone) {
    if (phone.startsWith('0')) {
      phone = '+62${phone.substring(1)}';
    } else if (phone.startsWith('62')) {
      phone = '+$phone';
    }
    return phone;
  }

  // Capitalize first letter
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  // Parse date from API
  static DateTime? parseDate(String? dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  // Relative time (e.g., "2 jam yang lalu")
  static String relativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 30) {
      return formatDate(dateTime);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} menit yang lalu';
    } else {
      return 'Baru saja';
    }
  }

  // Format number with thousand separators
  static String formatNumber(num amount) {
    // buat formatter dengan locale Indonesia dan tanpa simbol mata uang
    final formatter = NumberFormat('#,###', 'id_ID');
    return formatter.format(amount);
  }

  // Parse number from formatted string
  static double parseNumber(String formattedNumber) {
    final cleaned = formattedNumber.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleaned) ?? 0;
  }
}
