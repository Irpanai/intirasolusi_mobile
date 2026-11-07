import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/utils/formatters.dart';

class BreakEvenScreen extends StatefulWidget {
  const BreakEvenScreen({super.key});

  @override
  State<BreakEvenScreen> createState() => _BreakEvenScreenState();
}

class _BreakEvenScreenState extends State<BreakEvenScreen> {
  final _fixedCostController = TextEditingController();
  final _variableCostController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  _BreakEvenResult? _result;

  @override
  void dispose() {
    _fixedCostController.dispose();
    _variableCostController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  void _calculate() {
    final fixedCost = double.tryParse(_fixedCostController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final variableCost = double.tryParse(_variableCostController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final sellingPrice = double.tryParse(_sellingPriceController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;

    if (fixedCost <= 0 || sellingPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan biaya tetap dan harga jual')));
      return;
    }

    if (sellingPrice <= variableCost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harga jual harus lebih besar dari biaya variabel')));
      return;
    }

    final contribution = sellingPrice - variableCost;
    final bepUnit = fixedCost / contribution;
    final bepRevenue = bepUnit * sellingPrice;
    final marginPercent = (contribution / sellingPrice) * 100;

    setState(() {
      _result = _BreakEvenResult(
        bepUnit: bepUnit,
        bepRevenue: bepRevenue,
        contributionMargin: contribution,
        marginPercent: marginPercent,
        fixedCost: fixedCost,
        variableCost: variableCost,
        sellingPrice: sellingPrice,
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
            GradientHeader(showBackButton: true, child: const GradientHeaderTitle(title: 'Break-Even Point', subtitle: 'Hitung titik impas penjualan bisnis')),
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
          _infoBox('Biaya Tetap', 'Biaya yang tidak berubah meski produksi naik/turun, seperti sewa tempat, gaji karyawan tetap, listrik minimum.'),
          const SizedBox(height: 12),
          _label('Biaya Tetap / Bulan'),
          const SizedBox(height: 8),
          _currencyField(_fixedCostController, 'Sewa, gaji, listrik, dll'),
          const SizedBox(height: 16),
          _infoBox('Biaya Variabel', 'Biaya per unit produk, seperti bahan baku, packaging, ongkos kirim per item.'),
          const SizedBox(height: 12),
          _label('Biaya Variabel / Unit'),
          const SizedBox(height: 8),
          _currencyField(_variableCostController, 'Modal per produk'),
          const SizedBox(height: 16),
          _label('Harga Jual / Unit'),
          const SizedBox(height: 8),
          _currencyField(_sellingPriceController, 'Harga jual ke pelanggan'),
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

  Widget _infoBox(String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.help_outline, size: 16, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
            Text(desc, style: TextStyle(fontSize: 11, color: Colors.blue.shade600)),
          ])),
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
          _resultHeader('Titik Impas (BEP)', Icons.balance, Colors.teal),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('BEP Unit', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${_result!.bepUnit.ceil()} unit', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                ])),
                Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('BEP Revenue', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(Formatters.formatCurrency(_result!.bepRevenue), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _row('Harga Jual / Unit', Formatters.formatCurrency(_result!.sellingPrice)),
          _row('Biaya Variabel / Unit', Formatters.formatCurrency(_result!.variableCost)),
          _row('Contribution Margin', Formatters.formatCurrency(_result!.contributionMargin)),
          _row('Margin %', '${_result!.marginPercent.toStringAsFixed(1)}%'),
          const SizedBox(height: 12),
          _insight('Anda harus menjual minimal ${_result!.bepUnit.ceil()} unit per bulan agar tidak merugi. Setiap unit di atas BEP menghasilkan laba ${Formatters.formatCurrency(_result!.contributionMargin)}.'),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary));
  Widget _currencyField(TextEditingController c, String hint) => TextField(controller: c, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ThousandFormatter()], decoration: InputDecoration(prefixText: 'Rp ', hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
  Widget _resultHeader(String title, IconData icon, Color color) => Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))]);
  Widget _row(String label, String value, {bool highlight = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: highlight ? AppColors.error : AppColors.textPrimary))]));
  Widget _insight(String text) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.info)))]));
}

class _BreakEvenResult {
  final double bepUnit, bepRevenue, contributionMargin, marginPercent, fixedCost, variableCost, sellingPrice;
  _BreakEvenResult({required this.bepUnit, required this.bepRevenue, required this.contributionMargin, required this.marginPercent, required this.fixedCost, required this.variableCost, required this.sellingPrice});
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
