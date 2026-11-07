import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/utils/formatters.dart';

class CompoundingInterestScreen extends StatefulWidget {
  const CompoundingInterestScreen({super.key});

  @override
  State<CompoundingInterestScreen> createState() => _CompoundingInterestScreenState();
}

class _CompoundingInterestScreenState extends State<CompoundingInterestScreen> {
  final _principalController = TextEditingController();
  final _monthlyController = TextEditingController();
  double _annualRate = 6.0;
  double _years = 5;
  _CompoundResult? _result;

  @override
  void dispose() {
    _principalController.dispose();
    _monthlyController.dispose();
    super.dispose();
  }

  void _calculate() {
    final principal = double.tryParse(_principalController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final monthly = double.tryParse(_monthlyController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    if (principal <= 0 && monthly <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan modal awal atau setoran bulanan')),
      );
      return;
    }

    final r = _annualRate / 100 / 12;
    final n = (_years * 12).toInt();
    final totalDeposit = principal + (monthly * n);

    double futureValue;
    if (r == 0) {
      futureValue = totalDeposit;
    } else {
      final compoundPrincipal = principal * pow(1 + r, n);
      final compoundMonthly = monthly * ((pow(1 + r, n) - 1) / r);
      futureValue = compoundPrincipal + compoundMonthly;
    }

    final totalInterest = futureValue - totalDeposit;

    setState(() {
      _result = _CompoundResult(
        totalAsset: futureValue,
        totalDeposit: totalDeposit,
        totalInterest: totalInterest,
        principal: principal,
        monthlyDeposit: monthly,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(
              showBackButton: true,
              child: const GradientHeaderTitle(
                title: 'Compounding Interest',
                subtitle: 'Simulasi pertumbuhan investasi bunga majemuk',
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildFormCard(),
                    if (_result != null) ...[
                      const SizedBox(height: 16),
                      _buildResultCard(),
                    ],
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Modal Awal'),
          const SizedBox(height: 8),
          _currencyField(_principalController, 'Contoh: 10.000.000'),
          const SizedBox(height: 16),
          _label('Setoran Bulanan'),
          const SizedBox(height: 8),
          _currencyField(_monthlyController, 'Contoh: 1.000.000'),
          const SizedBox(height: 16),
          _label('Bunga per Tahun: ${_annualRate.toStringAsFixed(1)}%'),
          Slider(
            value: _annualRate,
            min: 0,
            max: 30,
            divisions: 60,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _annualRate = v),
          ),
          const SizedBox(height: 8),
          _label('Durasi: ${_years.toStringAsFixed(0)} tahun'),
          Slider(
            value: _years,
            min: 1,
            max: 30,
            divisions: 29,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _years = v),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Hitung', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultHeader('Hasil Perhitungan', Icons.show_chart, Colors.green),
          const SizedBox(height: 16),
          _bigValue('Total Aset', _result!.totalAsset),
          const SizedBox(height: 16),
          _row('Modal Awal', Formatters.formatCurrency(_result!.principal)),
          _row('Total Setoran Bulanan', Formatters.formatCurrency(_result!.totalDeposit - _result!.principal)),
          _row('Total Deposit', Formatters.formatCurrency(_result!.totalDeposit)),
          const Divider(height: 24),
          _row('Total Bunga Didapat', Formatters.formatCurrency(_result!.totalInterest), highlight: true),
          const SizedBox(height: 12),
          _insight('Uang Anda tumbuh ${((_result!.totalAsset / _result!.totalDeposit - 1) * 100).toStringAsFixed(1)}% dari total deposit berkat bunga majemuk.'),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary));

  Widget _currencyField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ThousandFormatter()],
      decoration: InputDecoration(
        prefixText: 'Rp ',
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _resultHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _bigValue(String label, double value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
          const SizedBox(height: 4),
          Text(Formatters.formatCurrency(value), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: highlight ? AppColors.success : AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _insight(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.info))),
        ],
      ),
    );
  }
}

class _CompoundResult {
  final double totalAsset;
  final double totalDeposit;
  final double totalInterest;
  final double principal;
  final double monthlyDeposit;

  _CompoundResult({
    required this.totalAsset,
    required this.totalDeposit,
    required this.totalInterest,
    required this.principal,
    required this.monthlyDeposit,
  });
}

class _ThousandFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final number = int.tryParse(newValue.text.replaceAll('.', ''));
    if (number == null) return oldValue;
    final formatted = Formatters.formatNumber(number);
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
