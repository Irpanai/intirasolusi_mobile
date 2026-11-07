import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/app_input_styles.dart';
import '../../../data/models/product_model.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/repositories/pawn_request_repository.dart';
import '../../blocs/pawn_request/pawn_request_bloc.dart';
import '../../../core/widgets/loading_widget.dart';

class PawnRequestCreateScreen extends StatefulWidget {
  const PawnRequestCreateScreen({super.key});

  @override
  State<PawnRequestCreateScreen> createState() => _PawnRequestCreateScreenState();
}

class _PawnRequestCreateScreenState extends State<PawnRequestCreateScreen> {
  int _currentStep = 1;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  bool _isSubmitting = false;
  
  // Daily limit
  static const int _maxDailySubmissions = 3;
  int _todaySubmissionCount = 0;
  bool _isCheckingLimit = true;

  // Form controllers
  final _collateralNameController = TextEditingController();
  final _collateralDescriptionController = TextEditingController();
  final _estimatedValueController = TextEditingController();
  final _requestedAmountController = TextEditingController();
  final _notesController = TextEditingController();

  // Selected values
  int? _selectedProductId;
  int? _selectedCategoryId;
  int? _selectedBranchId;
  bool _agreeTerms = false;

  // Photos
  final List<XFile> _photos = [];

  // API data
  List<ProductModel> _products = [];
  List<CollateralCategoryModel> _categories = [];
  List<BranchModel> _branches = [];

  @override
  void initState() {
    super.initState();
    // Load form data from API
    context.read<PawnRequestBloc>().add(LoadFormData());
    // Check daily submission limit
    _checkDailyLimit();
  }

  Future<void> _checkDailyLimit() async {
    try {
      final repository = PawnRequestRepository();
      final count = await repository.getTodaySubmissionCount();
      setState(() {
        _todaySubmissionCount = count;
        _isCheckingLimit = false;
      });
      
      // Show warning if limit reached
      if (count >= _maxDailySubmissions) {
        _showDailyLimitReachedDialog();
      }
    } catch (e) {
      setState(() => _isCheckingLimit = false);
    }
  }

