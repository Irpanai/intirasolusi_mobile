import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/app_colors.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            Transform.translate(
              offset: const Offset(0, -24),
              child: _buildContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 14, bottom: 44, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF14532D), // Deep green 900
            Color(0xFF15803D), // Emerald 700
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Kembali',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            const Text(
              'Pusat Bantuan & FAQ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Temukan panduan, kontak CS, dan jawaban seputar gadai Intira',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Actions
          _buildQuickActions(context),
          const SizedBox(height: 20),

          // FAQ Section
          _buildFAQSection(),
          const SizedBox(height: 20),

          // Contact Support
          _buildContactSection(context),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionItem(
              icon: Icons.menu_book_outlined,
              label: 'Panduan',
              onTap: () => _showGuideDialog(context),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _buildQuickActionItem(
              icon: Icons.calculate_outlined,
              label: 'Kalkulator',
              onTap: () => Navigator.pushNamed(context, '/calculator'),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.shade200,
          ),
          Expanded(
            child: _buildQuickActionItem(
              icon: Icons.store_outlined,
              label: 'Cabang',
              onTap: () => Navigator.pushNamed(context, '/branches'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    final List<_FAQItem> faqItems = [
      _FAQItem(
        question: 'Bagaimana cara mengajukan gadai?',
        answer:
            '1. Buka menu "Ajukan Gadai" di halaman utama\n'
            '2. Pilih jenis barang yang ingin digadaikan\n'
            '3. Upload foto barang dengan jelas\n'
            '4. Isi data barang dan estimasi nilai\n'
            '5. Pilih cabang terdekat\n'
            '6. Kirim pengajuan dan tunggu konfirmasi',
      ),
      _FAQItem(
        question: 'Berapa lama proses pencairan dana?',
        answer:
            'Proses pencairan dana biasanya memakan waktu 15-30 menit setelah barang diperiksa dan disetujui di cabang. Pastikan data pengajuan lengkap dan barang dalam kondisi baik.',
      ),
      _FAQItem(
        question: 'Apa saja barang yang bisa digadaikan?',
        answer:
            'Barang yang dapat digadaikan meliputi:\n'
            '• Elektronik (HP, laptop, kamera, televisi)\n'
            '• Kendaraan bermotor\n'
            'Setiap cabang mungkin memiliki kebijakan berbeda, silakan hubungi cabang terdekat untuk informasi lebih lanjut.',
      ),
      _FAQItem(
        question: 'Bagaimana cara perpanjang gadai?',
        answer:
            '1. Buka menu "Transaksi" di aplikasi\n'
            '2. Pilih transaksi yang ingin diperpanjang\n'
            '3. Klik tombol "Perpanjang"\n'
            '4. Bayar biaya perpanjangan sesuai ketentuan\n'
            '5. Masa gadai akan diperpanjang otomatis',
      ),
      _FAQItem(
        question: 'Bagaimana cara tebus barang?',
        answer:
            '1. Buka menu "Transaksi" di aplikasi\n'
            '2. Pilih transaksi yang ingin ditebus\n'
            '3. Lihat total biaya tebus\n'
            '4. Kunjungi cabang untuk melakukan pembayaran\n'
            '5. Barang akan dikembalikan setelah pembayaran lunas',
      ),
      _FAQItem(
        question: 'Berapa bunga dan biaya administrasi?',
        answer:
            'Bunga gadai dihitung berdasarkan:\n'
            '• Jenis barang\n'
            '• Nilai pinjaman\n'
            '• Jangka waktu\n\n'
            'Gunakan fitur "Kalkulator" untuk simulasi biaya. Biaya administrasi dikenakan saat pengajuan awal.',
      ),
      _FAQItem(
        question: 'Apa yang terjadi jika lewat jatuh tempo?',
        answer:
            'Jika melewati jatuh tempo:\n'
            '• Akan ada biaya keterlambatan\n'
            '• Anda akan menerima notifikasi pengingat\n'
            '• Hubungi cabang untuk negosiasi perpanjangan\n'
            '• Jika tidak ditebus dalam waktu tertentu, barang dapat dilelang sesuai ketentuan',
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.quiz_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Pertanyaan Umum (FAQ)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
          ...faqItems.map((item) => _buildFAQTile(item)),
        ],
      ),
    );
  }

  Widget _buildFAQTile(_FAQItem item) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        title: Text(
          item.question,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textMuted,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.answer,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.support_agent, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Hubungi Kami',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Butuh bantuan lebih lanjut? Tim kami siap membantu Anda.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Contact Options - Phone & WhatsApp temporarily disabled
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.phone,
                  label: 'Telepon',
                  color: AppColors.textMuted, // Greyed out
                  onTap: () => _showComingSoonMessage(context, 'Telepon'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.chat,
                  label: 'WhatsApp',
                  color: AppColors.textMuted, // Greyed out
                  onTap: () => _showComingSoonMessage(context, 'WhatsApp'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildContactButton(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  color: Colors.blue,
                  onTap: () => _launchEmail('support@intirasolusi.com'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildContactButton(
                  icon: Icons.store_outlined,
                  label: 'Cabang',
                  color: Colors.orange,
                  onTap: () => Navigator.pushNamed(context, '/branches'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Jam Operasional: Senin - Sabtu, 08:00 - 17:00 WIB',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuideDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Panduan Penggunaan Aplikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Divider(height: 1, thickness: 0.5, color: Colors.grey.shade200),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGuideItem(
                      number: '1',
                      title: 'Daftar Akun',
                      description:
                          'Buat akun baru dengan mengisi data diri lengkap. Pastikan nomor HP dan email valid untuk verifikasi.',
                    ),
                    _buildGuideItem(
                      number: '2',
                      title: 'Lengkapi Profil',
                      description:
                          'Upload foto KTP dan selfie untuk verifikasi identitas. Data Anda aman dan terenkripsi.',
                    ),
                    _buildGuideItem(
                      number: '3',
                      title: 'Ajukan Gadai',
                      description:
                          'Pilih jenis barang, upload foto, dan isi detail. Ajukan ke cabang terdekat untuk proses cepat.',
                    ),
                    _buildGuideItem(
                      number: '4',
                      title: 'Kunjungi Cabang',
                      description:
                          'Bawa barang ke cabang untuk penilaian. Petugas akan memeriksa dan memberikan nilai pinjaman.',
                    ),
                    _buildGuideItem(
                      number: '5',
                      title: 'Terima Dana',
                      description:
                          'Setelah disetujui, dana akan dicairkan dalam 15-30 menit. Bisa transfer atau tunai.',
                    ),
                    _buildGuideItem(
                      number: '6',
                      title: 'Kelola Gadai',
                      description:
                          'Pantau status gadai, perpanjang sebelum jatuh tempo, atau tebus kapan saja melalui aplikasi.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 20,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Tip: Aktifkan notifikasi untuk menerima pengingat jatuh tempo dan promo menarik!',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem({
    required String number,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoonMessage(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur $feature akan segera tersedia'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ignore: unused_element
  Future<void> _launchPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // ignore: unused_element
  Future<void> _launchWhatsApp(String phone) async {
    final url = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _launchEmail(String email) async {
    final url = Uri.parse('mailto:$email?subject=Bantuan Aplikasi');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

class _FAQItem {
  final String question;
  final String answer;

  _FAQItem({required this.question, required this.answer});
}
