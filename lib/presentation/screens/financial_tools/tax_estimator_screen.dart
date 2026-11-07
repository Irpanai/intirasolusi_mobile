import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/utils/formatters.dart';

class TaxEstimatorScreen extends StatefulWidget {
  const TaxEstimatorScreen({super.key});

  @override
  State<TaxEstimatorScreen> createState() => _TaxEstimatorScreenState();
}

class _TaxEstimatorScreenState extends State<TaxEstimatorScreen> {
  final _invoiceController = TextEditingController();
  String _taxType = 'pph23_jasa';
  _TaxResult? _result;

  final _taxTypes = {
    'pph23_jasa': {'label': 'PPh 23 - Jasa (2%)', 'rate': 2.0},
    'pph23_sewa': {'label': 'PPh 23 - Sewa (2%)', 'rate': 2.0},
    'pph21': {'label': 'PPh 21 - Honor (2.5%)', 'rate': 2.5},
    'umkm': {'label': 'PPh Final UMKM (0.5%)', 'rate': 0.5},
    'pph4_2': {'label': 'PPh 4(2) - Konstruksi (3%)', 'rate': 3.0},
  };

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

    final ppnRate = 11.0;
    final pphRate = (_taxTypes[_taxType]!['rate'] as double?) ?? 2.0;

    final ppn = invoice * ppnRate / 100;
    final dpp = invoice; // Dasar Pengenaan Pajak
    final pph = dpp * pphRate / 100;
    final totalInvoice = invoice + ppn;
    final netReceived = totalInvoice - pph;

    setState(() {
      _result = _TaxResult(
        invoiceValue: invoice,
        ppn: ppn,
        ppnRate: ppnRate,
        pph: pph,
        pphRate: pphRate,
        totalInvoice: totalInvoice,
        netReceived: netReceived,
        dpp: dpp,
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
            GradientHeader(showBackButton: true, child: const GradientHeaderTitle(title: 'Estimator Pajak', subtitle: 'Hitung PPN, PPh & nominal bersih invoice')),
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
          _label('Nilai Invoice (sebelum PPN)'),
          const SizedBox(height: 8),
          _currencyField(_invoiceController, 'Nilai kontrak/invoice'),
          const SizedBox(height: 16),
          _label('Jenis Pajak Penghasilan'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonFormField<String>(
              value: _taxType,
              isExpanded: true,
              decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
              items: _taxTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value['label'] as String, style: const TextStyle(fontSize: 14)))).toList(),
              onChanged: (v) => setState(() => _taxType = v!),
            ),
          ),
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
          _resultHeader('Rincian Pajak', Icons.receipt_long, Colors.red),
          const SizedBox(height: 16),
          _bigValue('Yang Diterima Bersih', _result!.netReceived),
          const SizedBox(height: 16),
          _row('Nilai Invoice (DPP)', Formatters.formatCurrency(_result!.invoiceValue)),
          _row('PPN (${_result!.ppnRate.toStringAsFixed(0)}%)', '+ ${Formatters.formatCurrency(_result!.ppn)}'),
          _row('Total Invoice + PPN', Formatters.formatCurrency(_result!.totalInvoice)),
          const Divider(height: 24),
          _row('PPh (${_result!.pphRate.toStringAsFixed(1)}%)', '- ${Formatters.formatCurrency(_result!.pph)}', highlight: true),
          _row('Diterima Bersih', Formatters.formatCurrency(_result!.netReceived)),
          const SizedBox(height: 12),
          _insight('Dari total invoice ${Formatters.formatCurrency(_result!.totalInvoice)}, Anda menerima ${Formatters.formatCurrency(_result!.netReceived)} setelah dipotong pajak.'),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary));
  Widget _currencyField(TextEditingController c, String hint) => TextField(controller: c, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ThousandFormatter()], decoration: InputDecoration(prefixText: 'Rp ', hintText: hint, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)));
  Widget _resultHeader(String title, IconData icon, Color color) => Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))]);
  Widget _bigValue(String label, double value) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(16)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)), const SizedBox(height: 4), Text(Formatters.formatCurrency(value), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))]));
  Widget _row(String label, String value, {bool highlight = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Flexible(child: Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary))), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: highlight ? AppColors.error : AppColors.textPrimary))]));
  Widget _insight(String text) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.info)))]));
}

class _TaxResult {
  final double invoiceValue, ppn, ppnRate, pph, pphRate, totalInvoice, netReceived, dpp;
  _TaxResult({required this.invoiceValue, required this.ppn, required this.ppnRate, required this.pph, required this.pphRate, required this.totalInvoice, required this.netReceived, required this.dpp});
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
