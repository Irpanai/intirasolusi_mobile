import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';

class SelfieCaptureWidget extends StatefulWidget {
  final Function(File image) onSelfieCaptured;
  final File? existingImage;

  const SelfieCaptureWidget({
    super.key,
    required this.onSelfieCaptured,
    this.existingImage,
  });

  @override
  State<SelfieCaptureWidget> createState() => _SelfieCaptureWidgetState();
}

class _SelfieCaptureWidgetState extends State<SelfieCaptureWidget> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _hasPermission = false;
  String? _errorMessage;
  
  File? _capturedImage;
  // ignore: unused_field - set for potential future UI feedback
  bool _faceDetected = false;
  
  final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableClassification: false,
      enableLandmarks: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.fast,
    ),
  );

  @override
  void initState() {
    super.initState();
    _checkPermissionAndInitCamera();
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector.close();
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
          _errorMessage = 'Izin kamera diperlukan untuk foto selfie';
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

      // Use front camera for selfie
      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
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

  Future<void> _captureAndValidate() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    
    if (!mounted) return;

    setState(() => _isProcessing = true);

    try {
      // Capture image
      final XFile image = await _cameraController!.takePicture();
      final File imageFile = File(image.path);

      // Detect face in captured image
      final inputImage = InputImage.fromFile(imageFile);
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (mounted) {
          setState(() => _isProcessing = false);
        
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Wajah tidak terdeteksi. Pastikan wajah terlihat jelas.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _capturedImage = imageFile;
          _faceDetected = true;
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
            content: Text('Gagal mengambil foto: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
      _faceDetected = false;
    });
  }

  void _confirm() {
    if (_capturedImage != null) {
      widget.onSelfieCaptured(_capturedImage!);
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
            color: Colors.black,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Camera Preview
                Center(
                  child: CameraPreview(_cameraController!),
                ),
                
                // Face Guide Overlay
                _buildFaceGuide(),
                
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
                            'Mendeteksi wajah...',
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
                'Posisikan wajah Anda dalam bingkai oval',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTip(Icons.lightbulb_outline, 'Pencahayaan cukup'),
                  const SizedBox(width: 16),
                  _buildTip(Icons.face, 'Wajah terlihat jelas'),
                ],
              ),
              const SizedBox(height: 20),
              
              // Capture Button
              GestureDetector(
                onTap: _isProcessing ? null : _captureAndValidate,
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

  Widget _buildTip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildFaceGuide() {
    return Center(
      child: Container(
        width: 250,
        height: 320,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary, width: 3),
          borderRadius: BorderRadius.circular(125),
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Wajah Anda di sini',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final imageToShow = _capturedImage ?? widget.existingImage;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image Preview
          ClipRRect(
            borderRadius: BorderRadius.circular(150),
            child: Image.file(
              imageToShow!,
              width: 250,
              height: 320,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 20),
          
          // Success indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Wajah terdeteksi dengan baik',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          
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

  Widget _buildPermissionError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_front_outlined,
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
