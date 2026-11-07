import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/utils/formatters.dart';

class FireCalculatorScreen extends StatefulWidget {
  const FireCalculatorScreen({super.key});

  @override
  State<FireCalculatorScreen> createState() => _FireCalculatorScreenState();
}

class _FireCalculatorScreenState extends State<FireCalculatorScreen> {
  final _expenseController = TextEditingController();
  final _savingsController = TextEditingController();
  final _monthlyInvestController = TextEditingController();
  double _withdrawalRate = 4.0;
  double _returnRate = 8.0;
  int _currentAge = 30;
  _FireResult? _result;

  @override
  void dispose() {
    _expenseController.dispose();
    _savingsController.dispose();
    _monthlyInvestController.dispose();
    super.dispose();
  }

  void _calculate() {
    final annualExpense = (double.tryParse(_expenseController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0) * 12;
    if (annualExpense <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan pengeluaran bulanan')));
      return;
    }

    final currentSavings = double.tryParse(_savingsController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final monthlyInvest = double.tryParse(_monthlyInvestController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final fireTarget = annualExpense / (_withdrawalRate / 100);
    final gap = fireTarget - currentSavings;

    int yearsToFire = 0;
    if (gap > 0 && monthlyInvest > 0) {
      double accumulated = currentSavings;
      final monthlyReturn = _returnRate / 100 / 12;
      while (accumulated < fireTarget && yearsToFire < 100) {
        for (int m = 0; m < 12; m++) {
          accumulated = accumulated * (1 + monthlyReturn) + monthlyInvest;
        }
        yearsToFire++;
      }
    }

    setState(() {
      _result = _FireResult(
        fireTarget: fireTarget,
        annualExpense: annualExpense,
        currentSavings: currentSavings,
        gap: gap > 0 ? gap : 0,
        yearsToFire: yearsToFire,
        retireAge: _currentAge + yearsToFire,
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
            GradientHeader(showBackButton: true, child: const GradientHeaderTitle(title: 'FIRE Calculator', subtitle: 'Financial Independence, Retire Early')),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(children: [_buildFormCard(), if (_result != null) ...[const SizedBox(height: 16), _buildResultCard()]]),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Pengeluaran Bulanan'),
          const SizedBox(height: 8),
          _currencyField(_expenseController, 'Total pengeluaran per bulan'),
          const SizedBox(height: 16),
          _label('Aset/Investasi Saat Ini'),
          const SizedBox(height: 8),
          _currencyField(_savingsController, 'Total aset produktif'),
          const SizedBox(height: 16),
          _label('Investasi Bulanan'),
          const SizedBox(height: 8),
          _currencyField(_monthlyInvestController, 'Yang diinvestasikan per bulan'),
          const SizedBox(height: 16),
          _label('Usia Saat Ini: $_currentAge tahun'),
          Slider(value: _currentAge.toDouble(), min: 18, max: 65, divisions: 47, activeColor: AppColors.primary, onChanged: (v) => setState(() => _currentAge = v.toInt())),
          _label('Withdrawal Rate: ${_withdrawalRate.toStringAsFixed(1)}%'),
          Slider(value: _withdrawalRate, min: 2, max: 8, divisions: 12, activeColor: AppColors.primary, onChanged: (v) => setState(() => _withdrawalRate = v)),
          _label('Expected Return: ${_returnRate.toStringAsFixed(1)}%/tahun'),
          Slider(value: _returnRate, min: 0, max: 20, divisions: 40, activeColor: AppColors.primary, onChanged: (v) => setState(() => _returnRate = v)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultHeader('Target FIRE', Icons.beach_access, Colors.orange),
          const SizedBox(height: 16),
          _bigValue('Angka Bebas Finansial', _result!.fireTarget),
          const SizedBox(height: 16),
          _row('Pengeluaran Tahunan', Formatters.formatCurrency(_result!.annualExpense)),
          _row('Aset Saat Ini', Formatters.formatCurrency(_result!.currentSavings)),
          _row('Kekurangan', Formatters.formatCurrency(_result!.gap)),
          const Divider(height: 24),
          if (_result!.yearsToFire > 0 && _result!.yearsToFire < 100) ...[
            _row('Waktu Menuju FIRE', '${_result!.yearsToFire} tahun'),
            _row('Usia Pensiun', '${_result!.retireAge} tahun'),
          ],
          const SizedBox(height: 12),
          _insight(_result!.gap <= 0
              ? 'Selamat! Anda sudah mencapai angka FIRE. Anda sudah bisa hidup dari hasil investasi.'
              : _result!.yearsToFire >= 100
                  ? 'Dengan investasi bulanan saat ini, target sulit tercapai. Tingkatkan investasi bulanan Anda.'
                  : 'Dengan konsistensi investasi, Anda bisa pensiun dini di usia ${_result!.retireAge} tahun.'),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary));
  Widget _currencyField(TextEditingController c, String hint) => TextField(controller: c, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ThousandFormatter()], decoration: InputDecoration(prefixText: 'Rp ', hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
  Widget _resultHeader(String title, IconData icon, Color color) => Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))]);
  Widget _bigValue(String label, double value) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)), const SizedBox(height: 4), Text(Formatters.formatCurrency(value), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))]));
  Widget _row(String label, String value, {bool highlight = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: highlight ? AppColors.error : AppColors.textPrimary))]));
  Widget _insight(String text) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.info)))]));
}

class _FireResult {
  final double fireTarget, annualExpense, currentSavings, gap;
  final int yearsToFire, retireAge;
  _FireResult({required this.fireTarget, required this.annualExpense, required this.currentSavings, required this.gap, required this.yearsToFire, required this.retireAge});
}

class _ThousandFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final n = int.tryParse(newValue.text.replaceAll('.', ''));
    if (n == null) return oldValue;
    final f = Formatters.formatNumber(n);
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}
