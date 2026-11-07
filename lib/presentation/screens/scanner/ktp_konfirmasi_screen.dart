import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/widgets/gradient_header.dart';
import '../../../core/services/ktp_ocr_service.dart';
import 'ktp_npwp_scanner_screen.dart'; // for KtpScanResult

class KtpKonfirmasiScreen extends StatefulWidget {
  final File fotoKtp;
  /// Data hasil OCR lengkap — semua field akan di-prefill ke form
  final KtpData? ktpData;
  /// Callback opsional untuk mode embed di RegisterFlowScreen
  final void Function(KtpScanResult result)? onSubmit;

  const KtpKonfirmasiScreen({
    super.key,
    required this.fotoKtp,
    this.ktpData,
    this.onSubmit,
  });

  @override
  KtpKonfirmasiScreenState createState() => KtpKonfirmasiScreenState();
}

class KtpKonfirmasiScreenState extends State<KtpKonfirmasiScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nikController;
  late final TextEditingController _namaController;
  late final TextEditingController _tempatLahirController;
  late final TextEditingController _tanggalLahirController;
  late final TextEditingController _jenisKelaminController;
  late final TextEditingController _alamatController;
  late final TextEditingController _rtRwController;
  late final TextEditingController _kelurahanController;
  late final TextEditingController _kecamatanController;
  late final TextEditingController _kabupatenKotaController;
  late final TextEditingController _agamaController;
  late final TextEditingController _statusPerkawinanController;
  late final TextEditingController _pekerjaanController;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final d = widget.ktpData;
    _nikController = TextEditingController(text: d?.nik ?? '');
    _namaController = TextEditingController(text: d?.nama ?? '');
    _tempatLahirController = TextEditingController(text: d?.tempatLahir ?? '');
    _tanggalLahirController = TextEditingController(text: d?.tanggalLahir ?? '');
    _jenisKelaminController = TextEditingController(text: d?.jenisKelamin ?? '');
    _alamatController = TextEditingController(text: d?.alamat ?? '');
    _rtRwController = TextEditingController(text: d?.rtRw ?? '');
    _kelurahanController = TextEditingController(text: d?.kelurahan ?? '');
    _kecamatanController = TextEditingController(text: d?.kecamatan ?? '');
    _kabupatenKotaController = TextEditingController(text: d?.kabupatenKota ?? '');
    _agamaController = TextEditingController(text: d?.agama ?? '');
    _statusPerkawinanController = TextEditingController(text: d?.statusPerkawinan ?? '');
    _pekerjaanController = TextEditingController(text: d?.pekerjaan ?? '');
  }

  @override
  void dispose() {
    _nikController.dispose();
    _namaController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _jenisKelaminController.dispose();
    _alamatController.dispose();
    _rtRwController.dispose();
    _kelurahanController.dispose();
    _kecamatanController.dispose();
    _kabupatenKotaController.dispose();
    _agamaController.dispose();
    _statusPerkawinanController.dispose();
    _pekerjaanController.dispose();
    super.dispose();
  }

  Future<void> _pickTanggalLahir() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir',
    );
    if (picked != null) {
      _tanggalLahirController.text =
          '${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Kumpulkan semua data yang siap dikirim ke backend
    final payload = {
      'nik': _nikController.text.trim(),
      'nama': _namaController.text.trim(),
      'tempat_lahir': _tempatLahirController.text.trim(),
      'tanggal_lahir': _tanggalLahirController.text.trim(),
      'jenis_kelamin': _jenisKelaminController.text.trim(),
      'alamat': _alamatController.text.trim(),
      'rt_rw': _rtRwController.text.trim(),
      'kelurahan': _kelurahanController.text.trim(),
      'kecamatan': _kecamatanController.text.trim(),
      'kabupaten_kota': _kabupatenKotaController.text.trim(),
      'agama': _agamaController.text.trim(),
      'status_perkawinan': _statusPerkawinanController.text.trim(),
      'pekerjaan': _pekerjaanController.text.trim(),
      // 'foto_ktp': widget.fotoKtp  ← kirim sebagai MultipartFile ke API
    };

    // TODO: Integrasikan dengan API Laravel di sini
    // Contoh menggunakan dio:
    // final formData = FormData.fromMap({
    //   ...payload,
    //   'foto_ktp': await MultipartFile.fromFile(
    //     widget.fotoKtp.path,
    //     filename: 'ktp_${payload['nik']}.jpg',
    //   ),
    // });
    // await dio.post('/api/kyc/register', data: formData);

    await Future.delayed(const Duration(seconds: 1)); // simulasi request
    setState(() => _isSubmitting = false);

    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Data Tersimpan'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Data KTP berhasil dikonfirmasi dan siap dikirim ke server:'),
              const SizedBox(height: 12),
              ...payload.entries
                  .where((e) => e.value.isNotEmpty)
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text('${e.key}: ${e.value}',
                            style: const TextStyle(fontSize: 13)),
                      )),
              const SizedBox(height: 8),
              Text('📎 foto_ktp: ${widget.fotoKtp.path.split('/').last}',
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          GradientHeader(
            showBackButton: true,
            child: const GradientHeaderTitle(
              title: 'Konfirmasi Data KTP',
              subtitle: 'Periksa & sesuaikan hasil pemindaian data Anda',
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
            // ── Preview Foto KTP ──────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                widget.fotoKtp,
                height: 180,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Foto KTP Anda',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),

            const SizedBox(height: 20),

            // ── Banner panduan ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber[300]!),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Periksa setiap data di bawah. Koreksi jika ada yang salah terbaca oleh kamera, lalu tekan SUBMIT.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF795548)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Form Konfirmasi ───────────────────────────────────────────
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // NIK — diisi otomatis dari OCR, wajib diperiksa
                  _buildField(
                    controller: _nikController,
                    label: 'NIK *',
                    hint: '16 digit angka',
                    icon: Icons.credit_card,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    isOcr: true, // tandai sebagai hasil OCR
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'NIK wajib diisi';
                      if (v.length < 15 || v.length > 16) {
                        return 'NIK harus 15–16 digit';
                      }
                      return null;
                    },
                  ),

                  // Nama — diisi otomatis dari OCR, wajib diperiksa
                  _buildField(
                    controller: _namaController,
                    label: 'Nama Lengkap *',
                    hint: 'Sesuai KTP',
                    icon: Icons.person_outline,
                    isOcr: true,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Nama wajib diisi' : null,
                  ),

                  // Tempat Lahir — input manual
                  _buildField(
                    controller: _tempatLahirController,
                    label: 'Tempat Lahir',
                    hint: 'Contoh: BALIKPAPAN',
                    icon: Icons.location_city_outlined,
                    textCapitalization: TextCapitalization.characters,
                  ),

                  // Tanggal Lahir — date picker
                  GestureDetector(
                    onTap: _pickTanggalLahir,
                    child: AbsorbPointer(
                      child: _buildField(
                        controller: _tanggalLahirController,
                        label: 'Tanggal Lahir',
                        hint: 'DD-MM-YYYY',
                        icon: Icons.cake_outlined,
                        suffixIcon: const Icon(Icons.calendar_today, size: 18),
                      ),
                    ),
                  ),

                  // Jenis Kelamin — dropdown via TextField
                  _buildDropdownField(
                    controller: _jenisKelaminController,
                    label: 'Jenis Kelamin',
                    icon: Icons.wc_outlined,
                    options: const ['LAKI-LAKI', 'PEREMPUAN'],
                  ),

                  // Alamat — multiline
                  _buildField(
                    controller: _alamatController,
                    label: 'Alamat',
                    hint: 'Sesuai KTP',
                    icon: Icons.home_outlined,
                    maxLines: 3,
                    textCapitalization: TextCapitalization.characters,
                  ),

                  // RT/RW
                  _buildField(
                    controller: _rtRwController,
                    label: 'RT / RW',
                    hint: 'Contoh: 001/001',
                    icon: Icons.map_outlined,
                  ),

                  // Kelurahan
                  _buildField(
                    controller: _kelurahanController,
                    label: 'Kelurahan / Desa',
                    hint: '',
                    icon: Icons.location_on_outlined,
                    textCapitalization: TextCapitalization.characters,
                  ),

                  // Kecamatan
                  _buildField(
                    controller: _kecamatanController,
                    label: 'Kecamatan',
                    hint: '',
                    icon: Icons.place_outlined,
                    textCapitalization: TextCapitalization.characters,
                  ),

                  // Kabupaten/Kota
                  _buildField(
                    controller: _kabupatenKotaController,
                    label: 'Kabupaten / Kota',
                    hint: '',
                    icon: Icons.location_city_outlined,
                    textCapitalization: TextCapitalization.characters,
                  ),

                  // Agama
                  _buildDropdownField(
                    controller: _agamaController,
                    label: 'Agama',
                    icon: Icons.auto_awesome_outlined,
                    options: const [
                      'ISLAM',
                      'KRISTEN',
                      'KATOLIK',
                      'HINDU',
                      'BUDDHA',
                      'KONGHUCU',
                    ],
                  ),

                  // Status Perkawinan
                  _buildDropdownField(
                    controller: _statusPerkawinanController,
                    label: 'Status Perkawinan',
                    icon: Icons.favorite_outline,
                    options: const [
                      'BELUM KAWIN',
                      'KAWIN',
                      'CERAI HIDUP',
                      'CERAI MATI',
                    ],
                  ),

                  // Pekerjaan
                  _buildField(
                    controller: _pekerjaanController,
                    label: 'Pekerjaan',
                    hint: 'Contoh: KARYAWAN SWASTA',
                    icon: Icons.work_outline,
                    textCapitalization: TextCapitalization.characters,
                  ),

                  const SizedBox(height: 32),

                  // ── Tombol Submit ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(
                        _isSubmitting ? 'Mengirim...' : 'SUBMIT DATA & FOTO KTP',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF15803D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSubmitting ? null : _submit,
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
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

  // ── Builder: TextFormField standar ─────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    String hint = '',
    required IconData icon,
    bool isOcr = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(
              color: isOcr ? const Color(0xFFF59E0B) : const Color(0xFFE2E8F0),
              width: isOcr ? 1.5 : 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Color(0xFF15803D),
              width: 1.8,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          helperText: isOcr ? '✏️ Hasil OCR — periksa & koreksi jika perlu' : null,
          helperStyle: const TextStyle(color: Color(0xFFD97706), fontSize: 11),
        ),
      ),
    );
  }

  // ── Builder: Dropdown sebagai ModalBottomSheet ─────────────────────────────
  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> options,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () async {
          final chosen = await showModalBottomSheet<String>(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text(label,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                ...options.map(
                  (o) => ListTile(
                    title: Text(o),
                    trailing: controller.text == o
                        ? const Icon(Icons.check, color: Color(0xFF15803D))
                        : null,
                    onTap: () => Navigator.pop(context, o),
                  ),
                ),
              ],
            ),
          );
          if (chosen != null) {
            setState(() => controller.text = chosen);
          }
        },
        child: AbsorbPointer(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
              suffixIcon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF15803D),
                  width: 1.8,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
