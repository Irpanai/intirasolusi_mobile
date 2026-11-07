import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';

class RealYieldScreen extends StatefulWidget {
  const RealYieldScreen({super.key});

  @override
  State<RealYieldScreen> createState() => _RealYieldScreenState();
}

class _RealYieldScreenState extends State<RealYieldScreen> {
  double _nominalReturn = 10.0;
  double _inflation = 5.0;
  double _taxRate = 10.0;
  _RealYieldResult? _result;

  void _calculate() {
    final afterTax = _nominalReturn * (1 - _taxRate / 100);
    final realYield = afterTax - _inflation;

    setState(() {
      _result = _RealYieldResult(
        nominalReturn: _nominalReturn,
        afterTax: afterTax,
        inflation: _inflation,
        realYield: realYield,
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
            GradientHeader(showBackButton: true, child: const GradientHeaderTitle(title: 'Real Yield', subtitle: 'Keuntungan bersih setelah inflasi & pajak')),
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
          _label('Keuntungan Nominal: ${_nominalReturn.toStringAsFixed(1)}%'),
          Slider(value: _nominalReturn, min: 0, max: 50, divisions: 100, activeColor: AppColors.primary, onChanged: (v) => setState(() => _nominalReturn = v)),
          const SizedBox(height: 8),
          _label('Inflasi: ${_inflation.toStringAsFixed(1)}%'),
          Slider(value: _inflation, min: 0, max: 20, divisions: 40, activeColor: Colors.orange, onChanged: (v) => setState(() => _inflation = v)),
          const SizedBox(height: 8),
          _label('Pajak: ${_taxRate.toStringAsFixed(1)}%'),
          Slider(value: _taxRate, min: 0, max: 30, divisions: 60, activeColor: Colors.red, onChanged: (v) => setState(() => _taxRate = v)),
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
    final isPositive = _result!.realYield >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultHeader('Hasil Analisis', Icons.percent, Colors.purple),
          const SizedBox(height: 16),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isPositive ? [AppColors.success, Colors.green.shade700] : [AppColors.error, Colors.red.shade700]),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text('Real Yield', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
                const SizedBox(height: 8),
                Text('${_result!.realYield >= 0 ? '+' : ''}${_result!.realYield.toStringAsFixed(2)}%', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _row('Keuntungan Nominal', '${_result!.nominalReturn.toStringAsFixed(1)}%'),
          _row('Setelah Pajak', '${_result!.afterTax.toStringAsFixed(2)}%'),
          _row('Dikurangi Inflasi', '-${_result!.inflation.toStringAsFixed(1)}%'),
          const Divider(height: 24),
          _row('Real Yield', '${_result!.realYield >= 0 ? '+' : ''}${_result!.realYield.toStringAsFixed(2)}%', highlight: !isPositive),
          const SizedBox(height: 12),
          _insight(isPositive
              ? 'Investasi Anda menghasilkan keuntungan nyata setelah memperhitungkan pajak dan inflasi.'
              : 'Keuntungan Anda kalah oleh inflasi! Pertimbangkan instrumen investasi dengan return lebih tinggi.'),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary));
  Widget _resultHeader(String title, IconData icon, Color color) => Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)), const SizedBox(width: 12), Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))]);
  Widget _row(String label, String value, {bool highlight = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)), Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: highlight ? AppColors.error : AppColors.textPrimary))]));
  Widget _insight(String text) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18), const SizedBox(width: 8), Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.info)))]));
}

class _RealYieldResult {
  final double nominalReturn, afterTax, inflation, realYield;
  _RealYieldResult({required this.nominalReturn, required this.afterTax, required this.inflation, required this.realYield});
}