  void _showDailyLimitReachedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Batas Harian Tercapai',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda sudah mengajukan $_todaySubmissionCount pengajuan hari ini. Batas maksimal adalah $_maxDailySubmissions pengajuan per hari.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Silakan coba lagi besok.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Kembali'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _collateralNameController.dispose();
    _collateralDescriptionController.dispose();
    _estimatedValueController.dispose();
    _requestedAmountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 1) {
      if (_formKey.currentState?.validate() ?? false) {
        setState(() => _currentStep = 2);
      }
    } else if (_currentStep == 2) {
      if (_photos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Minimal upload 1 foto barang')),
        );
        return;
      }
      setState(() => _currentStep = 3);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _pickPhotos() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 5 foto')),
      );
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage(
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (images.isNotEmpty) {
      final remaining = 5 - _photos.length;
      setState(() {
        _photos.addAll(images.take(remaining));
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 5 foto')),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _photos.add(image);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _submitRequest() {
    // Check daily limit before submission
    if (_todaySubmissionCount >= _maxDailySubmissions) {
      _showDailyLimitReachedDialog();
      return;
    }

    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda harus menyetujui syarat dan ketentuan')),
      );
      return;
    }

    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih produk pinjaman')),
      );
      return;
    }

    // Parse loan amount
    final loanAmountStr = _requestedAmountController.text.replaceAll('.', '');
    final loanAmount = double.tryParse(loanAmountStr) ?? 0;

    if (loanAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah pinjaman yang valid')),
      );
      return;
    }

    // Parse estimated value - now required
    final estValueStr = _estimatedValueController.text.replaceAll('.', '');
    final estimatedValue = double.tryParse(estValueStr) ?? 0;

    if (estimatedValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan estimasi nilai barang')),
      );
      return;
    }

    // Validate loan amount doesn't exceed estimated value
    if (loanAmount > estimatedValue) {
      _showValueLimitAlert(
        'Jumlah Melebihi Batas',
        'Jumlah pinjaman (Rp ${_requestedAmountController.text}) tidak boleh melebihi estimasi nilai barang (Rp ${_estimatedValueController.text})',
      );
      return;
    }

    // Convert photos to File list
    final photoFiles = _photos.map((xfile) => File(xfile.path)).toList();

    // Submit via BLoC
    context.read<PawnRequestBloc>().add(SubmitPawnRequest(
      productId: _selectedProductId!,
      categoryId: _selectedCategoryId,
      collateralName: _collateralNameController.text,
      collateralDescription: _collateralDescriptionController.text.isNotEmpty
          ? _collateralDescriptionController.text
          : null,
      estimatedValue: estimatedValue,
      loanAmount: loanAmount,
      preferredBranchId: _selectedBranchId,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      photos: photoFiles,
    ));
  }

  void _showSuccessDialog(String requestCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pengajuan Berhasil!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: requestCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kode berhasil disalin'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      requestCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 16,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.copy,
                      size: 18,
                      color: AppColors.primary.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap untuk menyalin kode',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pengajuan gadai Anda sedang diproses. Kami akan menghubungi Anda segera.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to list
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Kembali ke Daftar'),
            ),
          ),
        ],
      ),
    );
  }

  void _showValueLimitAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Mengerti'),
            ),
          ),
        ],
      ),
    );
  }

  void _validateLoanAgainstEstimate() {
    final estRaw = _estimatedValueController.text.replaceAll('.', '');
    final estimatedValue = double.tryParse(estRaw) ?? 0;
    
    final loanRaw = _requestedAmountController.text.replaceAll('.', '');
    final loanAmount = double.tryParse(loanRaw) ?? 0;
    
    if (estimatedValue > 0 && loanAmount > estimatedValue) {
      _showValueLimitAlert(
        'Jumlah Melebihi Batas',
        'Jumlah pinjaman tidak boleh melebihi estimasi nilai barang (Rp ${_estimatedValueController.text})',
      );
      // Reset to max allowed value (estimated value)
      final formatted = estimatedValue.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
      _requestedAmountController.text = formatted;
      _requestedAmountController.selection = TextSelection.collapsed(
        offset: _requestedAmountController.text.length,
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pengajuan Gagal',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Syarat dan Ketentuan',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Dengan mengajukan gadai, saya menyatakan bahwa:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              _buildTermItem('1', 'Barang yang saya gadaikan adalah milik saya sendiri dan bukan hasil dari tindak kejahatan.'),
              _buildTermItem('2', 'Saya bertanggung jawab penuh atas keaslian dan kepemilikan barang yang digadaikan.'),
              _buildTermItem('3', 'Saya bersedia memberikan informasi yang benar dan akurat mengenai barang jaminan.'),
              _buildTermItem('4', 'Saya memahami bahwa barang akan ditahan sebagai jaminan hingga pinjaman dilunasi.'),
              _buildTermItem('5', 'Saya bersedia membayar bunga dan biaya administrasi sesuai ketentuan yang berlaku.'),
              _buildTermItem('6', 'Saya memahami bahwa jika tidak melunasi pinjaman sesuai jangka waktu, barang dapat dilelang.'),
              _buildTermItem('7', 'Saya menyetujui bahwa keputusan penilaian barang sepenuhnya menjadi wewenang pihak Intira Solusi.'),
              const SizedBox(height: 16),
              Text(
                'Dengan mencentang kotak persetujuan, saya menyatakan telah membaca, memahami, dan menyetujui seluruh syarat dan ketentuan di atas.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Saya Mengerti'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getProductName(int? id) {
    if (id == null) return '-';
    final product = _products.where((p) => p.id == id).firstOrNull;
    return product?.name ?? '-';
  }

  String _getCategoryName(int? id) {
    if (id == null) return '-';
    final category = _categories.where((c) => c.id == id).firstOrNull;
    return category?.name ?? '-';
  }

  String _getBranchName(int? id) {
    if (id == null) return 'Tidak dipilih';
    final branch = _branches.where((b) => b.id == id).firstOrNull;
    return branch?.name ?? 'Tidak dipilih';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PawnRequestBloc, PawnRequestState>(
      listener: (context, state) {
        if (state is PawnRequestFormLoaded) {
          setState(() {
            _products = state.products;
            _categories = state.categories;
            _branches = state.branches;
          });
        } else if (state is PawnRequestSubmitSuccess) {
          setState(() => _isSubmitting = false);
          _showSuccessDialog(state.requestCode);
        } else if (state is PawnRequestError) {
          setState(() => _isSubmitting = false);
          _showErrorDialog(state.message);
        } else if (state is PawnRequestLoading) {
          // Only set submitting if we're on step 3
          if (_currentStep == 3) {
            setState(() => _isSubmitting = true);
          }
        }
      },
      builder: (context, state) {
        // Show loading while form data is being loaded
        if (state is PawnRequestFormLoading) {
          return Scaffold(
            backgroundColor: AppColors.background,
            body: Column(
              children: [
                _buildHeader(),
                const Expanded(
                  child: Center(
                    child: LoadingWidget(message: 'Memuat data...'),
                  ),
                ),
              ],
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Transform.translate(
                    offset: const Offset(0, -24),
                    child: _buildContent(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 14, bottom: 42, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF14532D), // Deep green 900
            Color(0xFF15803D), // Emerald 700
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
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
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Kembali',
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
            const SizedBox(height: 16),
            const Text(
              'Ajukan Gadai Online',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Isi formulir berikut untuk taksiran barang agunan',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12.5,
                    ),
                  ),
                ),
                if (!_isCheckingLimit) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _todaySubmissionCount >= _maxDailySubmissions
                          ? Colors.red.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_maxDailySubmissions - _todaySubmissionCount}/$_maxDailySubmissions sisa kuota',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: AppInputStyles.cardDecoration(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildStepIndicator(),
              const SizedBox(height: 24),
              if (_currentStep == 1) _buildStep1(),
              if (_currentStep == 2) _buildStep2(),
              if (_currentStep == 3) _buildStep3(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStep(1, 'Info'),
        _buildStepDivider(1),
        _buildStep(2, 'Foto'),
        _buildStepDivider(2),
        _buildStep(3, 'Kirim'),
      ],
    );
  }

  Widget _buildStep(int step, String label) {
    final isActive = _currentStep >= step;
    final isCurrent = _currentStep == step;

    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isActive ? AppColors.primary : Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: TextStyle(
                  color: isActive ? Colors.white : Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: isCurrent ? AppColors.textPrimary : AppColors.textMuted,
                fontWeight: isCurrent ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(int afterStep) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        width: 16,
        height: 2,
        color: _currentStep > afterStep ? AppColors.primary : Colors.grey.shade200,
      ),
    );
  }

  // Step 1: Product & Collateral Info
  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Dropdown
          _buildLabel('Produk Pinjaman', required: true),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedProductId,
            decoration: _inputDecoration('Pilih Produk'),
            isExpanded: true,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            items: _products.map((p) {
              return DropdownMenuItem(
                value: p.id,
                child: Text(
                  p.name,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedProductId = value),
            validator: (value) => value == null ? 'Pilih produk pinjaman' : null,
          ),
          const SizedBox(height: 16),

          // Category Dropdown
          _buildLabel('Kategori Barang', required: true),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedCategoryId,
            decoration: _inputDecoration('Pilih Kategori'),
            isExpanded: true,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            items: _categories.map((c) {
              return DropdownMenuItem(
                value: c.id,
                child: Text(
                  c.name,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCategoryId = value),
            validator: (value) => value == null ? 'Pilih kategori barang' : null,
          ),
          const SizedBox(height: 16),

          // Collateral Name
          _buildLabel('Nama Barang Jaminan', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _collateralNameController,
            decoration: _inputDecoration('Contoh: Cincin Emas 5 gram'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Nama barang wajib diisi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Description
          _buildLabel('Deskripsi Barang'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _collateralDescriptionController,
            decoration: _inputDecoration('Deskripsi detail barang (warna, kondisi, dll)'),
            maxLines: 3,
          ),
          const SizedBox(height: 16),

          // Estimated Value
          _buildLabel('Estimasi Nilai Barang', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _estimatedValueController,
            decoration: _inputDecoration('0').copyWith(
              prefixText: 'Rp ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ThousandsSeparatorFormatter(),
            ],
            textAlign: TextAlign.right,
            onChanged: (value) {
              final rawValue = value.replaceAll('.', '');
              final numValue = double.tryParse(rawValue) ?? 0;
              if (numValue > 25000000) {
                _showValueLimitAlert(
                  'Batas Maksimal',
                  'Estimasi nilai barang maksimal Rp 25.000.000',
                );
                // Reset to max value
                _estimatedValueController.text = '25.000.000';
                _estimatedValueController.selection = TextSelection.collapsed(
                  offset: _estimatedValueController.text.length,
                );
              }
              // Revalidate loan amount if it exceeds new estimated value
              _validateLoanAgainstEstimate();
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Estimasi nilai barang wajib diisi';
              }
              final rawValue = value.replaceAll('.', '');
              final numValue = double.tryParse(rawValue) ?? 0;
              if (numValue <= 0) {
                return 'Masukkan estimasi nilai yang valid';
              }
              if (numValue > 25000000) {
                return 'Maksimal Rp 25.000.000';
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Maksimal Rp 25.000.000',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          // Requested Amount
          _buildLabel('Jumlah Pinjaman yang Diinginkan', required: true),
          const SizedBox(height: 8),
          TextFormField(
            controller: _requestedAmountController,
            decoration: _inputDecoration('0').copyWith(
              prefixText: 'Rp ',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _ThousandsSeparatorFormatter(),
            ],
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
            onChanged: (value) => _validateLoanAgainstEstimate(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Jumlah pinjaman wajib diisi';
              }
              final rawValue = value.replaceAll('.', '');
              final loanAmount = double.tryParse(rawValue) ?? 0;
              if (loanAmount <= 0) {
                return 'Masukkan jumlah pinjaman yang valid';
              }
              // Check against estimated value
              final estRaw = _estimatedValueController.text.replaceAll('.', '');
              final estimatedValue = double.tryParse(estRaw) ?? 0;
              if (estimatedValue > 0 && loanAmount > estimatedValue) {
                return 'Tidak boleh melebihi estimasi nilai barang';
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Maksimal sesuai estimasi nilai barang',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          // Branch Dropdown
          _buildLabel('Cabang Preferensi'),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: _selectedBranchId,
            decoration: _inputDecoration('Pilih Cabang (Opsional)'),
            isExpanded: true,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            items: _branches.map((b) {
              return DropdownMenuItem(
                value: b.id,
                child: Text(
                  b.name,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedBranchId = value),
          ),
          const SizedBox(height: 4),
          Text(
            'Cabang yang ingin Anda kunjungi untuk proses gadai',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          _buildLabel('Catatan Tambahan'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            decoration: _inputDecoration('Catatan untuk admin (opsional)'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Next Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Lanjut',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: Photos
  Widget _buildStep2() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.camera_alt,
            size: 32,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Upload Foto Barang',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Foto yang jelas membantu proses review lebih cepat',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),

        // Photo Preview Grid
        if (_photos.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _photos.length,
            itemBuilder: (context, index) {
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(_photos[index].path),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removePhoto(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],

        // Upload Area
        if (_photos.length < 5) ...[
          GestureDetector(
            onTap: _pickPhotos,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cloud_upload_outlined,
                      size: 32,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tap untuk upload foto',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'JPG, PNG (Max 5MB per foto)',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text('Ambil Foto'),
              ),
            ],
          ),
        ],

        Text(
          'Minimal 1 foto, maksimal 5 foto',
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: 20),

        // Tips
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Tips foto yang baik:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildTip('Foto dengan pencahayaan yang cukup'),
              _buildTip('Foto dari berbagai sisi'),
              _buildTip('Pastikan foto tidak blur'),
              _buildTip('Sertakan foto cap/merk jika ada'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Navigation Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Kembali',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Lanjut',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check, color: Colors.blue.shade700, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 3: Confirmation
  Widget _buildStep3() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: 32,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Konfirmasi Pengajuan',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pastikan data sudah benar sebelum mengirim',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 24),

        // Summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildSummaryItem('Produk', _getProductName(_selectedProductId)),
              _buildSummaryItem('Kategori Barang', _getCategoryName(_selectedCategoryId)),
              _buildSummaryItem('Barang Jaminan', _collateralNameController.text),
              _buildSummaryItem(
                'Jumlah Pinjaman',
                'Rp ${_requestedAmountController.text}',
                isHighlighted: true,
              ),
              _buildSummaryItem('Jumlah Foto', '${_photos.length} foto'),
              _buildSummaryItem('Cabang Preferensi', _getBranchName(_selectedBranchId)),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Terms Checkbox
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _agreeTerms,
                  onChanged: (value) => setState(() => _agreeTerms = value ?? false),
                  activeColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Saya menyetujui',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showTermsDialog(),
                        child: const Text(
                          'Syarat dan Ketentuan',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // const SizedBox(height: 4),
                      Text(
                        'yang berlaku untuk pengajuan gadai',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Navigation Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, size: 18, color: _isSubmitting ? Colors.grey : AppColors.textPrimary),
                    const SizedBox(width: 8),
                    Text(
                      'Kembali',
                      style: TextStyle(
                        color: _isSubmitting ? Colors.grey : AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: (_agreeTerms && !_isSubmitting) ? _submitRequest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send, size: 18),
                          const SizedBox(width: 8),
                          const Text(
                            'Kirim',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value, {bool isHighlighted = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            textAlign: TextAlign.left,
            style: TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
              color: isHighlighted ? AppColors.primary : AppColors.textPrimary,
              fontSize: isHighlighted ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return AppInputStyles.formLabel(text, required: required);
  }

  InputDecoration _inputDecoration(String hint) {
    return AppInputStyles.inputDecoration(hintText: hint);
  }
}

class _ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = int.tryParse(newValue.text.replaceAll('.', ''));
    if (number == null) {
      return oldValue;
    }

    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
