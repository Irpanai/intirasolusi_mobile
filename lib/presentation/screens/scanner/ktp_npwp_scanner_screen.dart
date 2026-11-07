import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/services/ktp_ocr_service.dart';
import 'ktp_konfirmasi_screen.dart';

/// Model yang dibawa kembali ke pemanggil setelah user selesai konfirmasi
class KtpScanResult {
  final File fotoKtp;
  final String nik;
  final String nama;

  const KtpScanResult({
    required this.fotoKtp,
    required this.nik,
    required this.nama,
  });
}

class KtpNpwpScannerScreen extends StatefulWidget {
  /// Callback opsional: jika diisi, tombol konfirmasi akan mengembalikan
  /// [KtpScanResult] ke pemanggil (misal RegisterFlowScreen) lewat pop.
  final void Function(KtpScanResult result)? onConfirmed;

  const KtpNpwpScannerScreen({super.key, this.onConfirmed});

  @override
  KtpNpwpScannerScreenState createState() => KtpNpwpScannerScreenState();
}

class KtpNpwpScannerScreenState extends State<KtpNpwpScannerScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  KtpData? _ktpData;
  String _statusMsg = '';

  final ImagePicker _picker = ImagePicker();
  // Gunakan service yang sudah ada (dual-pass OCR + ktp_extractor + rotation)
  final KtpOcrService _ocrService = KtpOcrService();

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 100,
      maxWidth: 2000,
      maxHeight: 2000,
    );

    if (pickedFile == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: pickedFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop KTP — potong rapat ke tepi kartu',
          toolbarColor: const Color(0xFF1565C0),
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(title: 'Crop KTP'),
      ],
    );

    if (croppedFile == null) return;

    setState(() {
      _selectedImage = File(croppedFile.path);
      _isLoading = true;
      _ktpData = null;
      _statusMsg = 'Memproses OCR…';
    });

    try {
      // Gunakan KtpOcrService yang lengkap:
      // - Auto-crop via ktp_extractor Object Detection
      // - Dual-pass OCR (preprocessed + raw)
      // - Image rotation fallback (0°, 90°, 180°, 270°)
      // - Merge hasil terbaik dari semua pass
      final ktpData = await _ocrService.processKtpImage(_selectedImage!);

      setState(() {
        _ktpData = ktpData;
        _isLoading = false;
        _statusMsg = _buildStatusMsg(ktpData);
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses OCR: $e')),
        );
      }
    }
  }

  String _buildStatusMsg(KtpData data) {
    final found = <String>[];
    if (data.nik != null) found.add('NIK');
    if (data.nama != null) found.add('Nama');
    if (data.tempatLahir != null) found.add('TTL');
    if (data.jenisKelamin != null) found.add('JK');
    if (data.alamat != null) found.add('Alamat');
    if (found.isEmpty) return 'Tidak ada data yang terdeteksi';
    return 'Terdeteksi: ${found.join(', ')}';
  }

  void _lanjutKonfirmasi() {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto KTP belum diambil')),
      );
      return;
    }

    if (widget.onConfirmed != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KtpKonfirmasiScreen(
            fotoKtp: _selectedImage!,
            ktpData: _ktpData,
            onSubmit: (confirmedResult) {
              Navigator.pop(context);
              widget.onConfirmed!(confirmedResult);
            },
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => KtpKonfirmasiScreen(
            fotoKtp: _selectedImage!,
            ktpData: _ktpData,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasResult = !_isLoading && _selectedImage != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Scan KTP'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Preview Foto KTP ──────────────────────────────────────────
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _selectedImage != null
                      ? const Color(0xFF1565C0)
                      : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(),
                          const SizedBox(height: 14),
                          Text(_statusMsg,
                              style: const TextStyle(color: Color(0xFF1565C0))),
                          const SizedBox(height: 6),
                          const Text(
                            'Menggunakan dual-pass OCR + auto-rotate…',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_selectedImage!, fit: BoxFit.contain),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.credit_card,
                                size: 72, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            Text('Belum ada foto KTP',
                                style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
            ),

            const SizedBox(height: 20),

            // ── Tombol Kamera / Galeri ────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Kamera'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      foregroundColor: const Color(0xFF1565C0),
                    ),
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF1565C0)),
                      foregroundColor: const Color(0xFF1565C0),
                    ),
                    onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                  ),
                ),
              ],
            ),

            // ── Hasil OCR ringkasan ───────────────────────────────────────
            if (hasResult && _ktpData != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                        SizedBox(width: 8),
                        Text('Data terdeteksi (akan terisi otomatis):',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1565C0))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _resultRow('NIK', _ktpData!.nik ?? '— tidak terdeteksi', urgent: _ktpData!.nik == null),
                    _resultRow('Nama', _ktpData!.nama ?? '— tidak terdeteksi', urgent: _ktpData!.nama == null),
                    if (_ktpData!.tempatLahir != null)
                      _resultRow('Tempat Lahir', _ktpData!.tempatLahir!),
                    if (_ktpData!.tanggalLahir != null)
                      _resultRow('Tgl Lahir', _ktpData!.tanggalLahir!),
                    if (_ktpData!.jenisKelamin != null)
                      _resultRow('Jenis Kelamin', _ktpData!.jenisKelamin!),
                    if (_ktpData!.alamat != null)
                      _resultRow('Alamat', _ktpData!.alamat!),
                    const SizedBox(height: 10),
                    const Text(
                      '✏️ Semua data bisa dikoreksi di form konfirmasi.',
                      style: TextStyle(fontSize: 12, color: Colors.orange),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text(
                  'Lanjut ke Form Konfirmasi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _lanjutKonfirmasi,
              ),
            ],

            if (hasResult && _ktpData == null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange[300]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tidak ada data terdeteksi. Coba crop lebih rapat ke area teks KTP.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                icon: const Icon(Icons.edit_note),
                label: const Text('Isi Form Manual'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _lanjutKonfirmasi,
              ),
            ],

            const SizedBox(height: 24),

            // Tips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Color(0xFF1565C0), size: 18),
                      SizedBox(width: 6),
                      Text('Tips foto KTP yang baik:',
                          style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1565C0))),
                    ],
                  ),
                  SizedBox(height: 8),
                  _TipItem('Crop rapat ke 4 sisi kartu KTP'),
                  _TipItem('Pastikan seluruh teks terlihat jelas'),
                  _TipItem('Hindari pantulan cahaya atau bayangan'),
                  _TipItem('NIK yang salah terbaca bisa dikoreksi manual'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, {bool urgent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13)),
          ),
          const Text(' : ', style: TextStyle(color: Colors.black45)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: urgent ? Colors.red[400] : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  const _TipItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF1565C0))),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 12, color: Color(0xFF1565C0))),
          ),
        ],
      ),
    );
  }
}
