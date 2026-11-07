import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    // Minimum display duration: 400ms allows the splash to appear smoothly without feeling stuck
    Future.delayed(const Duration(milliseconds: 400), () {
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
    return Scaffold(
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
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF14532D), // Deep pine green
                Color(0xFF15803D), // Emerald green
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Minimalist Emblem Logo
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.account_balance_rounded,
                      size: 46,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Brand Name
                const Text(
                  'INTIRA',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    letterSpacing: 5,
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Text(
                  'Solusi Gadai Online Aman & Terpercaya',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 36),

                // Sleek Minimalist Progress Indicator
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 100,
                    height: 3,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Secure Badge Footer
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Terdaftar & Terpercaya',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
