import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/calculator_model.dart';
import '../../../data/repositories/calculator_repository.dart';
import '../../../core/utils/navigation_helper.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../blocs/auth/auth_bloc.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorRepository _calculatorRepository = CalculatorRepository();
  
  CalculatorProductModel? _selectedProduct;
  final _amountController = TextEditingController();
  
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
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    developer.log('_loadProducts called', name: 'CalculatorScreen');
    setState(() {
      _isLoadingProducts = true;
      _productsError = null;
    });

    try {
      final products = await _calculatorRepository.getProducts();
      developer.log('Products loaded: ${products.length}', name: 'CalculatorScreen');
      for (var i = 0; i < products.length; i++) {
        developer.log('Product $i: ${products[i].name} (id: ${products[i].id})', name: 'CalculatorScreen');
      }
      setState(() {
        _products = products;
        _isLoadingProducts = false;
        developer.log('setState completed: _products.length = ${_products.length}', name: 'CalculatorScreen');
      });
    } catch (e, stackTrace) {
      developer.log('Error loading products: $e', name: 'CalculatorScreen', error: e, stackTrace: stackTrace);
      setState(() {
        _isLoadingProducts = false;
        _productsError = e.toString();
      });
    }
  }

  /// Load tiers untuk produk yang memiliki hasTiers=true
  Future<void> _loadTiersForProduct(CalculatorProductModel product) async {
    if (!product.hasTiers || product.tiers != null) return;
    
    developer.log('Loading tiers for product: ${product.id}', name: 'CalculatorScreen');
    try {
      final tiers = await _calculatorRepository.getProductTiers(product.id);
      developer.log('Tiers loaded: ${tiers.length}', name: 'CalculatorScreen');
      
      // Update product dengan tiers baru
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
    } catch (e) {
      developer.log('Error loading tiers: $e', name: 'CalculatorScreen');
    }
  }

  /// Handle product selection
  void _onProductSelected(int productId) {
    final product = _products.firstWhere((p) => p.id == productId);
    developer.log('Product selected: ${product.name}, isSharia: ${product.isSharia}, hasTiers: ${product.hasTiers}', 
        name: 'CalculatorScreen');
    
    setState(() {
      _selectedProduct = product;
      _result = null;
    });
    
    // Load tiers jika produk memiliki hasTiers
    if (product.hasTiers && product.tiers == null) {
      _loadTiersForProduct(product);
    }
  }

  void _onQuickAmountSelected(int amount) {
    _amountController.text = Formatters.formatNumber(amount);
    setState(() {});
  }

  void _calculate() async {
    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih produk terlebih dahulu'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final amountText = _amountController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan jumlah pinjaman'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountText) ?? 0;
    
    // Validate against product limits
    if (_selectedProduct!.minAmount != null && amount < _selectedProduct!.minAmount!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimal pinjaman ${Formatters.formatCurrency(_selectedProduct!.minAmount!)}'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    
    if (_selectedProduct!.maxAmount != null && amount > _selectedProduct!.maxAmount!) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maksimal pinjaman ${Formatters.formatCurrency(_selectedProduct!.maxAmount!)}'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (amount < 500000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal pinjaman Rp 500.000'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isCalculating = true;
      _result = null;
    });

    try {
      // API akan otomatis mencari tier yang cocok untuk produk syariah
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
      developer.log('API calculation failed, using local: $e', name: 'CalculatorScreen');
      // Fallback to local calculation if API fails
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
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header
          GradientHeader(
            showBackButton: true,
            child: const GradientHeaderTitle(
              title: 'Kalkulator Pinjaman',
              subtitle: 'Hitung estimasi pinjaman Anda',
            ),
          ),

          // Content
          Transform.translate(
            offset: const Offset(0, -24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Form Card
                  _buildFormCard(),
                  const SizedBox(height: 16),

                  // Result Card
                  if (_result != null) _buildResultCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Dropdown
          const Text(
            'Produk Pinjaman',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          
          // Debug info
          if (_products.isEmpty && !_isLoadingProducts)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _productsError != null 
                    ? AppColors.error.withValues(alpha: 0.1) 
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _productsError != null ? AppColors.error : AppColors.warning,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _productsError != null ? Icons.error_outline : Icons.warning_amber, 
                    color: _productsError != null ? AppColors.error : AppColors.warning, 
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _productsError != null 
                              ? 'Gagal memuat produk' 
                              : 'Tidak ada produk tersedia',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        if (_productsError != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _productsError!,
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                          ),
                        ],
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _loadProducts,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Muat ulang'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          if (_isLoadingProducts)
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  const Text('Memuat produk...'),
                ],
              ),
            ),
          
          if (_products.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonFormField<int>(
                value: _selectedProduct?.id,
                isExpanded: true,
                decoration: const InputDecoration(
                  hintText: 'Pilih Produk',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.keyboard_arrow_down),
                items: _products.map((product) {
                  return DropdownMenuItem<int>(
                    value: product.id,
                    child: Text(
                      product.isSharia 
                          ? '${product.name} (Syariah)' 
                          : product.name,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _onProductSelected(value);
                  }
                },
              ),
            ),
          
          // Show product info if selected
          if (_selectedProduct != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.info),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _buildProductInfoText(),
                      style: TextStyle(fontSize: 12, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          // Loan Amount
          const Text(
            'Jumlah Pinjaman',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Rp',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparatorFormatter(),
                    ],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Quick Amount Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickAmounts.map((amount) {
              return GestureDetector(
                onTap: () => _onQuickAmountSelected(amount),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _formatShortAmount(amount),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Calculate Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isCalculating ? null : _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                  : const Text(
                      'Hitung',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Hasil Perhitungan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Cash Received (Primary)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Uang yang Diterima',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatCurrency(_result!.cashReceived),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details
          _buildDetailRow('Jumlah Pinjaman', Formatters.formatCurrency(_result!.loanAmount)),
          _buildDetailRow(
            'Biaya Admin (${_result!.adminFeePercent.toStringAsFixed(1)}%)',
            '- ${Formatters.formatCurrency(_result!.adminFee)}',
            isDeduction: true,
          ),
          _buildDetailRow(
            'Bunga (${_result!.interestRate.toStringAsFixed(1)}%)',
            '- ${Formatters.formatCurrency(_result!.interest)}',
            isDeduction: true,
          ),
          const Divider(height: 24),
          _buildDetailRow('Jangka Waktu', '${_result!.tenor} hari'),
          _buildDetailRow('Jatuh Tempo', Formatters.formatDate(_result!.dueDate)),
          const SizedBox(height: 16),

          // Note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: AppColors.info,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _result!.note ?? 'Nilai aktual dapat berbeda tergantung hasil taksiran.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                final authState = context.read<AuthBloc>().state;
                if (authState is AuthAuthenticated) {
                  NavigationHelper.goToPawnRequestCreate(context);
                } else {
                  Navigator.pushNamed(context, '/login');
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ajukan Gadai Sekarang',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isDeduction = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDeduction ? AppColors.error : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _buildProductInfoText() {
    if (_selectedProduct == null) return '';
    
    final product = _selectedProduct!;
    final parts = <String>[];
    
    // Mark sharia products
    if (product.isSharia) {
      parts.add('⭐ Syariah');
    }
    
    if (product.minAmount != null && product.maxAmount != null) {
      parts.add('Pinjaman: ${Formatters.formatCurrency(product.minAmount!.toDouble())} - ${Formatters.formatCurrency(product.maxAmount!.toDouble())}');
    }
    
    if (product.interestRate != null && !product.isSharia) {
      parts.add('Bunga: ${product.interestRate}%/bulan');
    }
    
    if (product.adminFeePercent != null && !product.isSharia) {
      parts.add('Admin: ${product.adminFeePercent}%');
    }
    
    return parts.join(' • ');
  }

  String _formatShortAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(0)} Juta';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} Ribu';
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
