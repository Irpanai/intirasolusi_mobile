import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/ktp_ocr_service.dart';
import '../../../core/widgets/app_input_styles.dart';
import '../../../core/utils/validators.dart';
import '../../blocs/auth/auth_bloc.dart';
import 'widgets/selfie_capture_widget.dart';

class RegisterFlowScreen extends StatefulWidget {
  const RegisterFlowScreen({super.key});

  @override
  State<RegisterFlowScreen> createState() => _RegisterFlowScreenState();
}

class _RegisterFlowScreenState extends State<RegisterFlowScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();
  final KtpOcrService _ocrService = KtpOcrService();
  final ImagePicker _picker = ImagePicker();

  // ─── Step 1: Akun ──────────────────────────────────────────────────────────
  final _step1FormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // ─── Step 2: Foto KTP ──────────────────────────────────────────────────────
  File? _ktpImage;
  bool _isProcessingOcr = false;
  KtpData? _ktpData;

  // ─── Step 3: Foto Selfie ───────────────────────────────────────────────────
  File? _selfieImage;

  // ─── Step 4: Konfirmasi (NIK, Nama, Tgl Lahir saja) ───────────────────────
  final _step3FormKey = GlobalKey<FormState>();
  final _nikController = TextEditingController();
  final _namaController = TextEditingController();
  final _tglLahirController = TextEditingController();
  bool _agreeTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nikController.dispose();
    _namaController.dispose();
    _tglLahirController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  // ── Navigasi antar step ────────────────────────────────────────────────────
  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
    } else {
      Navigator.pop(context);
    }
  }

  // ── Step 1 → Step 2 ───────────────────────────────────────────────────────
  void _validateAndNext() {
    if (_step1FormKey.currentState?.validate() ?? false) {
      _goToStep(1);
    }
  }

  // ── Ambil foto KTP + OCR inline ───────────────────────────────────────────
  Future<void> _pickAndProcessKtp(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 100,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (picked == null) return;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop KTP — potong rapat ke tepi kartu',
          toolbarColor: AppColors.primary,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop KTP'),
      ],
    );
    if (cropped == null) return;

    setState(() {
      _ktpImage = File(cropped.path);
      _isProcessingOcr = true;
      _ktpData = null;
    });

    try {
      final data = await _ocrService.processKtpImage(_ktpImage!);
      setState(() {
        _ktpData = data;
        _isProcessingOcr = false;
        // Pre-fill Step 3 controllers dengan hasil OCR
        _nikController.text = data.nik ?? '';
        _namaController.text = data.nama ?? '';
        _tglLahirController.text = data.tanggalLahir ?? '';
      });
      if (mounted) {
        final hasData = data.nik != null || data.nama != null;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(hasData
              ? 'Data KTP berhasil terdeteksi'
              : 'Tidak dapat membaca data. Periksa ulang foto KTP.'),
          backgroundColor: hasData ? AppColors.success : AppColors.warning,
        ));
      }
    } catch (e) {
      setState(() => _isProcessingOcr = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal membaca KTP. Coba foto ulang.'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  // ── Step 2 → Step 3 (Selfie) ──────────────────────────────────────────────
  void _goToSelfie() {
    if (_ktpImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Harap ambil foto KTP terlebih dahulu'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    _goToStep(2);
  }

  // ── Step 3 → Step 4 (Konfirmasi) ──────────────────────────────────────────
  void _goToKonfirmasi() {
    if (_selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Harap ambil foto selfie terlebih dahulu'),
        backgroundColor: AppColors.error,
      ));
      return;
    }
    _goToStep(3);
  }

  // ── Buka Kamera Selfie Fullscreen ──────────────────────────────────────────
  void _openSelfieCamera() {
    Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: const Text('Foto Selfie'),
            backgroundColor: const Color(0xFF14532D),
            foregroundColor: Colors.white,
          ),
          body: SelfieCaptureWidget(
            existingImage: _selfieImage,
            onSelfieCaptured: (file) {
              setState(() => _selfieImage = file);
              Navigator.pop(ctx, file);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickSelfieFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _selfieImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto dari galeri: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  void _submit() {
    if (!(_step3FormKey.currentState?.validate() ?? false)) return;
    if (_selfieImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Harap ambil foto selfie terlebih dahulu'),
        backgroundColor: AppColors.error,
      ));
      _goToStep(2);
      return;
    }
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Harap setujui syarat dan ketentuan'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    context.read<AuthBloc>().add(AuthRegisterWithKtp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          phone: _phoneController.text.trim(),
          ktpImage: _ktpImage!,
          selfieImage: _selfieImage!,
          nik: _nikController.text.trim(),
          name: _namaController.text.trim(),
          birthDate: _tglLahirController.text.trim(),
          // Sisa field dari OCR (lebih lengkap)
          birthPlace: _ktpData?.tempatLahir,
          gender: _ktpData?.gender ?? 'male',
          address: _ktpData?.alamat ?? '',
          rtRw: _ktpData?.rtRw,
          village: _ktpData?.kelurahan,
          district: _ktpData?.kecamatan,
          city: _ktpData?.kabupatenKota,
          province: _ktpData?.provinsi,
          religion: _ktpData?.agama,
          maritalStatus: _ktpData?.statusPerkawinan,
          occupation: _ktpData?.pekerjaan,
        ));
  }

  // ─────────────────────────────────────────────────────────────────── Build ─
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ));
          }
        },
        child: Column(
          children: [
            _buildHeader(),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStepSelfie(),
                  _buildStep3(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────── Header ────
  Widget _buildHeader() {
    const titles = ['Buat Akun', 'Foto KTP', 'Foto Selfie', 'Konfirmasi Data'];
    const subtitles = [
      'Lengkapi data dasar akun Anda',
      'Pindai e-KTP untuk identifikasi',
      'Ambil foto selfie untuk verifikasi',
      'Periksa kembali kelengkapan data',
    ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF14532D), // Pine green
            Color(0xFF15803D), // Emerald green
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _previousStep,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _currentStep == 0 ? 'Kembali' : 'Sebelumnya',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Langkah ${_currentStep + 1} dari 4',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                titles[_currentStep],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitles[_currentStep],
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────── Step Indicator ───
  Widget _buildStepIndicator() {
    const labels = ['Akun', 'KTP', 'Selfie', 'Konfirmasi'];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(4, (i) {
          final isCurrent = i == _currentStep;
          final isDone = i < _currentStep;

          return Expanded(
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone || isCurrent
                        ? const Color(0xFF15803D)
                        : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone || isCurrent
                          ? const Color(0xFF15803D)
                          : const Color(0xFFCBD5E1),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: isCurrent ? Colors.white : const Color(0xFF64748B),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrent || isDone
                          ? const Color(0xFF15803D)
                          : const Color(0xFF64748B),
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (i < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: isDone
                          ? const Color(0xFF15803D)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ════════════════════════════════════════════════════ STEP 1: Akun ══════════
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: AppInputStyles.cardDecoration(),
        child: Form(
          key: _step1FormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Data Akun Pengguna',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Masukkan email, nomor telepon, dan password untuk membuat akun baru.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 20),
              _field(
                controller: _emailController,
                label: 'Email',
                hint: 'nama@email.com',
                icon: Icons.email_outlined,
                keyboard: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: 16),
              _field(
                controller: _phoneController,
                label: 'No. Handphone',
                hint: '08xxxxxxxxxx',
                icon: Icons.phone_outlined,
                keyboard: TextInputType.phone,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'No. HP wajib diisi';
                  if (v.length < 10) return 'No. HP tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _field(
                controller: _passwordController,
                label: 'Password',
                hint: 'Minimal 8 karakter',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: 16),
              _field(
                controller: _confirmPasswordController,
                label: 'Konfirmasi Password',
                hint: 'Ulangi password di atas',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureConfirmPassword,
                suffix: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                  onPressed: () => setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: (v) {
                  if (v != _passwordController.text) return 'Password tidak cocok';
                  return null;
                },
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _validateAndNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'Lanjutkan',
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
              ),
              const SizedBox(height: 18),
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
                      'Sudah punya akun? ',
                      style: TextStyle(color: Color(0xFF475569), fontSize: 13),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text(
                        'Masuk',
                        style: TextStyle(
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════ STEP 2: Foto KTP ══════════
  Widget _buildStep2() {
    final hasPhoto = _ktpImage != null;
    final hasData = _ktpData != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: AppInputStyles.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Foto Kartu e-KTP',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ambil foto KTP Anda. Pastikan seluruh teks terlihat jelas agar data dapat terbaca otomatis.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),

            // ── Preview KTP ────────────────────────────────────────────────────
            GestureDetector(
              onTap: hasPhoto && !_isProcessingOcr
                  ? () => _showSourcePicker()
                  : null,
              child: Container(
                height: 195,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasPhoto ? const Color(0xFF15803D) : const Color(0xFFCBD5E1),
                    width: hasPhoto ? 2 : 1.2,
                  ),
                ),
                child: hasPhoto
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.file(_ktpImage!,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover),
                          ),
                          if (_isProcessingOcr)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                    SizedBox(height: 12),
                                    Text('Membaca data KTP...',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600)),
                                    SizedBox(height: 3),
                                    Text('Dual-pass OCR sedang berlangsung',
                                        style: TextStyle(
                                            color: Colors.white70, fontSize: 11)),
                                  ],
                                ),
                              ),
                            ),
                          if (!_isProcessingOcr)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _ktpImage = null;
                                  _ktpData = null;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close_rounded,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFDCFCE7)),
                            ),
                            child: const Icon(Icons.credit_card_rounded,
                                size: 36, color: Color(0xFF15803D)),
                          ),
                          const SizedBox(height: 10),
                          const Text('Belum ada foto KTP',
                              style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          const SizedBox(height: 2),
                          const Text('Gunakan e-KTP fisik asli yang masih berlaku',
                              style: TextStyle(
                                  color: Color(0xFF64748B), fontSize: 11.5)),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Tombol ambil foto ──────────────────────────────────────────────
            if (!hasPhoto || !_isProcessingOcr)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.camera_alt_outlined, size: 18),
                      label: Text(hasPhoto ? 'Foto Ulang' : 'Kamera'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF15803D), width: 1.2),
                        foregroundColor: const Color(0xFF15803D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _pickAndProcessKtp(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined, size: 18),
                      label: Text(hasPhoto ? 'Ganti Galeri' : 'Galeri'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF15803D), width: 1.2),
                        foregroundColor: const Color(0xFF15803D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _pickAndProcessKtp(ImageSource.gallery),
                    ),
                  ),
                ],
              ),

            // ── Hasil deteksi (ringkasan) ──────────────────────────────────────
            if (hasData && !_isProcessingOcr) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.check_circle_rounded,
                            color: Color(0xFF15803D), size: 18),
                        SizedBox(width: 6),
                        Text('Data KTP Terbaca:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF14532D))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _previewRow('NIK', _ktpData!.nik),
                    _previewRow('Nama', _ktpData!.nama),
                    _previewRow('Tgl Lahir', _ktpData!.tanggalLahir),
                    const SizedBox(height: 8),
                    const Text(
                      '✏️ Data dapat diperiksa & diedit di langkah konfirmasi.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // ── Tips ───────────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 6),
                      Text('Panduan Foto KTP:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _tip('Crop rapat ke 4 sisi kartu KTP fisik'),
                  _tip('Hindari pantulan cahaya atau bayangan gelap'),
                  _tip('Pastikan seluruh teks NIK & Nama terbaca tajam'),
                ],
              ),
            ),

            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_ktpImage != null && !_isProcessingOcr)
                    ? _goToSelfie
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  disabledBackgroundColor: const Color(0xFFE2E8F0),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Lanjut ke Foto Selfie',
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
            ),
          ],
        ),
      ),
    );
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined, color: Color(0xFF15803D)),
            title: const Text('Ambil Foto Kamera'),
            onTap: () {
              Navigator.pop(context);
              _pickAndProcessKtp(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined, color: Color(0xFF15803D)),
            title: const Text('Pilih dari Galeri'),
            onTap: () {
              Navigator.pop(context);
              _pickAndProcessKtp(ImageSource.gallery);
            },
          ),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════ STEP 3: Foto Selfie ════════
  Widget _buildStepSelfie() {
    final hasSelfie = _selfieImage != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: AppInputStyles.cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Foto Selfie Wajah',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ambil foto selfie wajah Anda untuk verifikasi identitas (KYC) dan keamanan akun.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),

            // ── Preview Selfie ──────────────────────────────────────────────────
            Center(
              child: Container(
                width: 190,
                height: 230,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: hasSelfie ? const Color(0xFF15803D) : const Color(0xFFCBD5E1),
                    width: hasSelfie ? 2.5 : 1.2,
                  ),
                ),
                child: hasSelfie
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.file(
                              _selfieImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _selfieImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded,
                                    color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 10,
                            left: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: Color(0xFF22C55E), size: 15),
                                  SizedBox(width: 5),
                                  Text(
                                    'Wajah Terverifikasi',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFDCFCE7)),
                            ),
                            child: const Icon(
                              Icons.face_rounded,
                              size: 42,
                              color: Color(0xFF15803D),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Belum ada foto selfie',
                            style: TextStyle(
                                color: Color(0xFF1E293B),
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Arahkan wajah ke kamera',
                            style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11.5),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 22),

            // ── Tombol Aksi Selfie ─────────────────────────────────────────────
            if (!hasSelfie) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.camera_front_rounded, size: 20),
                  label: const Text(
                    'Buka Kamera Selfie',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF15803D),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _openSelfieCamera,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Pilih dari Galeri'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF15803D), width: 1.2),
                    foregroundColor: const Color(0xFF15803D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _pickSelfieFromGallery,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Foto Ulang'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Color(0xFF15803D), width: 1.2),
                        foregroundColor: const Color(0xFF15803D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _openSelfieCamera,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _goToKonfirmasi,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text('Lanjutkan',
                                style: TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 14)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),

            // ── Tips Selfie ───────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lightbulb_outline_rounded,
                          color: Color(0xFFD97706), size: 18),
                      SizedBox(width: 6),
                      Text('Panduan Foto Selfie:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: Color(0xFF1E293B))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _tip('Posisikan wajah tepat di tengah bingkai'),
                  _tip('Pastikan pencahayaan cukup dan wajah terang'),
                  _tip('Lepaskan masker, kacamata hitam, atau penutup wajah'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════ STEP 4: Konfirmasi ══════════
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: AppInputStyles.cardDecoration(),
        child: Form(
          key: _step3FormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Konfirmasi Data Diri',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Periksa hasil pembacaan KTP. Anda dapat mengoreksi data jika belum tepat.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),

              // Thumbnail Dokumen KTP & Selfie
              Row(
                children: [
                  if (_ktpImage != null)
                    Expanded(
                      child: Container(
                        height: 85,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            children: [
                              Image.file(_ktpImage!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          color: Color(0xFF22C55E), size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'KTP Terlampir',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  if (_selfieImage != null)
                    Expanded(
                      child: Container(
                        height: 85,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Stack(
                            children: [
                              Image.file(_selfieImage!,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded,
                                          color: Color(0xFF22C55E), size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Selfie Terlampir',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Tombol kembali ke foto jika data salah
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _goToStep(1),
                    icon: const Icon(Icons.credit_card_rounded, size: 15),
                    label: const Text('Ulang KTP', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF15803D),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                  const Text('•', style: TextStyle(color: Color(0xFFCBD5E1))),
                  TextButton.icon(
                    onPressed: () => _goToStep(2),
                    icon: const Icon(Icons.face_rounded, size: 15),
                    label: const Text('Ulang Selfie', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF15803D),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // NIK
              _confirmField(
                controller: _nikController,
                label: 'NIK (Nomor Induk Kependudukan)',
                hint: '16 digit NIK',
                icon: Icons.badge_outlined,
                keyboard: TextInputType.number,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'NIK wajib diisi';
                  }
                  if (v.length < 15 || v.length > 16) {
                    return 'NIK harus 15–16 digit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nama
              _confirmField(
                controller: _namaController,
                label: 'Nama Lengkap (sesuai KTP)',
                hint: 'Masukkan nama lengkap',
                icon: Icons.person_outline_rounded,
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Tanggal Lahir
              GestureDetector(
                onTap: _pickTanggalLahir,
                child: AbsorbPointer(
                  child: _confirmField(
                    controller: _tglLahirController,
                    label: 'Tanggal Lahir',
                    icon: Icons.cake_outlined,
                    hint: 'DD-MM-YYYY (opsional)',
                    suffix: const Icon(Icons.calendar_today_outlined,
                        size: 18, color: Color(0xFF64748B)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Syarat & Ketentuan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: _agreeTerms,
                        onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                        activeColor: const Color(0xFF15803D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF475569),
                                height: 1.4),
                            children: [
                              TextSpan(text: 'Saya menyetujui '),
                              TextSpan(
                                text: 'Syarat & Ketentuan',
                                style: TextStyle(
                                    color: Color(0xFF15803D),
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: ' serta '),
                              TextSpan(
                                text: 'Kebijakan Privasi',
                                style: TextStyle(
                                    color: Color(0xFF15803D),
                                    fontWeight: FontWeight.bold),
                              ),
                              TextSpan(text: ' GASPOL by INTIRA.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tombol Daftar
              BlocBuilder<AuthBloc, AuthState>(
                builder: (ctx, state) {
                  final isLoading = state is AuthLoading;
                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _submit,
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
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.check_circle_outline_rounded,
                                    size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Selesaikan Pendaftaran',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTanggalLahir() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _tglLahirController.text =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
    }
  }

  // ─────────────────────────────────────────────────── Helper Widgets ─────────
  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInputStyles.formLabel(label, required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          obscureText: obscure,
          validator: validator,
          decoration: AppInputStyles.inputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF15803D)),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }

  Widget _confirmField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppInputStyles.formLabel(label, required: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: formatters,
          validator: validator,
          decoration: AppInputStyles.inputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF15803D)),
            suffixIcon: suffix,
          ).copyWith(
            helperText: '✏️ Koreksi jika hasil pemindaian tidak sesuai',
            helperStyle: const TextStyle(fontSize: 11, color: Color(0xFFD97706)),
          ),
        ),
      ],
    );
  }

  Widget _previewRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "—",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value != null
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFEF4444),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, size: 14, color: Color(0xFF15803D)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
            ),
          ),
        ],
      ),
    );
  }
}
