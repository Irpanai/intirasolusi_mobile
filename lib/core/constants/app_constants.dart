class AppConstants {
  // App Info
  static const String appName = 'Intira Mobile';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int defaultPageSize = 10;

  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;

  // File Upload
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int maxPhotos = 5;
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png'];

  // Date Formats
  static const String dateFormat = 'dd MMMM yyyy';
  static const String dateTimeFormat = 'dd MMMM yyyy HH:mm';
  static const String timeFormat = 'HH:mm';
  static const String apiDateFormat = 'yyyy-MM-dd';

  // Regex Patterns
  static final RegExp emailRegex = RegExp(
    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
  );
  static final RegExp phoneRegex = RegExp(r'^(\+62|62|0)8[1-9][0-9]{6,9}$');
  static final RegExp nikRegex = RegExp(r'^\d{16}$');

  // Minimum Lengths
  static const int minPasswordLength = 6;
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;
}
