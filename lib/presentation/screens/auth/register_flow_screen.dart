import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/services/ktp_ocr_service.dart';
import '../../../core/widgets/app_button.dart';
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
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: List.generate(4, (i) {
          final isActive = i <= _currentStep;
          final isDone = i < _currentStep;
          return Expanded(
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : Text('${i + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? Colors.white
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            )),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            isActive ? AppColors.primary : Colors.grey.shade500,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis),
                ),
                if (i < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      color: i < _currentStep
                          ? AppColors.primary
                          : Colors.grey.shade300,
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
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan email, nomor telepon, dan password untuk membuat akun baru.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
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
              icon: Icons.lock_outline,
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textMuted,
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
              hint: 'Ulangi password',
              icon: Icons.lock_outline,
              obscure: _obscureConfirmPassword,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: AppColors.textMuted,
                ),
                onPressed: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              validator: (v) {
                if (v != _passwordController.text) return 'Password tidak sama';
                return null;
              },
            ),
            const SizedBox(height: 32),
            AppButton(text: 'Lanjutkan', onPressed: _validateAndNext),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Sudah punya akun? ',
                    style: TextStyle(color: AppColors.textSecondary)),
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/login'),
                  child: const Text('Masuk',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════ STEP 2: Foto KTP ══════════
  Widget _buildStep2() {
    final hasPhoto = _ktpImage != null;
    final hasData = _ktpData != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ambil foto KTP Anda. Pastikan seluruh teks terlihat jelas. Data akan terbaca otomatis.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          // ── Preview KTP ────────────────────────────────────────────────────
          GestureDetector(
            onTap: hasPhoto && !_isProcessingOcr
                ? () => _showSourcePicker()
                : null,
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasPhoto ? AppColors.primary : AppColors.border,
                  width: hasPhoto ? 2 : 1,
                ),
              ),
              child: hasPhoto
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(_ktpImage!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover),
                        ),
                        if (_isProcessingOcr)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircularProgressIndicator(
                                      color: Colors.white),
                                  SizedBox(height: 10),
                                  Text('Membaca data KTP...',
                                      style: TextStyle(color: Colors.white)),
                                  Text('dual-pass OCR + auto-rotate',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 11)),
                                ],
                              ),
                            ),
                          ),
                        if (!_isProcessingOcr)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _ktpImage = null;
                                _ktpData = null;
                              }),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card,
                            size: 56, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        const Text('Belum ada foto KTP',
                            style: TextStyle(color: AppColors.textSecondary)),
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
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(hasPhoto ? 'Foto Ulang' : 'Kamera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: () => _pickAndProcessKtp(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(hasPhoto ? 'Ganti Galeri' : 'Galeri'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                      SizedBox(width: 6),
                      Text('Data terdeteksi:',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _previewRow('NIK', _ktpData!.nik),
                  _previewRow('Nama', _ktpData!.nama),
                  _previewRow('Tgl Lahir', _ktpData!.tanggalLahir),
                  const SizedBox(height: 6),
                  const Text(
                    '✏️ Data bisa dikoreksi di langkah berikutnya.',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Tips ───────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.lightbulb_outline,
                      color: AppColors.info, size: 18),
                  const SizedBox(width: 6),
                  const Text('Tips foto KTP:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                _tip('Crop rapat ke 4 sisi kartu KTP'),
                _tip('Hindari pantulan cahaya atau bayangan'),
                _tip('Pastikan seluruh teks terlihat jelas'),
              ],
            ),
          ),

          const SizedBox(height: 32),
          AppButton(
            text: 'Lanjut ke Foto Selfie',
            onPressed: (_ktpImage != null && !_isProcessingOcr)
                ? _goToSelfie
                : null,
          ),
        ],
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
            leading: const Icon(Icons.camera_alt, color: AppColors.primary),
            title: const Text('Ambil Foto'),
            onTap: () {
              Navigator.pop(context);
              _pickAndProcessKtp(ImageSource.camera);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: AppColors.primary),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Ambil foto selfie wajah Anda untuk verifikasi identitas (KYC) dan keamanan akun.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // ── Preview Selfie ──────────────────────────────────────────────────
          Center(
            child: Container(
              width: 200,
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasSelfie ? AppColors.success : AppColors.border,
                  width: hasSelfie ? 2.5 : 1,
                ),
              ),
              child: hasSelfie
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
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
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle,
                                    color: AppColors.success, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Wajah Terverifikasi',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
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
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.face,
                            size: 48,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Belum ada foto selfie',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),

          // ── Tombol Aksi Selfie ─────────────────────────────────────────────
          if (!hasSelfie) ...[
            AppButton(
              text: 'Buka Kamera Selfie',
              icon: Icons.camera_front_outlined,
              onPressed: _openSelfieCamera,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Pilih dari Galeri'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppColors.primary),
                foregroundColor: AppColors.primary,
              ),
              onPressed: _pickSelfieFromGallery,
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Foto Ulang'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                    ),
                    onPressed: _openSelfieCamera,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Lanjut ke Konfirmasi',
                    onPressed: _goToKonfirmasi,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),

          // ── Tips Selfie ───────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.lightbulb_outline,
                      color: AppColors.info, size: 18),
                  const SizedBox(width: 6),
                  const Text('Panduan foto selfie:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 6),
                _tip('Pastikan wajah berada di tengah bingkai oval'),
                _tip('Pencahayaan cukup dan wajah terlihat terang'),
                _tip('Lepaskan masker, kacamata hitam, atau penutup wajah'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════ STEP 4: Konfirmasi ══════════
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step3FormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Dokumen KTP & Selfie
            Row(
              children: [
                if (_ktpImage != null)
                  Expanded(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
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
                                color: Colors.black54,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: const Text(
                                  'KTP ✓',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
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
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
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
                                color: Colors.black54,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 2),
                                child: const Text(
                                  'Selfie ✓',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 10),
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
            const SizedBox(height: 16),

            // Info banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Periksa data yang terbaca dari KTP. Koreksi jika ada yang salah sebelum submit.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // NIK
            _confirmField(
              controller: _nikController,
              label: 'NIK *',
              icon: Icons.credit_card_outlined,
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
              label: 'Nama Lengkap *',
              icon: Icons.person_outline,
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
                  suffix: const Icon(Icons.calendar_today,
                      size: 18, color: AppColors.textMuted),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Tombol kembali ke foto jika data salah
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => _goToStep(1),
                  icon: const Icon(Icons.credit_card, size: 16),
                  label: const Text('Ulang KTP'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                ),
                const Text(' • ', style: TextStyle(color: AppColors.textMuted)),
                TextButton.icon(
                  onPressed: () => _goToStep(2),
                  icon: const Icon(Icons.face, size: 16),
                  label: const Text('Ulang Selfie'),
                  style: TextButton.styleFrom(foregroundColor: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Syarat & Ketentuan
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _agreeTerms,
                    onChanged: (v) => setState(() => _agreeTerms = v ?? false),
                    activeColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textSecondary),
                        children: [
                          const TextSpan(text: 'Saya menyetujui '),
                          TextSpan(
                            text: 'Syarat dan Ketentuan',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                          const TextSpan(text: ' serta '),
                          TextSpan(
                            text: 'Kebijakan Privasi',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Tombol Daftar
            BlocBuilder<AuthBloc, AuthState>(
              builder: (ctx, state) => AppButton(
                text: 'Daftar',
                isLoading: state is AuthLoading,
                onPressed: state is AuthLoading ? null : _submit,
              ),
            ),
            const SizedBox(height: 32),
          ],
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
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
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
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
            suffixIcon: suffix,
          ).copyWith(
            helperText: '✏️ Koreksi jika hasil OCR tidak tepat',
            helperStyle: const TextStyle(fontSize: 11, color: Color(0xFFD97706)),
          ),
        ),
      ],
    );
  }

  Widget _previewRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 2),
      child: Text(
        '$label: ${value ?? "—"}',
        style: TextStyle(
            fontSize: 12,
            color: value != null
                ? AppColors.textSecondary
                : AppColors.error.withValues(alpha: 0.7)),
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ',
              style: TextStyle(fontSize: 12, color: AppColors.info)),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
