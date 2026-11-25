import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/theme/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _privacyWebUrl = 'https://gadaiintira.com/privacy';

  Future<void> _openWebPrivacy(BuildContext context) async {
    final uri = Uri.parse(_privacyWebUrl);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka tautan kebijakan privasi')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    icon: Icons.security_outlined,
                    title: '1. Pendahuluan',
                    children: [
                      const Text(
                        'GASPOL by INTIRA ("Aplikasi", "kami") adalah aplikasi layanan gadai digital yang dikelola dan dioperasikan oleh PT. Gadai Intira Nusantara. Kebijakan Privasi ini menjelaskan bagaimana kami mengumpulkan, menggunakan, menyimpan, dan melindungi data pribadi Anda saat menggunakan aplikasi mobile maupun layanan web kami.',
                        style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.55),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    icon: Icons.perm_device_information_outlined,
                    title: '2. Data & Izin Perangkat yang Dikumpulkan',
                    children: [
                      _buildBulletItem(
                        'Kamera & Gambar',
                        'Digunakan secara langsung untuk memindai e-KTP, melakukan swafoto (selfie) verifikasi wajah saat pendaftaran, serta mengambil foto barang agunan saat pengajuan gadai. Aplikasi tidak merekam suara maupun mengambil gambar di latar belakang.',
                      ),
                      _buildBulletItem(
                        'Lokasi Perangkat',
                        'Mengakses lokasi perangkat saat Anda menggunakan fitur cabang untuk membantu menemukan kantor cabang PT. Gadai Intira Nusantara terdekat.',
                      ),
                      _buildBulletItem(
                        'Data Identitas Pribadi',
                        'Data KTP (Nama Lengkap, NIK, Alamat), Nomor Telepon, Email, Pekerjaan, dan Kontak Darurat untuk keperluan verifikasi nasabah (KYC) dan penerbitan Surat Bukti Gadai (SBG).',
                      ),
                      _buildBulletItem(
                        'Autentikasi Biometrik Lokal',
                        'Fitur login sidik jari/wajah menggunakan sistem keamanan bawaan perangkat Anda. Kami tidak pernah menyimpan data biometrik Anda di server.',
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    icon: Icons.lock_outline_rounded,
                    title: '3. Pemrosesan & Keamanan Data',
                    children: [
                      _buildBulletItem(
                        'Pemrosesan Lokal',
                        'Pemindaian teks e-KTP dan deteksi wajah diproses secara lokal di perangkat sebelum Anda meninjau dan mengirimkannya.',
                      ),
                      _buildBulletItem(
                        'Enkripsi Transmisi',
                        'Seluruh komunikasi antara aplikasi dan server menggunakan protokol terenkripsi HTTPS/TLS.',
                      ),
                      _buildBulletItem(
                        'Penyimpanan Token Aman',
                        'Token sesi login disimpan dalam penyimpanan aman terenkripsi pada perangkat Anda.',
                        isLast: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    icon: Icons.share_outlined,
                    title: '4. Pembagian & Pengungkapan Data',
                    children: [
                      const Text(
                        'Kami tidak pernah menjual, menyewakan, atau memperdagangkan data pribadi Anda kepada pihak ketiga. Informasi hanya digunakan oleh tim resmi PT. Gadai Intira Nusantara untuk pemrosesan layanan gadai dan instansi berwenang apabila diwajibkan oleh hukum yang berlaku di Indonesia.',
                        style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.55),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    icon: Icons.delete_outline_rounded,
                    title: '5. Retensi & Penghapusan Akun',
                    children: [
                      const Text(
                        'Anda berhak mengakses, memperbarui, atau mengajukan penghapusan akun dan data pribadi Anda selama tidak memiliki transaksi gadai aktif yang masih berjalan. Permintaan penghapusan akun dapat dikirimkan ke email sejahterasolusiintira@gmail.com atau WhatsApp Layanan Pelanggan di 082154031958, dan akan diproses maksimal dalam 7 hari kerja.',
                        style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.55),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildSectionCard(
                    icon: Icons.support_agent_outlined,
                    title: '6. Hubungi Kami',
                    children: [
                      _buildInfoRow('Perusahaan', 'PT. Gadai Intira Nusantara'),
                      _buildInfoRow('Aplikasi', 'GASPOL by INTIRA'),
                      _buildInfoRow('Email', 'sejahterasolusiintira@gmail.com'),
                      _buildInfoRow('WhatsApp', '082154031958'),
                      _buildInfoRow('Website', 'https://gadaiintira.com', isLast: true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _openWebPrivacy(context),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: const Text('Buka Versi Web (gadaiintira.com/privacy)'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF15803D),
                        side: const BorderSide(color: Color(0xFF15803D)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF14532D),
            Color(0xFF15803D),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  behavior: HitTestBehavior.opaque,
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
              ),
              const Text(
                'Kebijakan Privasi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'GASPOL by INTIRA',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF14532D),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'PT. Gadai Intira Nusantara • Diperbarui 25 November 2026',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF15803D),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: const Color(0xFF15803D)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildBulletItem(String label, String description, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(Icons.circle, size: 6, color: Color(0xFF15803D)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
