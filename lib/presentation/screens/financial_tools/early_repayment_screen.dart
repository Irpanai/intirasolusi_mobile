import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/utils/formatters.dart';

class EarlyRepaymentScreen extends StatefulWidget {
  const EarlyRepaymentScreen({super.key});

  @override
  State<EarlyRepaymentScreen> createState() => _EarlyRepaymentScreenState();
}

class _EarlyRepaymentScreenState extends State<EarlyRepaymentScreen> {
  final _principalController = TextEditingController();
  final _extraPayController = TextEditingController();
  double _interestRate = 10.0;
  double _remainingMonths = 60;
  _RepaymentResult? _result;

  @override
  void dispose() {
    _principalController.dispose();
    _extraPayController.dispose();
    super.dispose();
  }

  void _calculate() {
    final principal = double.tryParse(_principalController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final extraPay = double.tryParse(_extraPayController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    if (principal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan sisa pokok pinjaman')));
      return;
    }

    final monthlyRate = _interestRate / 100 / 12;
    final months = _remainingMonths.toInt();

    // Normal schedule
    double normalMonthly = 0;
    if (monthlyRate > 0) {
      normalMonthly = principal * monthlyRate * pow(1 + monthlyRate, months) / (pow(1 + monthlyRate, months) - 1);
    } else {
      normalMonthly = principal / months;
    }
    double normalTotalInterest = (normalMonthly * months) - principal;

    // With extra payment schedule
    double balance = principal;
    double totalInterestWithExtra = 0;
    int monthsWithExtra = 0;
    final newMonthly = normalMonthly + extraPay;

    while (balance > 0 && monthsWithExtra < months * 2) {
      final interestPortion = balance * monthlyRate;
      totalInterestWithExtra += interestPortion;
      final principalPortion = newMonthly - interestPortion;
      if (principalPortion <= 0) break;
      balance -= principalPortion;
      monthsWithExtra++;
      if (balance <= 0) break;
    }

    final interestSaved = normalTotalInterest - totalInterestWithExtra;
    final monthsSaved = months - monthsWithExtra;

    setState(() {
      _result = _RepaymentResult(
        normalMonthly: normalMonthly,
        newMonthly: newMonthly,
        normalTotalInterest: normalTotalInterest,
        newTotalInterest: totalInterestWithExtra,
        interestSaved: interestSaved > 0 ? interestSaved : 0,
        originalMonths: months,
        newMonths: monthsWithExtra,
        monthsSaved: monthsSaved > 0 ? monthsSaved : 0,
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
            GradientHeader(showBackButton: true, child: const GradientHeaderTitle(title: 'Pelunasan Dipercepat', subtitle: 'Simulasi penghematan bunga dengan bayar ekstra')),
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
          _label('Sisa Pokok Pinjaman'),
          const SizedBox(height: 8),
          _currencyField(_principalController, 'Sisa hutang pokok'),
          const SizedBox(height: 16),
          _label('Suku Bunga: ${_interestRate.toStringAsFixed(1)}% / tahun'),
          Slider(value: _interestRate, min: 1, max: 30, divisions: 58, activeColor: AppColors.primary, onChanged: (v) => setState(() => _interestRate = v)),
          const SizedBox(height: 8),
          _label('Sisa Tenor: ${_remainingMonths.toInt()} bulan'),
          Slider(value: _remainingMonths, min: 6, max: 360, divisions: 59, activeColor: AppColors.primary, onChanged: (v) => setState(() => _remainingMonths = v)),
          const SizedBox(height: 16),
          _label('Tambahan Bayar / Bulan'),
          const SizedBox(height: 8),
          _currencyField(_extraPayController, 'Jumlah bayar ekstra'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Simulasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final r = _result!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultHeader('Perbandingan', Icons.compare_arrows, Colors.indigo),
          const SizedBox(height: 16),
          // Comparison cards
          Row(children: [
            Expanded(child: _compCard('Normal', '${r.originalMonths} bulan', Formatters.formatCurrency(r.normalTotalInterest), Colors.grey)),
            const SizedBox(width: 12),
            Expanded(child: _compCard('Dipercepat', '${r.newMonths} bulan', Formatters.formatCurrency(r.newTotalInterest), AppColors.success)),
          ]),
          const SizedBox(height: 16),
          // Savings highlight
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.success, Colors.green.shade700]), borderRadius: BorderRadius.circular(16)),
            child: Column(children: [
              const Icon(Icons.savings, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              const Text('Total Penghematan', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 4),
              Text(Formatters.formatCurrency(r.interestSaved), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Lunas ${r.monthsSaved} bulan lebih cepat', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 16),
          _row('Cicilan Normal', '${Formatters.formatCurrency(r.normalMonthly)}/bln'),
          _row('Cicilan + Ekstra', '${Formatters.formatCurrency(r.newMonthly)}/bln'),
          _row('Bunga Normal', Formatters.formatCurrency(r.normalTotalInterest)),
          _row('Bunga Dipercepat', Formatters.formatCurrency(r.newTotalInterest)),
          const SizedBox(height: 12),
          _insight('Dengan membayar ekstra ${Formatters.formatCurrency(r.newMonthly - r.normalMonthly)}/bulan, Anda menghemat ${Formatters.formatCurrency(r.interestSaved)} bunga dan lunas ${r.monthsSaved} bulan lebih cepat.'),
        ],
      ),
    );
  }

  Widget _compCard(String title, String months, String interest, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(children: [
        Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        const SizedBox(height: 8),
        Text(months, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(interest, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        Text('total bunga', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ]),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary));
  Widget _currencyField(TextEditingController c, String hint) => TextField(controller: c, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ThousandFormatter()], decoration: InputDecoration(prefixText: 'Rp ', hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
  Widget _resultHeader(String title, IconData icon, Color color) => Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))]);
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))]));
  Widget _insight(String text) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.info)))]));
}

class _RepaymentResult {
  final double normalMonthly, newMonthly, normalTotalInterest, newTotalInterest, interestSaved;
  final int originalMonths, newMonths, monthsSaved;
  _RepaymentResult({required this.normalMonthly, required this.newMonthly, required this.normalTotalInterest, required this.newTotalInterest, required this.interestSaved, required this.originalMonths, required this.newMonths, required this.monthsSaved});
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
