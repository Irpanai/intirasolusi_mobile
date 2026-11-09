import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/app_input_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../core/services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _biometricService = BiometricService.instance;
  
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  String _biometricTypeName = 'Sidik Jari';

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometric() async {
    final available = await _biometricService.isAvailable();
    final enabled = await _biometricService.isEnabled();
    final typeName = await _biometricService.getBiometricTypeName();

    if (mounted) {
      setState(() {
        _biometricAvailable = available;
        _biometricEnabled = enabled;
        _biometricTypeName = typeName;
      });

      // Auto-prompt biometric jika sudah diaktifkan
      if (available && enabled) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) _loginWithBiometric();
        });
      }
    }
  }

  Future<void> _loginWithBiometric() async {
    final authenticated = await _biometricService.authenticate(
      reason: 'Gunakan $_biometricTypeName untuk masuk ke GASPOL by INTIRA',
    );

    if (authenticated && mounted) {
      final credentials = await _biometricService.getCredentials();
      if (credentials != null && mounted) {
        context.read<AuthBloc>().add(AuthLogin(
              email: credentials.email,
              password: credentials.password,
            ));
      }
    }
  }

  void _showBiometricEnableDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.fingerprint_rounded, color: Color(0xFF15803D), size: 28),
            const SizedBox(width: 12),
            Text('Aktifkan $_biometricTypeName?'),
          ],
        ),
        content: Text(
          'Login lebih cepat dan praktis menggunakan $_biometricTypeName di sesi berikutnya.',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
            child: const Text('Nanti Saja', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () async {
              await _biometricService.saveCredentials(
                email: _emailController.text,
                password: _passwordController.text,
              );
              if (!mounted) return;
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$_biometricTypeName berhasil diaktifkan'),
                  backgroundColor: const Color(0xFF15803D),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pushReplacementNamed(context, '/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Aktifkan'),
          ),
        ],
      ),
    );
  }

  void _onSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(AuthLogin(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          ));
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: const [
            Icon(Icons.help_outline_rounded, color: Color(0xFF15803D), size: 24),
            SizedBox(width: 10),
            Text('Lupa Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Untuk mengatur ulang password akun Anda, silakan hubungi tim Customer Service GASPOL atau kunjungi cabang Intira terdekat dengan membawa kartu identitas (KTP).',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            if (_biometricAvailable && !_biometricEnabled) {
              _showBiometricEnableDialog();
            } else {
              Navigator.pushReplacementNamed(context, '/dashboard');
            }
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Vibrant Curved Header
              _buildHeader(context),
              
              // Overlapping Modern Form Card
              Transform.translate(
                offset: const Offset(0, -30),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildFormCard(context),
                      const SizedBox(height: 20),
                      _buildTrustFooter(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 54, bottom: 64, left: 24, right: 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF14532D), // Deep pine green
            Color(0xFF15803D), // Emerald green
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Column(
        children: [
          // Logo GASPOL by INTIRA
          Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'GASPOL',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'by INTIRA',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppInputStyles.cardDecoration(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title & Subtitle
            const Text(
              'Masuk ke Akun',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Masukkan email & password akun Anda',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Email Field
            AppInputStyles.formLabel('Email', required: true),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.validateEmail,
              decoration: AppInputStyles.inputDecoration(
                hintText: 'nama@email.com',
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF15803D),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Password Field
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppInputStyles.formLabel('Password', required: true),
                GestureDetector(
                  onTap: _showForgotPasswordDialog,
                  child: const Padding(
                    padding: EdgeInsets.only(bottom: 7),
                    child: Text(
                      'Lupa Password?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              validator: Validators.validatePassword,
              onFieldSubmitted: (_) => _onSubmit(),
              decoration: AppInputStyles.inputDecoration(
                hintText: 'Masukkan password Anda',
                prefixIcon: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF15803D),
                  size: 20,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Login Button
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                return SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Text(
                                'Masuk Sekarang',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                  ),
                );
              },
            ),

            // Biometric Option
            if (_biometricAvailable && _biometricEnabled) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _loginWithBiometric,
                icon: const Icon(Icons.fingerprint_rounded, color: Color(0xFF15803D), size: 22),
                label: Text(
                  'Masuk dengan $_biometricTypeName',
                  style: const TextStyle(
                    color: Color(0xFF15803D),
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF15803D), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Divider
            Row(
              children: const [
                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    'atau',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: Color(0xFFE2E8F0))),
              ],
            ),
            const SizedBox(height: 18),

            // Register CTA Button / Link
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDCFCE7)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Belum punya akun? ',
                    style: TextStyle(
                      color: Color(0xFF475569),
                      fontSize: 13,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/register-flow'),
                    child: const Text(
                      'Daftar Sekarang',
                      style: TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(
          Icons.verified_user_outlined,
          size: 14,
          color: Color(0xFF94A3B8),
        ),
        SizedBox(width: 6),
        Text(
          'Terpercaya & Berizin Resmi • Keamanan Terjamin',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
