import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/utils/formatters.dart';

class EarlyPaymentScreen extends StatefulWidget {
  const EarlyPaymentScreen({super.key});

  @override
  State<EarlyPaymentScreen> createState() => _EarlyPaymentScreenState();
}

class _EarlyPaymentScreenState extends State<EarlyPaymentScreen> {
  final _invoiceController = TextEditingController();
  double _discountPercent = 2.0;
  double _daysRemaining = 30;
  double _loanInterestRate = 12.0;
  _EarlyPaymentResult? _result;

  @override
  void dispose() {
    _invoiceController.dispose();
    super.dispose();
  }

  void _calculate() {
    final invoice = double.tryParse(_invoiceController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    if (invoice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan nilai invoice')));
      return;
    }

    final discountAmount = invoice * _discountPercent / 100;
    final earlyPayAmount = invoice - discountAmount;
    final annualizedDiscount = (_discountPercent / _daysRemaining) * 365;
    final loanCost = invoice * (_loanInterestRate / 100) * (_daysRemaining / 365);
    final shouldTakeDiscount = annualizedDiscount > _loanInterestRate;
    final savings = shouldTakeDiscount ? (loanCost - discountAmount) : 0.0;

    setState(() {
      _result = _EarlyPaymentResult(
        invoiceValue: invoice,
        discountAmount: discountAmount,
        earlyPayAmount: earlyPayAmount,
        annualizedDiscount: annualizedDiscount,
        loanCost: loanCost,
        shouldTakeDiscount: shouldTakeDiscount,
        savings: savings.abs(),
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
            GradientHeader(showBackButton: true, child: const GradientHeaderTitle(title: 'Early Payment', subtitle: 'Analisis untung-rugi bayar invoice lebih awal')),
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
          _label('Nilai Invoice'),
          const SizedBox(height: 8),
          _currencyField(_invoiceController, 'Nilai tagihan'),
          const SizedBox(height: 16),
          _label('Diskon Early Payment: ${_discountPercent.toStringAsFixed(1)}%'),
          Slider(value: _discountPercent, min: 0.5, max: 10, divisions: 19, activeColor: AppColors.primary, onChanged: (v) => setState(() => _discountPercent = v)),
          const SizedBox(height: 8),
          _label('Sisa Hari Jatuh Tempo: ${_daysRemaining.toInt()} hari'),
          Slider(value: _daysRemaining, min: 5, max: 90, divisions: 17, activeColor: AppColors.primary, onChanged: (v) => setState(() => _daysRemaining = v)),
          const SizedBox(height: 8),
          _label('Bunga Pinjaman Modal Kerja: ${_loanInterestRate.toStringAsFixed(1)}%/tahun'),
          Slider(value: _loanInterestRate, min: 1, max: 30, divisions: 58, activeColor: Colors.orange, onChanged: (v) => setState(() => _loanInterestRate = v)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Analisis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final take = _result!.shouldTakeDiscount;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultHeader('Rekomendasi', Icons.speed, Colors.indigo),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: take ? [AppColors.success, Colors.green.shade700] : [Colors.orange, Colors.orange.shade700]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(children: [
              Icon(take ? Icons.check_circle : Icons.timer, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(take ? 'AMBIL DISKON' : 'TUNGGU JATUH TEMPO', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(take ? 'Bayar lebih awal lebih menguntungkan' : 'Menunggu jatuh tempo lebih hemat', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
            ]),
          ),
          const SizedBox(height: 16),
          _row('Nilai Invoice', Formatters.formatCurrency(_result!.invoiceValue)),
          _row('Diskon Early Payment', '- ${Formatters.formatCurrency(_result!.discountAmount)}'),
          _row('Bayar Sekarang', Formatters.formatCurrency(_result!.earlyPayAmount)),
          const Divider(height: 24),
          _row('Annualized Discount Rate', '${_result!.annualizedDiscount.toStringAsFixed(1)}%'),
          _row('Biaya Pinjaman (jika menunggu)', Formatters.formatCurrency(_result!.loanCost)),
          if (_result!.savings > 0) _row('Penghematan', Formatters.formatCurrency(_result!.savings), highlight: false),
          const SizedBox(height: 12),
          _insight(take
              ? 'Annualized discount rate (${_result!.annualizedDiscount.toStringAsFixed(1)}%) lebih tinggi dari bunga pinjaman. Lebih baik bayar sekarang.'
              : 'Bunga pinjaman lebih rendah dari diskon yang ditawarkan. Lebih baik simpan uang dan bayar saat jatuh tempo.'),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary));
  Widget _currencyField(TextEditingController c, String hint) => TextField(controller: c, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ThousandFormatter()], decoration: InputDecoration(prefixText: 'Rp ', hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
  Widget _resultHeader(String title, IconData icon, Color color) => Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))]);
  Widget _row(String label, String value, {bool highlight = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: highlight ? AppColors.error : AppColors.textPrimary))]));
  Widget _insight(String text) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.info)))]));
}

class _EarlyPaymentResult {
  final double invoiceValue, discountAmount, earlyPayAmount, annualizedDiscount, loanCost, savings;
  final bool shouldTakeDiscount;
  _EarlyPaymentResult({required this.invoiceValue, required this.discountAmount, required this.earlyPayAmount, required this.annualizedDiscount, required this.loanCost, required this.shouldTakeDiscount, required this.savings});
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
