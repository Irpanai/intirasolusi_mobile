import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../blocs/auth/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _minTimeElapsed = false;
  bool _hasNavigated = false;
  AuthState? _pendingState;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen: initState called');

    // Trigger check auth status from storage/API
    context.read<AuthBloc>().add(AuthCheckStatus());

    // Minimum display duration for branding (1.8 seconds)
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _minTimeElapsed = true);
        if (_pendingState != null) {
          _handleNavigation(_pendingState!);
        }
      }
    });

    // Fallback timer: if network hangs or no response within 5 seconds, navigate to welcome
    _fallbackTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_hasNavigated) {
        debugPrint('SplashScreen: timeout reached, fallback to welcome');
        _navigate('/welcome');
      }
    });
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  void _handleNavigation(AuthState state) {
    if (_hasNavigated || !mounted) return;

    if (state is AuthAuthenticated) {
      debugPrint('SplashScreen: authenticated user found, navigating to dashboard');
      _navigate('/dashboard');
    } else if (state is AuthUnauthenticated || state is AuthError) {
      debugPrint('SplashScreen: unauthenticated, navigating to welcome');
      _navigate('/welcome');
    }
  }

  void _navigate(String routeName) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();
    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('SplashScreen: build called');
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated ||
              state is AuthUnauthenticated ||
              state is AuthError) {
            if (_minTimeElapsed) {
              _handleNavigation(state);
            } else {
              _pendingState = state;
            }
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo placeholder
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.account_balance,
                  size: 64,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'INTIRA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gadai Online Terpercaya',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
