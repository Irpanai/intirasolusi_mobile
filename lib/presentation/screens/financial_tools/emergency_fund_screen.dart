import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/utils/formatters.dart';

class EmergencyFundScreen extends StatefulWidget {
  const EmergencyFundScreen({super.key});

  @override
  State<EmergencyFundScreen> createState() => _EmergencyFundScreenState();
}

class _EmergencyFundScreenState extends State<EmergencyFundScreen> {
  final _expenseController = TextEditingController();
  final _savingsController = TextEditingController();
  String _status = 'single';
  _EmergencyResult? _result;

  @override
  void dispose() {
    _expenseController.dispose();
    _savingsController.dispose();
    super.dispose();
  }

  void _calculate() {
    final expense = double.tryParse(_expenseController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    if (expense <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan pengeluaran bulanan')));
      return;
    }

    final savings = double.tryParse(_savingsController.text.replaceAll(RegExp(r'[^\d]'), '')) ?? 0;
    final multiplier = _status == 'single' ? 6 : (_status == 'married' ? 9 : 12);
    final target = expense * multiplier;
    final gap = target - savings;

    setState(() {
      _result = _EmergencyResult(
        target: target,
        currentSavings: savings,
        gap: gap > 0 ? gap : 0,
        multiplier: multiplier,
        monthlyExpense: expense,
        monthsToSave: gap > 0 && expense > 0 ? (gap / (expense * 0.2)).ceil() : 0,
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
              child: const GradientHeaderTitle(title: 'Dana Darurat', subtitle: 'Hitung kebutuhan dana darurat ideal'),
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildFormCard(),
                    if (_result != null) ...[const SizedBox(height: 16), _buildResultCard()],
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Pengeluaran Bulanan'),
          const SizedBox(height: 8),
          _currencyField(_expenseController, 'Total pengeluaran per bulan'),
          const SizedBox(height: 16),
          _label('Tabungan/Investasi Saat Ini'),
          const SizedBox(height: 8),
          _currencyField(_savingsController, 'Dana yang sudah terkumpul'),
          const SizedBox(height: 16),
          _label('Status'),
          const SizedBox(height: 8),
          Row(
            children: [
              _statusChip('single', 'Single', Icons.person),
              const SizedBox(width: 8),
              _statusChip('married', 'Menikah', Icons.people),
              const SizedBox(width: 8),
              _statusChip('family', 'Berkeluarga', Icons.family_restroom),
            ],
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

  Widget _statusChip(String value, String label, IconData icon) {
    final selected = _status == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _status = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? AppColors.primary : Colors.grey.shade300, width: selected ? 2 : 1),
            borderRadius: BorderRadius.circular(10),
            color: selected ? AppColors.primary.withValues(alpha: 0.05) : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.primary : Colors.grey, size: 20),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w600 : FontWeight.normal, color: selected ? AppColors.primary : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final percentage = _result!.currentSavings / _result!.target * 100;
    final clampedPct = percentage.clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resultHeader('Hasil Analisis', Icons.shield_outlined, Colors.blue),
          const SizedBox(height: 16),
          _bigValue('Target Dana Darurat (${_result!.multiplier}x pengeluaran)', _result!.target),
          const SizedBox(height: 16),
          _label('Progress'),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: clampedPct / 100, minHeight: 12, backgroundColor: Colors.grey.shade200, color: clampedPct >= 100 ? AppColors.success : AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text('${clampedPct.toStringAsFixed(1)}% tercapai', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _row('Dana Saat Ini', Formatters.formatCurrency(_result!.currentSavings)),
          _row('Kekurangan', Formatters.formatCurrency(_result!.gap), highlight: _result!.gap > 0),
          if (_result!.monthsToSave > 0)
            _row('Estimasi Waktu (tabung 20%/bln)', '${_result!.monthsToSave} bulan'),
          const SizedBox(height: 12),
          _insight(_result!.gap <= 0
              ? 'Selamat! Dana darurat Anda sudah mencukupi.'
              : 'Sisihkan 20% dari pengeluaran bulanan (${Formatters.formatCurrency(_result!.monthlyExpense * 0.2)}) untuk mencapai target.'),
        ],
      ),
    );
  }

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary));

  Widget _currencyField(TextEditingController c, String hint) => TextField(
    controller: c,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ThousandFormatter()],
    decoration: InputDecoration(
      prefixText: 'Rp ', hintText: hint,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );

  Widget _resultHeader(String title, IconData icon, Color color) => Row(children: [
    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
    const SizedBox(width: 12),
    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
  ]);

  Widget _bigValue(String label, double value) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]), borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
      const SizedBox(height: 4),
      Text(Formatters.formatCurrency(value), style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
    ]),
  );

  Widget _row(String label, String value, {bool highlight = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: highlight ? AppColors.error : AppColors.textPrimary)),
    ]),
  );

  Widget _insight(String text) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.info.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(Icons.lightbulb_outline, color: AppColors.info, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: TextStyle(fontSize: 12, color: AppColors.info))),
    ]),
  );
}

class _EmergencyResult {
  final double target, currentSavings, gap, monthlyExpense;
  final int multiplier, monthsToSave;
  _EmergencyResult({required this.target, required this.currentSavings, required this.gap, required this.multiplier, required this.monthlyExpense, required this.monthsToSave});
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
