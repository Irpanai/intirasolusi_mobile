import '../../config/app_config.dart';

class ApiEndpoints {
  // Base URL
  static String get baseUrl => AppConfig.baseUrl;

  // Auth
  static const String register = '/register';
  static const String registerWithKtp = '/register-with-ktp';
  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';

  // Dashboard
  static const String dashboard = '/dashboard';

  // Profile
  static const String profile = '/profile';
  static const String changePassword = '/profile/change-password';

  // Calculator
  static const String calculatorProducts = '/calculator/products';
  static String calculatorTiers(int productId) =>
      '/calculator/products/$productId/tiers';
  static const String calculatorCalculate = '/calculator/calculate';
  static const String collateralCategories = '/calculator/collateral-categories';
  static const String productCategories = '/calculator/product-categories';

  // Branches
  static const String branches = '/branches';
  static const String branchesCities = '/branches/cities';
  static const String branchesProvinces = '/branches/provinces';
  static String branchDetail(String code) => '/branches/$code';
  static const String branchesNearby = '/branches/nearby';

  // Locations
  static const String provinces = '/locations/provinces';
  static String cities(String provinceCode) =>
      '/locations/cities/$provinceCode';
  static String districts(String cityCode) => '/locations/districts/$cityCode';
  static String villages(String districtCode) =>
      '/locations/villages/$districtCode';

  // Pawn Requests
  static const String pawnRequests = '/pawn-requests';
  static String pawnRequestDetail(String code) => '/pawn-requests/$code';
  static String pawnRequestCancel(String code) => '/pawn-requests/$code/cancel';
  static String pawnRequestPhotos(String code) => '/pawn-requests/$code/photos';

  // Articles
  static const String articles = '/articles';
  static String articleDetail(String slug) => '/articles/$slug';

  // Transactions
  static const String transactions = '/transactions';
  static String transactionDetail(String code) => '/transactions/$code';
  static String transactionHistory(String code) =>
      '/transactions/$code/history';
}
