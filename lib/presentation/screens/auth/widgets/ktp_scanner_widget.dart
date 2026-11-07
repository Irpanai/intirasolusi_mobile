import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/services/ktp_ocr_service.dart';
import '../../../../core/widgets/app_button.dart';

/// Global key used to obtain the KTP guide overlay Rect for auto-crop
final _ktpGuideKey = GlobalKey();

class KtpScannerWidget extends StatefulWidget {
  final Function(File image, KtpData ktpData) onKtpCaptured;
  final File? existingImage;

  const KtpScannerWidget({
    super.key,
    required this.onKtpCaptured,
    this.existingImage,
  });

  @override
  State<KtpScannerWidget> createState() => _KtpScannerWidgetState();
}

class _KtpScannerWidgetState extends State<KtpScannerWidget> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _hasPermission = false;
  String? _errorMessage;
  
  File? _capturedImage;
  KtpData? _ktpData;
  
  final KtpOcrService _ocrService = KtpOcrService();

  /// Key for the camera preview area to calculate crop coordinates
  final _cameraPreviewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkPermissionAndInitCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionAndInitCamera() async {
    final status = await Permission.camera.request();
    
    if (status.isGranted) {
      if (mounted) setState(() => _hasPermission = true);
      await _initializeCamera();
    } else {
      if (mounted) {
        setState(() {
          _hasPermission = false;
          _errorMessage = 'Izin kamera diperlukan untuk scan KTP';
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (mounted) setState(() => _errorMessage = 'Kamera tidak tersedia');
        return;
      }

      // Use back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = 'Gagal menginisialisasi kamera: $e');
    }
  }

  Future<void> _captureAndProcess() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();
      File imageFile = File(image.path);

      // Auto-crop to KTP guide area
      imageFile = await _autoCropToKtpArea(imageFile);

      // Process OCR (includes preprocessing internally)
      final ktpData = await _ocrService.processKtpImage(imageFile);

      if (mounted) {
        setState(() {
          _capturedImage = imageFile;
          _ktpData = ktpData;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'Gagal memproses gambar: $e';
        });
      
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses KTP: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// Auto-crop the captured image to only the KTP guide area
  Future<File> _autoCropToKtpArea(File originalFile) async {
    try {
      // Get the guide overlay position relative to the camera preview
      final guideBox = _ktpGuideKey.currentContext?.findRenderObject() as RenderBox?;
      final previewBox = _cameraPreviewKey.currentContext?.findRenderObject() as RenderBox?;

      if (guideBox == null || previewBox == null) {
        debugPrint('Auto-crop: guide or preview box not found, skipping crop');
        return originalFile;
      }

      // Guide position relative to preview
      final guidePos = guideBox.localToGlobal(Offset.zero);
      final previewPos = previewBox.localToGlobal(Offset.zero);
      final previewSize = previewBox.size;

      // Guide rect relative to preview widget
      final relLeft = (guidePos.dx - previewPos.dx) / previewSize.width;
      final relTop = (guidePos.dy - previewPos.dy) / previewSize.height;
      final relWidth = guideBox.size.width / previewSize.width;
      final relHeight = guideBox.size.height / previewSize.height;

      // Read the actual image dimensions
      final bytes = await originalFile.readAsBytes();
      final decoder = await _decodeImageDimensions(bytes);
      if (decoder == null) return originalFile;

      final imgWidth = decoder.width;
      final imgHeight = decoder.height;

      // The camera may have different aspect ratio than preview widget.
      // Camera image is typically portrait (rotated), so we need to figure out
      // the mapping. For simplicity, assume the preview maps to the full image.
      final cropLeft = (relLeft * imgWidth).round().clamp(0, imgWidth - 1);
      final cropTop = (relTop * imgHeight).round().clamp(0, imgHeight - 1);
      final cropWidth = (relWidth * imgWidth).round().clamp(1, imgWidth - cropLeft);
      final cropHeight = (relHeight * imgHeight).round().clamp(1, imgHeight - cropTop);

      debugPrint('Auto-crop: img=${imgWidth}x$imgHeight '
          'crop=($cropLeft,$cropTop,${cropWidth}x$cropHeight) '
          'rel=($relLeft,$relTop,$relWidth,$relHeight)');

      // Use dart:ui to crop
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final fullImage = frame.image;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        fullImage,
        Rect.fromLTWH(
          cropLeft.toDouble(), cropTop.toDouble(),
          cropWidth.toDouble(), cropHeight.toDouble(),
        ),
        Rect.fromLTWH(0, 0, cropWidth.toDouble(), cropHeight.toDouble()),
        Paint(),
      );

      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(cropWidth, cropHeight);
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

      fullImage.dispose();
      croppedImage.dispose();

      if (byteData == null) return originalFile;

      final croppedFile = File(
        '${Directory.systemTemp.path}/ktp_cropped_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await croppedFile.writeAsBytes(byteData.buffer.asUint8List());

      debugPrint('Auto-crop: saved cropped image to ${croppedFile.path}');
      return croppedFile;
    } catch (e) {
      debugPrint('Auto-crop failed: $e, using original image');
      return originalFile;
    }
  }

  /// Decode image dimensions without fully decoding pixels
  Future<_ImageDimension?> _decodeImageDimensions(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final dim = _ImageDimension(frame.image.width, frame.image.height);
      frame.image.dispose();
      return dim;
    } catch (_) {
      return null;
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
      _ktpData = null;
    });
  }

  void _confirm() {
    if (_capturedImage != null && _ktpData != null) {
      widget.onKtpCaptured(_capturedImage!, _ktpData!);
    }
  }

  @override
  Widget build(BuildContext context) {
    // If already has captured image, show preview
    if (_capturedImage != null || widget.existingImage != null) {
      return _buildPreview();
    }

    // Show camera or error
    if (!_hasPermission || _errorMessage != null) {
      return _buildPermissionError();
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    return _buildCameraView();
  }

  Widget _buildCameraView() {
    // Ensure camera is fully initialized with preview size
    if (_cameraController == null || 
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.previewSize == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }
    
    return Column(
      children: [
        Expanded(
          child: Container(
            key: _cameraPreviewKey,
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera Preview
                Center(
                  child: CameraPreview(_cameraController!),
                ),
              
                // Dark overlay with KTP cutout
                _buildDarkOverlayWithCutout(),
              
                // Processing Overlay
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Memproses KTP...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Instructions & Capture Button
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.white,
          child: Column(
            children: [
              const Text(
                'Posisikan KTP dalam bingkai dan pastikan foto jelas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              
              // Capture Button
              GestureDetector(
                onTap: _isProcessing ? null : _captureAndProcess,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: AppColors.primary, width: 4),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary,
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Builds a dark semi-transparent overlay with a clear cutout for the KTP area
  Widget _buildDarkOverlayWithCutout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // KTP card aspect ratio: 85.6mm x 53.98mm = 1.586
        const ktpAspect = 1.586;
        final availableWidth = constraints.maxWidth - 48; // 24px margin each side
        final ktpWidth = availableWidth;
        final ktpHeight = ktpWidth / ktpAspect;

        final left = 24.0;
        final top = (constraints.maxHeight - ktpHeight) / 2;

        return Stack(
          children: [
            // Dark overlay with hole
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _KtpOverlayPainter(
                cutoutRect: Rect.fromLTWH(left, top, ktpWidth, ktpHeight),
                overlayColor: Colors.black.withValues(alpha: 0.6),
                borderColor: AppColors.primary,
                borderWidth: 3,
                cornerRadius: 12,
              ),
            ),

            // KTP guide box (with key for auto-crop coordinate calculation)
            Positioned(
              left: left,
              top: top,
              width: ktpWidth,
              height: ktpHeight,
              child: Container(
                key: _ktpGuideKey,
                child: Stack(
                  children: [
                    // Corner brackets
                    ..._buildCornerBrackets(ktpWidth, ktpHeight),

                    // Center instruction text
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Letakkan KTP di sini',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    // Edge labels to guide alignment
                    Positioned(
                      bottom: 8,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Pastikan semua teks KTP terlihat jelas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build corner bracket indicators for KTP guide
  List<Widget> _buildCornerBrackets(double width, double height) {
    const bracketLength = 30.0;
    const thickness = 3.0;
    const color = AppColors.primary;

    return [
      // Top Left
      Positioned(top: 0, left: 0, child: _cornerPiece(bracketLength, thickness, color, corner: _Corner.topLeft)),
      // Top Right
      Positioned(top: 0, right: 0, child: _cornerPiece(bracketLength, thickness, color, corner: _Corner.topRight)),
      // Bottom Left
      Positioned(bottom: 0, left: 0, child: _cornerPiece(bracketLength, thickness, color, corner: _Corner.bottomLeft)),
      // Bottom Right
      Positioned(bottom: 0, right: 0, child: _cornerPiece(bracketLength, thickness, color, corner: _Corner.bottomRight)),
    ];
  }

  Widget _cornerPiece(double length, double thickness, Color color, {required _Corner corner}) {
    final isTop = corner == _Corner.topLeft || corner == _Corner.topRight;
    final isLeft = corner == _Corner.topLeft || corner == _Corner.bottomLeft;

    return SizedBox(
      width: length,
      height: length,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          thickness: thickness,
          isTop: isTop,
          isLeft: isLeft,
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final imageToShow = _capturedImage ?? widget.existingImage;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              imageToShow!,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          
          // OCR Results Preview
          if (_ktpData != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Data KTP Terdeteksi',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildOcrResult('NIK', _ktpData!.nik),
                  _buildOcrResult('Nama', _ktpData!.nama),
                  _buildOcrResult('Tempat Lahir', _ktpData!.tempatLahir),
                  _buildOcrResult('Tanggal Lahir', _ktpData!.tanggalLahir),
                  _buildOcrResult('Alamat', _ktpData!.alamat),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data akan bisa dikoreksi di langkah berikutnya',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted),
            ),
          ],
          
          const SizedBox(height: 24),
          
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _retake,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Foto Ulang'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  text: 'Lanjutkan',
                  onPressed: _confirm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOcrResult(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Izin kamera diperlukan',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            AppButton(
              text: 'Buka Pengaturan',
              onPressed: () => openAppSettings(),
            ),
          ],
        ),
      ),
    );
  }
}

// === Helper enums and classes ===

enum _Corner { topLeft, topRight, bottomLeft, bottomRight }

class _ImageDimension {
  final int width;
  final int height;
  _ImageDimension(this.width, this.height);
}

/// Custom painter to draw a dark overlay with a rounded-rect cutout for the KTP area
class _KtpOverlayPainter extends CustomPainter {
  final Rect cutoutRect;
  final Color overlayColor;
  final Color borderColor;
  final double borderWidth;
  final double cornerRadius;

  _KtpOverlayPainter({
    required this.cutoutRect,
    required this.overlayColor,
    required this.borderColor,
    required this.borderWidth,
    required this.cornerRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw overlay with cutout using path difference
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, Radius.circular(cornerRadius)));
    final combinedPath = Path.combine(PathOperation.difference, overlayPath, cutoutPath);

    canvas.drawPath(combinedPath, Paint()..color = overlayColor);

    // Draw border around cutout
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutoutRect, Radius.circular(cornerRadius)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _KtpOverlayPainter oldDelegate) {
    return cutoutRect != oldDelegate.cutoutRect;
  }
}

/// Custom painter for a single corner bracket (L-shaped)
class _CornerPainter extends CustomPainter {
  final Color color;
  final double thickness;
  final bool isTop;
  final bool isLeft;

  _CornerPainter({
    required this.color,
    required this.thickness,
    required this.isTop,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isTop && isLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTop && !isLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter oldDelegate) => false;
}
