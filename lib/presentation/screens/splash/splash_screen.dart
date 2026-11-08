import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../blocs/auth/auth_bloc.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  bool _hasNavigated = false;
  AuthState? _latestAuthState;
  Timer? _fallbackTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('SplashScreen: initState started');

    // Trigger check auth status from storage/API in background
    context.read<AuthBloc>().add(AuthCheckStatus());

    // Initialize Video Player
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/videos/splash.mp4');
      await _videoController.initialize();
      _videoController.setLooping(false);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });

        _videoController.play();
        _videoController.addListener(_videoListener);

        // Fallback timer if video stalls (duration + 1s buffer)
        final videoDuration = _videoController.value.duration;
        final timeoutDuration = videoDuration > Duration.zero 
            ? videoDuration + const Duration(milliseconds: 1000)
            : const Duration(seconds: 10);

        _fallbackTimer = Timer(timeoutDuration, () {
          if (mounted && !_hasNavigated) {
            debugPrint('SplashScreen: timeout reached, navigating');
            _onSplashFinished();
          }
        });
      }
    } catch (e) {
      debugPrint('SplashScreen: video initialization error: $e');
      if (mounted) {
        // Direct transition if video cannot play
        _fallbackTimer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted && !_hasNavigated) {
            _onSplashFinished();
          }
        });
      }
    }
  }

  void _videoListener() {
    if (!_isVideoInitialized || _hasNavigated) return;

    final pos = _videoController.value.position;
    final dur = _videoController.value.duration;

    if (dur > Duration.zero && pos >= dur) {
      debugPrint('SplashScreen: video finished playing');
      _onSplashFinished();
    }
  }

  void _onSplashFinished() {
    if (_hasNavigated || !mounted) return;

    final authState = _latestAuthState ?? context.read<AuthBloc>().state;
    _handleNavigation(authState);
  }

  void _handleNavigation(AuthState state) {
    if (_hasNavigated || !mounted) return;

    if (state is AuthAuthenticated) {
      debugPrint('SplashScreen: authenticated user found, navigate to dashboard');
      _navigate('/dashboard');
    } else {
      debugPrint('SplashScreen: unauthenticated, navigate directly to login');
      _navigate('/login');
    }
  }

  void _navigate(String routeName) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _fallbackTimer?.cancel();

    if (_isVideoInitialized) {
      _videoController.pause();
    }

    Navigator.pushReplacementNamed(context, routeName);
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    if (_isVideoInitialized) {
      _videoController.removeListener(_videoListener);
      _videoController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF14532D),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          _latestAuthState = state;
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen Video Player (Direct start, no loading bar)
            if (_isVideoInitialized)
              SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoController.value.size.width,
                    height: _videoController.value.size.height,
                    child: VideoPlayer(_videoController),
                  ),
                ),
              )
            else
              // Clean seamless background while video spins up (<100ms)
              const SizedBox.expand(),

            // Top-right Skip Button
            Positioned(
              top: 16,
              right: 16,
              child: SafeArea(
                child: GestureDetector(
                  onTap: _onSplashFinished,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Lewati',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
