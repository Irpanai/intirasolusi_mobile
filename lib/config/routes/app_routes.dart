import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/welcome_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/register_flow_screen.dart';
import '../../presentation/screens/main/main_nav_screen.dart';
import '../../presentation/screens/calculator/calculator_screen.dart';
import '../../presentation/screens/branch/branch_list_screen.dart';
import '../../presentation/screens/branch/branch_detail_screen.dart';
import '../../presentation/screens/pawn_request/pawn_request_create_screen.dart';
import '../../presentation/screens/pawn_request/pawn_request_detail_screen.dart';
import '../../presentation/screens/transaction/transaction_detail_screen.dart';
import '../../presentation/screens/profile/profile_edit_screen.dart';
import '../../presentation/screens/profile/profile_complete_screen.dart';
import '../../presentation/screens/profile/change_password_screen.dart';
import '../../presentation/screens/help/help_screen.dart';
import '../../presentation/screens/financial_tools/financial_tools_screen.dart';
import '../../presentation/screens/financial_tools/compounding_interest_screen.dart';
import '../../presentation/screens/financial_tools/emergency_fund_screen.dart';
import '../../presentation/screens/financial_tools/fire_calculator_screen.dart';
import '../../presentation/screens/financial_tools/real_yield_screen.dart';
import '../../presentation/screens/financial_tools/break_even_screen.dart';
import '../../presentation/screens/financial_tools/tax_estimator_screen.dart';
import '../../presentation/screens/financial_tools/early_payment_screen.dart';
import '../../presentation/screens/financial_tools/dsr_calculator_screen.dart';
import '../../presentation/screens/financial_tools/early_repayment_screen.dart';
import '../../presentation/screens/article/article_list_screen.dart';
import '../../presentation/screens/article/article_detail_screen.dart';
import '../../presentation/blocs/transaction/transaction_bloc.dart';
import '../../presentation/blocs/article/article_bloc.dart';

class AppRoutes {
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String registerFlow = '/register-flow';
  static const String completeProfile = '/complete-profile';
  static const String dashboard = '/dashboard';
  static const String calculator = '/calculator';
  static const String pawnRequests = '/pawn-requests';
  static const String pawnRequestCreate = '/pawn-requests/create';
  static const String transactions = '/transactions';
  static const String branches = '/branches';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String help = '/help';
  static const String financialTools = '/financial-tools';
  static const String compoundingInterest = '/financial-tools/compounding-interest';
  static const String emergencyFund = '/financial-tools/emergency-fund';
  static const String fireCalculator = '/financial-tools/fire-calculator';
  static const String realYield = '/financial-tools/real-yield';
  static const String breakEven = '/financial-tools/break-even';
  static const String taxEstimator = '/financial-tools/tax-estimator';
  static const String earlyPayment = '/financial-tools/early-payment';
  static const String dsrCalculator = '/financial-tools/dsr-calculator';
  static const String earlyRepayment = '/financial-tools/early-repayment';
  static const String articles = '/articles';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());

      case registerFlow:
        return MaterialPageRoute(builder: (_) => const RegisterFlowScreen());

      case completeProfile:
        // Extract phone argument if provided from registration
        final completeProfileArgs = settings.arguments as Map<String, dynamic>?;
        final phoneFromRegistration = completeProfileArgs?['phone'] as String?;
        return MaterialPageRoute(
          builder: (_) => ProfileCompleteScreen(initialPhone: phoneFromRegistration),
        );

      case dashboard:
        return MaterialPageRoute(builder: (_) => const MainNavScreen(initialIndex: 0));

      case calculator:
        return MaterialPageRoute(builder: (_) => const CalculatorScreen());

      case pawnRequests:
        return MaterialPageRoute(builder: (_) => const MainNavScreen(initialIndex: 2));

      case pawnRequestCreate:
        return MaterialPageRoute(builder: (_) => const PawnRequestCreateScreen());

      case transactions:
        return MaterialPageRoute(builder: (_) => const MainNavScreen(initialIndex: 1));

      case branches:
        return MaterialPageRoute(builder: (_) => const BranchListScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const MainNavScreen(initialIndex: 3));

      case profileEdit:
        return MaterialPageRoute(builder: (_) => const ProfileEditScreen());

      case changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());

      case help:
        return MaterialPageRoute(builder: (_) => const HelpScreen());

      case financialTools:
        return MaterialPageRoute(builder: (_) => const FinancialToolsScreen());

      case compoundingInterest:
        return MaterialPageRoute(builder: (_) => const CompoundingInterestScreen());

      case emergencyFund:
        return MaterialPageRoute(builder: (_) => const EmergencyFundScreen());

      case fireCalculator:
        return MaterialPageRoute(builder: (_) => const FireCalculatorScreen());

      case realYield:
        return MaterialPageRoute(builder: (_) => const RealYieldScreen());

      case breakEven:
        return MaterialPageRoute(builder: (_) => const BreakEvenScreen());

      case taxEstimator:
        return MaterialPageRoute(builder: (_) => const TaxEstimatorScreen());

      case earlyPayment:
        return MaterialPageRoute(builder: (_) => const EarlyPaymentScreen());

      case dsrCalculator:
        return MaterialPageRoute(builder: (_) => const DsrCalculatorScreen());

      case earlyRepayment:
        return MaterialPageRoute(builder: (_) => const EarlyRepaymentScreen());

      case articles:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => ArticleBloc()..add(ArticleLoadList()),
            child: const ArticleListScreen(),
          ),
        );

      default:
        // Handle dynamic routes
        if (settings.name?.startsWith('/articles/') == true) {
          final slug = settings.name!.replaceFirst('/articles/', '');
          return MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => ArticleBloc()..add(ArticleLoadDetail(slug: slug)),
              child: ArticleDetailScreen(slug: slug),
            ),
          );
        }

        if (settings.name?.startsWith('/transactions/') == true) {
          final code = settings.name!.replaceFirst('/transactions/', '');
          return MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => TransactionBloc(),
              child: TransactionDetailScreen(transactionCode: code),
            ),
          );
        }

        if (settings.name?.startsWith('/pawn-requests/') == true) {
          final code = settings.name!.replaceFirst('/pawn-requests/', '');
          if (code != 'create') {
            return MaterialPageRoute(
              builder: (_) => PawnRequestDetailScreen(requestCode: code),
            );
          }
        }

        if (settings.name?.startsWith('/branches/') == true) {
          final code = settings.name!.replaceFirst('/branches/', '');
          return MaterialPageRoute(
            builder: (_) => BranchDetailScreen(branchCode: code),
          );
        }

        // 404 Not Found
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Halaman Tidak Ditemukan')),
            body: const Center(
              child: Text('Halaman yang Anda cari tidak ditemukan'),
            ),
          ),
        );
    }
  }
}
