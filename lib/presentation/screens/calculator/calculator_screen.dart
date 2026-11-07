import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../config/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/navigation_helper.dart';
import '../../../core/widgets/app_input_styles.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../data/models/calculator_model.dart';
import '../../../data/repositories/calculator_repository.dart';
import '../../blocs/auth/auth_bloc.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorRepository _calculatorRepository = CalculatorRepository();
  final TextEditingController _amountController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  CalculatorProductModel? _selectedProduct;
  bool _isLoadingProducts = true;
  bool _isCalculating = false;
  String? _productsError;

  List<CalculatorProductModel> _products = [];
  CalculateResultModel? _result;

  final List<int> _quickAmounts = [
    1000000,
    2000000,
    5000000,
    10000000,
    20000000,
    50000000,
  ];

  @override
  void initState() {
    super.initState();
    _amountFocusNode.addListener(() {
      setState(() {});
    });
    _loadProducts();
  }

  @override
  void dispose() {
    _amountFocusNode.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    developer.log('_loadProducts called', name: 'CalculatorScreen');
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final products = await _calculatorRepository.getProducts();
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e, stackTrace) {
      developer.log('Error loading products: $e', name: 'CalculatorScreen', error: e, stackTrace: stackTrace);
      setState(() {
        _isLoadingProducts = false;
        _productsError = e.toString();
      });
    }
  }

  Future<void> _loadTiersForProduct(CalculatorProductModel product) async {
    if (!product.hasTiers || product.tiers != null) return;

    try {
      final tiers = await _calculatorRepository.getProductTiers(product.id);
      final updatedProduct = CalculatorProductModel(
        id: product.id,
        name: product.name,
        code: product.code,
        description: product.description,
        categoryId: product.categoryId,
        categoryName: product.categoryName,
        minAmount: product.minAmount,
        maxAmount: product.maxAmount,
        interestRate: product.interestRate,
        adminFeePercent: product.adminFeePercent,
        adminFeeFixed: product.adminFeeFixed,
        defaultTenor: product.defaultTenor,
        minTenor: product.minTenor,
        maxTenor: product.maxTenor,
        dueDateDays: product.dueDateDays,
        isSharia: product.isSharia,
        hasTiers: product.hasTiers,
        isActive: product.isActive,
        tiers: tiers,
      );

      setState(() {
        _selectedProduct = updatedProduct;
      });

      // Auto re-calculate if amount is already entered
      if (_amountController.text.isNotEmpty) {
        _calculate();
      }
    } catch (e) {
      developer.log('Error loading tiers: $e', name: 'CalculatorScreen');
    }
  }

  void _onProductSelected(int productId) {
    final product = _products.firstWhere((p) => p.id == productId);
    setState(() {
      _selectedProduct = product;
      _result = null;
    });

    if (product.hasTiers && product.tiers == null) {
      _loadTiersForProduct(product);
    } else if (_amountController.text.isNotEmpty) {
      _calculate();
    }
  }

  void _onQuickAmountSelected(int amount) {
    _amountController.text = Formatters.formatNumber(amount);
    setState(() {});

    if (_selectedProduct != null) {
      _calculate();
    }
  }

  double _getCurrentAmount() {
    return Formatters.parseNumber(_amountController.text);
  }

  void _calculate() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih produk gadai terlebih dahulu'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = _getCurrentAmount();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah pinjaman yang valid'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedProduct!.minAmount != null && amount < _selectedProduct!.minAmount!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimal pinjaman ${Formatters.formatCurrency(_selectedProduct!.minAmount!)}'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_selectedProduct!.maxAmount != null && amount > _selectedProduct!.maxAmount!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maksimal pinjaman ${Formatters.formatCurrency(_selectedProduct!.maxAmount!)}'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (amount < 500000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal pinjaman Rp 500.000'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
    });

    try {
      final result = await _calculatorRepository.calculate(
        CalculateRequest(
          productId: _selectedProduct!.id,
          amount: amount,
        ),
      );

      setState(() {
        _isCalculating = false;
        _result = result;
      });
    } catch (e) {
      developer.log('API calculation failed, fallback to local: $e', name: 'CalculatorScreen');
      final result = _calculatorRepository.calculateLocal(
        product: _selectedProduct!,
        amount: amount,
      );

      setState(() {
        _isCalculating = false;
        _result = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            GradientHeader(
              showBackButton: true,
              child: const GradientHeaderTitle(
                title: 'Kalkulator Pinjaman',
                subtitle: 'Hitung estimasi pencairan & pelunasan',
              ),
            ),

            // Content Body
            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildFormCard(),
                    const SizedBox(height: 16),
                    if (_result != null) _buildResultCard(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppInputStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Produk Pinjaman Label
          AppInputStyles.formLabel('Produk Pinjaman', required: true),

          // Loading / Error State
          if (_isLoadingProducts)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: const [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF15803D)),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Memuat daftar produk...',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else if (_products.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _productsError ?? 'Tidak ada produk tersedia',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF991B1B)),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadProducts,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Coba Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            DropdownButtonFormField<int>(
              key: ValueKey(_selectedProduct?.id),
              initialValue: _selectedProduct?.id,
              isExpanded: true,
              decoration: AppInputStyles.inputDecoration(
                hintText: 'Pilih jenis produk gadai',
                prefixIcon: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF15803D),
                  size: 20,
                ),
              ),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
              items: _products.map((product) {
                return DropdownMenuItem<int>(
                  value: product.id,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (product.isSharia)
                        Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Syariah',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  _onProductSelected(value);
                }
              },
            ),

          // Product Info Box (Clean & Minimal)
          if (_selectedProduct != null) _buildProductBadgeInfo(),

          const SizedBox(height: 18),

          // Loan Amount Label
          AppInputStyles.formLabel('Jumlah Pinjaman', required: true),

          // Integrated Modern Currency Input
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _amountFocusNode.hasFocus ? const Color(0xFF15803D) : const Color(0xFFE2E8F0),
                width: _amountFocusNode.hasFocus ? 1.6 : 1.2,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Rp',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    focusNode: _amountFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparatorFormatter(),
                    ],
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFCBD5E1),
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                  ),
                ),
                if (_amountController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _amountController.clear();
                      setState(() {
                        _result = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE2E8F0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Minimalist Limit Hint
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 2),
            child: Text(
              _selectedProduct?.minAmount != null
                  ? '*Rentang pinjaman: ${Formatters.formatCurrency(_selectedProduct!.minAmount!)} s/d ${Formatters.formatCurrency(_selectedProduct!.maxAmount ?? 0)}'
                  : '*Minimal nominal pinjaman Rp 500.000',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Pilihan Cepat Nominal
          const Text(
            'Pilihan Cepat Nominal',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),

          // Clean 3-Column Grid for Quick Amounts
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: _quickAmounts.map((amount) {
              final isSelected = _getCurrentAmount() == amount.toDouble();
              return InkWell(
                onTap: () => _onQuickAmountSelected(amount),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFDCFCE7) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF15803D) : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Rp ${_formatShortAmount(amount)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? const Color(0xFF15803D) : const Color(0xFF475569),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Calculate Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isCalculating ? null : _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isCalculating
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
                        Icon(Icons.calculate_outlined, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Hitung Estimasi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductBadgeInfo() {
    if (_selectedProduct == null) return const SizedBox.shrink();

    final product = _selectedProduct!;
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 16,
                color: Color(0xFF15803D),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  product.minAmount != null && product.maxAmount != null
                      ? 'Limit: ${Formatters.formatCurrency(product.minAmount!)} - ${Formatters.formatCurrency(product.maxAmount!)}'
                      : 'Produk aktif untuk simulasi',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15803D),
                  ),
                ),
              ),
              if (product.defaultTenor != null)
                Text(
                  '${product.defaultTenor} Hari',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF166534),
                  ),
                ),
            ],
          ),
          if (!product.isSharia && (product.interestRate != null || product.adminFeePercent != null)) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                if (product.interestRate != null)
                  Expanded(
                    child: Text(
                      '• Bunga: ${product.interestRate}%/bln',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                    ),
                  ),
                if (product.adminFeePercent != null)
                  Expanded(
                    child: Text(
                      '• Biaya Admin: ${product.adminFeePercent}%',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppInputStyles.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF15803D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Hasil Simulasi Pinjaman',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Estimasi pencairan dana & rincian pelunasan',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Primary Hero Card (Uang Diterima)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF15803D),
                  Color(0xFF166534),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF15803D).withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DANA BERSIH DITERIMA',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _selectedProduct?.isSharia == true ? 'Syariah' : 'Konvensional',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  Formatters.formatCurrency(_result!.cashReceived),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Dana tunai yang langsung diterima saat pencairan',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Section 1: Rincian Potongan Awal
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
                const Text(
                  'Rincian Pemotongan Awal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                _buildCleanDetailRow(
                  'Plafon Pinjaman',
                  Formatters.formatCurrency(_result!.loanAmount),
                  isBoldValue: true,
                ),
                _buildCleanDetailRow(
                  'Biaya Admin (${_result!.adminFeePercent.toStringAsFixed(1)}%)',
                  '- ${Formatters.formatCurrency(_result!.adminFee)}',
                  valueColor: const Color(0xFFDC2626),
                ),
                _buildCleanDetailRow(
                  'Sewa Modal / Bunga (${_result!.interestRate.toStringAsFixed(1)}%)',
                  '- ${Formatters.formatCurrency(_result!.interest)}',
                  valueColor: const Color(0xFFDC2626),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),
                _buildCleanDetailRow(
                  'Total Potongan',
                  '- ${Formatters.formatCurrency(_result!.totalDeduction)}',
                  isBoldValue: true,
                  valueColor: const Color(0xFFDC2626),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Section 2: Jadwal & Pelunasan
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
                const Text(
                  'Jadwal & Pelunasan',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF475569),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                _buildCleanDetailRow('Durasi Pinjaman', '${_result!.tenor} Hari'),
                _buildCleanDetailRow('Jatuh Tempo', Formatters.formatDate(_result!.dueDate)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                ),
                _buildCleanDetailRow(
                  'Pelunasan Saat Jatuh Tempo',
                  Formatters.formatCurrency(_result!.loanAmount),
                  isBoldValue: true,
                  valueColor: const Color(0xFF15803D),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Subtle Information Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(
                  Icons.verified_outlined,
                  color: Color(0xFF15803D),
                  size: 16,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Simulasi ini bersifat estimasi. Nilai pencairan aktual mengikuti hasil taksiran fisik agunan di kantor cabang.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF166534),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // CTA Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  NavigationHelper.goToPawnRequestCreate(context);
                } else {
                  Navigator.pushNamed(context, '/login');
                }
              },
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
                    'Ajukan Gadai Sekarang',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
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
    );
  }

  Widget _buildCleanDetailRow(
    String label,
    String value, {
    bool isBoldValue = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBoldValue ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortAmount(int amount) {
    if (amount >= 1000000) {
      final val = amount / 1000000;
      return val % 1 == 0 ? '${val.toInt()} Jt' : '${val.toStringAsFixed(1)} Jt';
    } else if (amount >= 1000) {
      final val = amount / 1000;
      return val % 1 == 0 ? '${val.toInt()} Rb' : '${val.toStringAsFixed(1)} Rb';
    }
    return amount.toString();
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

    final formatted = Formatters.formatNumber(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
