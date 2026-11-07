import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'config/theme/app_theme.dart';
import 'config/routes/app_routes.dart';
import 'presentation/blocs/auth/auth_bloc.dart';
import 'presentation/blocs/dashboard/dashboard_bloc.dart';
import 'presentation/blocs/transaction/transaction_bloc.dart';
import 'presentation/blocs/pawn_request/pawn_request_bloc.dart';
import 'presentation/blocs/article/article_bloc.dart';

class IntiraApp extends StatelessWidget {
  const IntiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => DashboardBloc(),
        ),
        BlocProvider<TransactionBloc>(
          create: (context) => TransactionBloc(),
        ),
        BlocProvider<PawnRequestBloc>(
          create: (context) => PawnRequestBloc(),
        ),
        BlocProvider<ArticleBloc>(
          create: (context) => ArticleBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'Intira Mobile',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        locale: const Locale('id', 'ID'),
        supportedLocales: const [
          Locale('id', 'ID'),
          Locale('en', 'US'),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
