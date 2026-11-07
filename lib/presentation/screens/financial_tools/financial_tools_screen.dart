import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';

class FinancialToolsScreen extends StatelessWidget {
  const FinancialToolsScreen({super.key});

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
                title: 'Tool Keuangan',
                subtitle: 'Kumpulan kalkulator & analisis keuangan',
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      context,
                      title: 'Investasi & Perencanaan',
                      icon: Icons.trending_up,
                      tools: [
                        _ToolItem(
                          icon: Icons.show_chart,
                          color: Colors.green,
                          title: 'Compounding Interest',
                          subtitle: 'Hitung pertumbuhan investasi dengan bunga majemuk',
                          route: '/financial-tools/compounding-interest',
                        ),
                        _ToolItem(
                          icon: Icons.shield_outlined,
                          color: Colors.blue,
                          title: 'Dana Darurat',
                          subtitle: 'Hitung kebutuhan dana darurat ideal Anda',
                          route: '/financial-tools/emergency-fund',
                        ),
                        _ToolItem(
                          icon: Icons.beach_access,
                          color: Colors.orange,
                          title: 'FIRE Calculator',
                          subtitle: 'Simulasi kebebasan finansial & pensiun dini',
                          route: '/financial-tools/fire-calculator',
                        ),
                        _ToolItem(
                          icon: Icons.percent,
                          color: Colors.purple,
                          title: 'Real Yield',
                          subtitle: 'Hitung keuntungan bersih setelah inflasi & pajak',
                          route: '/financial-tools/real-yield',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      title: 'Keputusan Bisnis',
                      icon: Icons.business_center,
                      tools: [
                        _ToolItem(
                          icon: Icons.balance,
                          color: Colors.teal,
                          title: 'Break-Even Point',
                          subtitle: 'Hitung titik impas penjualan bisnis Anda',
                          route: '/financial-tools/break-even',
                        ),
                        _ToolItem(
                          icon: Icons.receipt_long,
                          color: Colors.red,
                          title: 'Estimator Pajak',
                          subtitle: 'Hitung PPN, PPh & nominal bersih invoice',
                          route: '/financial-tools/tax-estimator',
                        ),
                        _ToolItem(
                          icon: Icons.speed,
                          color: Colors.indigo,
                          title: 'Early Payment',
                          subtitle: 'Analisis untung-rugi bayar invoice lebih awal',
                          route: '/financial-tools/early-payment',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSection(
                      context,
                      title: 'Analisis Kredit',
                      icon: Icons.account_balance,
                      tools: [
                        _ToolItem(
                          icon: Icons.pie_chart,
                          color: Colors.amber.shade700,
                          title: 'DSR Calculator',
                          subtitle: 'Cek rasio utang terhadap pendapatan Anda',
                          route: '/financial-tools/dsr-calculator',
                        ),
                        _ToolItem(
                          icon: Icons.rocket_launch,
                          color: Colors.deepPurple,
                          title: 'Pelunasan Dipercepat',
                          subtitle: 'Simulasi hemat bunga dengan pelunasan lebih awal',
                          route: '/financial-tools/early-repayment',
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {
    required String title,
    required IconData icon,
    required List<_ToolItem> tools,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ...tools.map((tool) => _buildToolTile(context, tool)),
        ],
      ),
    );
  }

  Widget _buildToolTile(BuildContext context, _ToolItem tool) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, tool.route),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tool.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tool.icon, color: tool.color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tool.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

class _ToolItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String route;

  const _ToolItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.route,
  });
}
