import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/utils/formatters.dart';

class DsrCalculatorScreen extends StatefulWidget {
  const DsrCalculatorScreen({super.key});

  @override
  State<DsrCalculatorScreen> createState() => _DsrCalculatorScreenState();
}

class _DsrCalculatorScreenState extends State<DsrCalculatorScreen> {
  final _incomeController = TextEditingController();
  final _debtController = TextEditingController();
  _DsrResult? _result;

  @override
  void dispose() {
    _incomeController.dispose();
    _debtController.dispose();
    super.dispose();
  }

  void _calculate() {
    final income = double.tryParse(_incomeController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final debt = double.tryParse(_debtController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    if (income <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan pendapatan bersih')));
      return;
    }

    final dsr = (debt / income) * 100;
    String status;
    Color statusColor;
    String advice;
    if (dsr < 30) {
      status = 'Aman';
      statusColor = AppColors.success;
      advice = 'Rasio utang Anda sehat. Anda masih memiliki ruang untuk mengambil pinjaman tambahan jika diperlukan.';
    } else if (dsr < 40) {
      status = 'Hati-hati';
      statusColor = Colors.orange;
      advice = 'Rasio utang mulai tinggi. Pertimbangkan untuk tidak menambah cicilan baru dan fokus melunasi yang ada.';
    } else if (dsr < 50) {
      status = 'Berisiko';
      statusColor = AppColors.error;
      advice = 'Rasio utang Anda tinggi. Cari cara untuk mengurangi cicilan, misalnya refinancing atau pelunasan dipercepat.';
    } else {
      status = 'Berbahaya';
      statusColor = AppColors.error;
      advice = 'Lebih dari separuh pendapatan Anda untuk cicilan. Segera konsultasi dengan perencana keuangan.';
    }

    final maxRecommended = income * 0.30;
    final availableCapacity = maxRecommended - debt;

    setState(() {
      _result = _DsrResult(income: income, debt: debt, dsr: dsr, status: status, statusColor: statusColor, advice: advice, maxRecommended: maxRecommended, availableCapacity: availableCapacity > 0 ? availableCapacity : 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            GradientHeader(showBackButton: true, child: const GradientHeaderTitle(title: 'Debt Service Ratio', subtitle: 'Cek kesehatan rasio utang terhadap pendapatan')),
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
          _label('Pendapatan Bersih / Bulan'),
          const SizedBox(height: 8),
          _currencyField(_incomeController, 'Gaji + penghasilan lain'),
          const SizedBox(height: 16),
          _label('Total Cicilan / Bulan'),
          const SizedBox(height: 8),
          _currencyField(_debtController, 'KPR + KTA + Kartu Kredit + dll'),
          const SizedBox(height: 12),
          _info('Masukkan SEMUA cicilan termasuk KPR, kredit mobil, KTA, kartu kredit minimum, dan cicilan lainnya.'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _calculate,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Hitung DSR', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
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
          _resultHeader('Hasil Analisis DSR', Icons.analytics, Colors.indigo),
          const SizedBox(height: 20),
          // DSR Gauge
          Center(
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 140, height: 140,
                      child: CircularProgressIndicator(
                        value: (r.dsr / 100).clamp(0, 1),
                        strokeWidth: 14,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(r.statusColor),
                      ),
                    ),
                    Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('${r.dsr.toStringAsFixed(1)}%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: r.statusColor)),
                      Text('DSR', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ]),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(color: r.statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text(r.status, style: TextStyle(color: r.statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Scale indicator
          _buildScaleBar(),
          const SizedBox(height: 16),
          _row('Pendapatan Bersih', Formatters.formatCurrency(r.income)),
          _row('Total Cicilan', Formatters.formatCurrency(r.debt)),
          _row('Batas Aman (30%)', Formatters.formatCurrency(r.maxRecommended)),
          _row('Kapasitas Cicilan Tersisa', Formatters.formatCurrency(r.availableCapacity)),
          const SizedBox(height: 12),
          _insight(r.advice),
        ],
      ),
    );
  }

  Widget _buildScaleBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(children: [
            Expanded(flex: 30, child: Container(height: 8, color: AppColors.success)),
            Expanded(flex: 10, child: Container(height: 8, color: Colors.orange)),
            Expanded(flex: 10, child: Container(height: 8, color: AppColors.error)),
            Expanded(flex: 50, child: Container(height: 8, color: AppColors.error.withValues(alpha: 0.5))),
          ]),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0%', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text('30%', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text('40%', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            Text('50%+', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary));
  Widget _currencyField(TextEditingController c, String hint) => TextField(controller: c, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ThousandFormatter()], decoration: InputDecoration(prefixText: 'Rp ', hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
  Widget _resultHeader(String title, IconData icon, Color color) => Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))]);
  Widget _row(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary))]));
  Widget _info(String text) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.info_outline, color: Colors.blue, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: Colors.blue.shade700)))]));
  Widget _insight(String text) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.info)))]));
}

class _DsrResult {
  final double income, debt, dsr, maxRecommended, availableCapacity;
  final String status, advice;
  final Color statusColor;
  _DsrResult({required this.income, required this.debt, required this.dsr, required this.status, required this.statusColor, required this.advice, required this.maxRecommended, required this.availableCapacity});
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
