import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:ktp_extractor/ktp_extractor.dart';

/// Model untuk menyimpan data hasil OCR KTP
class KtpData {
  String? nik;
  String? nama;
  String? tempatLahir;
  String? tanggalLahir;
  String? jenisKelamin;
  String? alamat;
  String? rtRw;
  String? kelurahan;
  String? kecamatan;
  String? kabupatenKota;
  String? provinsi;
  String? agama;
  String? statusPerkawinan;
  String? pekerjaan;

  KtpData({
    this.nik,
    this.nama,
    this.tempatLahir,
    this.tanggalLahir,
    this.jenisKelamin,
    this.alamat,
    this.rtRw,
    this.kelurahan,
    this.kecamatan,
    this.kabupatenKota,
    this.provinsi,
    this.agama,
    this.statusPerkawinan,
    this.pekerjaan,
  });

  /// Create KtpData from ktp_extractor's KtpModel
  factory KtpData.fromKtpModel(KtpModel model) {
    // Combine RT and RW into RT/RW format
    String? rtRw;
    if (model.rt != null || model.rw != null) {
      final rt = model.rt ?? '000';
      final rw = model.rw ?? '000';
      rtRw = '$rt/$rw';
    }

    return KtpData(
      nik: model.nik,
      nama: model.name,
      tempatLahir: model.placeBirth,
      tanggalLahir: model.birthDay,
      jenisKelamin: model.gender,
      alamat: model.address,
      rtRw: rtRw,
      kelurahan: model.subDistrict,
      kecamatan: model.district,
      kabupatenKota: model.city,
      provinsi: model.province,
      agama: model.religion,
      statusPerkawinan: model.marital,
      pekerjaan: model.occupation,
    );
  }

  /// Convert gender ke format backend (male/female)
  String? get gender {
    if (jenisKelamin == null) return null;
    final lower = jenisKelamin!.toLowerCase();
    if (lower.contains('laki')) return 'male';
    if (lower.contains('perempuan') || lower.contains('wanita')) return 'female';
    return null;
  }

  /// Convert tanggal lahir ke format YYYY-MM-DD
  String? get birthDateFormatted {
    if (tanggalLahir == null) return null;
    try {
      // Format dari KTP: DD-MM-YYYY
      final parts = tanggalLahir!.split('-');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return '$year-$month-$day';
      }
    } catch (_) {}
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'nik': nik,
      'name': nama,
      'birth_place': tempatLahir,
      'birth_date': birthDateFormatted,
      'gender': gender,
      'address': alamat,
      'rt_rw': rtRw,
      'village': kelurahan,
      'district': kecamatan,
      'city': kabupatenKota,
      'province': provinsi,
      'religion': agama,
      'marital_status': statusPerkawinan,
      'occupation': pekerjaan,
    };
  }

  @override
  String toString() {
    return '''
KtpData(
  nik: $nik,
  nama: $nama,
  tempatLahir: $tempatLahir,
  tanggalLahir: $tanggalLahir,
  jenisKelamin: $jenisKelamin,
  alamat: $alamat,
  rtRw: $rtRw,
  kelurahan: $kelurahan,
  kecamatan: $kecamatan,
  kabupatenKota: $kabupatenKota,
  agama: $agama,
  statusPerkawinan: $statusPerkawinan,
  pekerjaan: $pekerjaan,
)''';
  }
}

/// Service untuk melakukan OCR pada foto KTP
/// Hybrid approach: KtpExtractor untuk auto-crop + custom parsing yang robust
class KtpOcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Valid Indonesian province codes for NIK validation
  static const _validProvinceCodes = {
    11, 12, 13, 14, 15, 16, 17, 18, 19, 21,
    31, 32, 33, 34, 35, 36,
    51, 52, 53,
    61, 62, 63, 64, 65,
    71, 72, 73, 74, 75, 76,
    81, 82,
    91, 92, 94,
  };

  /// Proses foto KTP dan extract data
  /// 1. Auto-crop menggunakan KtpExtractor (ML Kit Object Detection)
  /// 2. Custom OCR + parsing yang robust (dengan preprocessing & fallback)
  /// 3. KtpExtractor parsing sebagai supplement
  /// 4. Merge hasil terbaik dari keduanya
  Future<KtpData> processKtpImage(File imageFile) async {
    // Step 1: Auto-crop menggunakan KtpExtractor Object Detection
    File imageToProcess = imageFile;
    try {
      final croppedImage = await KtpExtractor.cropImageForKtp(imageFile);
      if (croppedImage != null) {
        imageToProcess = croppedImage;
        debugPrint('=== KtpExtractor auto-crop berhasil ===');
      }
    } catch (e) {
      debugPrint('KtpExtractor auto-crop gagal: $e, menggunakan gambar asli');
    }

    // Step 2: Custom OCR + parsing (robust)
    final customResult = await _processWithCustomOcr(imageToProcess);
    final customScore = _scoreKtpData(customResult);
    debugPrint('=== Custom OCR score: $customScore ===');

    // Step 3: KtpExtractor parsing sebagai supplement
    KtpData? extractorResult;
    try {
      final ktpModel = await KtpExtractor.extractKtp(imageToProcess);
      extractorResult = KtpData.fromKtpModel(ktpModel);
      debugPrint('=== KtpExtractor score: ${_scoreKtpData(extractorResult)} ===');
    } catch (e) {
      debugPrint('KtpExtractor parsing gagal: $e');
    }

    // Step 4: Merge - custom sebagai basis, extractor sebagai supplement
    final mergedResult = _mergeResults(customResult, extractorResult);

    // Step 5: If NIK still not found, try original image (before auto-crop) for NIK
    if (mergedResult.nik == null && imageToProcess.path != imageFile.path) {
      try {
        final origInputImage = InputImage.fromFile(imageFile);
        final origRecognized = await _textRecognizer.processImage(origInputImage);
        final origTexts = <String>[];
        for (final block in origRecognized.blocks) {
          for (final line in block.lines) {
            origTexts.add(line.text.trim());
          }
        }
        debugPrint('=== Original image OCR for NIK (${origTexts.length} lines) ===');
        mergedResult.nik = _extractBestNikFromLines(origTexts);
        if (mergedResult.nik != null) {
          debugPrint('=== NIK found from original image: ${mergedResult.nik} ===');
        }
      } catch (e) {
        debugPrint('Original image OCR for NIK failed: $e');
      }
    }

    debugPrint('=== Final Merged Result ===');
    debugPrint(mergedResult.toString());
    debugPrint('===========================');

    return mergedResult;
  }

  /// Merge dua hasil: custom sebagai basis, extractor mengisi field yang kosong
  KtpData _mergeResults(KtpData custom, KtpData? extractor) {
    if (extractor == null) return custom;

    return KtpData(
      nik: _pickBestNik(custom.nik, extractor.nik),
      nama: custom.nama ?? extractor.nama,
      tempatLahir: custom.tempatLahir ?? extractor.tempatLahir,
      tanggalLahir: custom.tanggalLahir ?? extractor.tanggalLahir,
      jenisKelamin: custom.jenisKelamin ?? extractor.jenisKelamin,
      alamat: custom.alamat ?? extractor.alamat,
      rtRw: custom.rtRw ?? extractor.rtRw,
      kelurahan: custom.kelurahan ?? extractor.kelurahan,
      kecamatan: custom.kecamatan ?? extractor.kecamatan,
      kabupatenKota: custom.kabupatenKota ?? extractor.kabupatenKota,
      provinsi: custom.provinsi ?? extractor.provinsi,
      agama: custom.agama ?? extractor.agama,
      statusPerkawinan: custom.statusPerkawinan ?? extractor.statusPerkawinan,
      pekerjaan: custom.pekerjaan ?? extractor.pekerjaan,
    );
  }

  /// Pilih NIK terbaik: prioritaskan yang valid secara struktur
  String? _pickBestNik(String? a, String? b) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;

    // Collect all candidates including 5↔6 swaps
    final candidates = <_NikCandidate>[];
    if (RegExp(r'^\d{16}$').hasMatch(a)) {
      final c = _NikCandidate(a, 'merge-a', 5);
      candidates.add(c);
      candidates.addAll(_generate56SwapCandidates(c));
    } else {
      candidates.add(_NikCandidate(a, 'merge-a', 0));
    }
    if (RegExp(r'^\d{16}$').hasMatch(b)) {
      final c = _NikCandidate(b, 'merge-b', 4);
      candidates.add(c);
      candidates.addAll(_generate56SwapCandidates(c));
    } else {
      candidates.add(_NikCandidate(b, 'merge-b', 0));
    }

    return _pickBestNikCandidate(candidates);
  }

  /// Process menggunakan custom OCR pipeline
  /// Mencoba beberapa rotasi jika orientasi awal gagal dibaca
  Future<KtpData> _processWithCustomOcr(File imageFile) async {
    // Try original orientation first
    final originalResult = await _processImageToKtpData(imageFile);
    final originalScore = _scoreKtpData(originalResult);

    debugPrint('=== Original orientation score: $originalScore ===');

    // If we got good results (at least NIK + nama + TTL), return immediately
    if (originalScore >= 5) {
      return originalResult;
    }

    // Try rotating the image 90°, 180°, 270° and pick the best result
    KtpData bestResult = originalResult;
    int bestScore = originalScore;

    for (final degrees in [90, 180, 270]) {
      File? rotatedFile;
      try {
        rotatedFile = await _rotateImageFile(imageFile, degrees);
        final result = await _processImageToKtpData(rotatedFile);
        final score = _scoreKtpData(result);

        debugPrint('=== Rotation $degrees° score: $score ===');

        if (score > bestScore) {
          bestScore = score;
          bestResult = result;
        }

        // Good enough, stop trying
        if (bestScore >= 5) break;
      } catch (e) {
        debugPrint('Rotation $degrees° failed: $e');
      } finally {
        // Clean up temp file
        if (rotatedFile != null && await rotatedFile.exists()) {
          try { await rotatedFile.delete(); } catch (_) {}
        }
      }
    }

    return bestResult;
  }

  /// Process a single image file and return parsed KtpData
  /// Runs dual-pass OCR (preprocessed + raw) and merges for best accuracy
  Future<KtpData> _processImageToKtpData(File imageFile) async {
    // Pass 1: Preprocessed image
    final preprocessedFile = await _preprocessImage(imageFile);
    final fileToProcess = preprocessedFile ?? imageFile;

    final preprocessedResult = await _ocrAndParse(fileToProcess);

    // Clean up preprocessed temp file
    if (preprocessedFile != null && preprocessedFile.path != imageFile.path) {
      try { await preprocessedFile.delete(); } catch (_) {}
    }

    // Pass 2: Raw image (without preprocessing) — helps when preprocessing
    // degrades digit shapes (e.g., 5 vs 6 confusion from binarization)
    if (preprocessedFile != null) {
      final rawResult = await _ocrAndParse(imageFile);

      final preScore = _scoreKtpData(preprocessedResult);
      final rawScore = _scoreKtpData(rawResult);
      debugPrint('=== Dual-pass: preprocessed=$preScore, raw=$rawScore ===');

      // Merge: take each field from the higher-quality source
      return _mergeDualPassResults(preprocessedResult, rawResult);
    }

    return preprocessedResult;
  }

  /// Run OCR on a single file and parse the result
  Future<KtpData> _ocrAndParse(File file) async {
    final inputImage = InputImage.fromFile(file);
    final recognizedText = await _textRecognizer.processImage(inputImage);

    final ktpData = KtpData();

    // Collect all text lines WITH their bounding box positions
    final positionedLines = <_PositionedLine>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final rect = line.boundingBox;
        positionedLines.add(_PositionedLine(
          text: line.text.trim(),
          top: rect.top,
          left: rect.left,
          bottom: rect.bottom,
          height: rect.height,
        ));
      }
    }

    // Sort by Y position (top to bottom)
    positionedLines.sort((a, b) {
      final yDiff = a.top.compareTo(b.top);
      if (yDiff != 0) return yDiff;
      return a.left.compareTo(b.left);
    });

    // Group lines that are on the same visual row
    // Two lines are "same row" if their vertical centers overlap significantly
    final mergedLines = <String>[];
    final used = List.filled(positionedLines.length, false);

    for (var i = 0; i < positionedLines.length; i++) {
      if (used[i]) continue;
      used[i] = true;

      final rowLines = <_PositionedLine>[positionedLines[i]];

      // Find other lines on the same row
      final centerY = (positionedLines[i].top + positionedLines[i].bottom) / 2;
      final threshold = positionedLines[i].height * 0.5;

      for (var j = i + 1; j < positionedLines.length; j++) {
        if (used[j]) continue;
        final otherCenterY = (positionedLines[j].top + positionedLines[j].bottom) / 2;
        if ((otherCenterY - centerY).abs() < threshold) {
          rowLines.add(positionedLines[j]);
          used[j] = true;
        }
      }

      // Sort row lines by X position (left to right)
      rowLines.sort((a, b) => a.left.compareTo(b.left));

      // Merge into a single line, adding space between fragments
      final merged = rowLines.map((l) => l.text).join(' ');
      if (merged.trim().isNotEmpty) {
        mergedLines.add(merged.trim());
      }
    }

    // Debug: print raw vs merged lines
    debugPrint('=== OCR Raw Lines (${positionedLines.length}) ===');
    for (var i = 0; i < positionedLines.length; i++) {
      final p = positionedLines[i];
      debugPrint('  [$i] y=${p.top.toInt()} x=${p.left.toInt()} "${p.text}"');
    }
    debugPrint('=== OCR Merged Lines (${mergedLines.length}) ===');
    for (var i = 0; i < mergedLines.length; i++) {
      debugPrint('  [$i] ${mergedLines[i]}');
    }
    debugPrint('=================');

    // Parse merged lines to extract KTP data (pass raw lines for NIK fallback)
    _parseKtpData(mergedLines, ktpData, positionedLines);

    return ktpData;
  }

  /// Merge results from dual-pass OCR (preprocessed + raw image)
  /// For each field, pick the one that's not null; for NIK use structural scoring
  KtpData _mergeDualPassResults(KtpData preprocessed, KtpData raw) {
    return KtpData(
      nik: _pickBestNik(preprocessed.nik, raw.nik),
      nama: preprocessed.nama ?? raw.nama,
      tempatLahir: preprocessed.tempatLahir ?? raw.tempatLahir,
      tanggalLahir: preprocessed.tanggalLahir ?? raw.tanggalLahir,
      jenisKelamin: preprocessed.jenisKelamin ?? raw.jenisKelamin,
      alamat: preprocessed.alamat ?? raw.alamat,
      rtRw: preprocessed.rtRw ?? raw.rtRw,
      kelurahan: preprocessed.kelurahan ?? raw.kelurahan,
      kecamatan: preprocessed.kecamatan ?? raw.kecamatan,
      kabupatenKota: preprocessed.kabupatenKota ?? raw.kabupatenKota,
      provinsi: preprocessed.provinsi ?? raw.provinsi,
      agama: preprocessed.agama ?? raw.agama,
      statusPerkawinan: preprocessed.statusPerkawinan ?? raw.statusPerkawinan,
      pekerjaan: preprocessed.pekerjaan ?? raw.pekerjaan,
    );
  }

  /// Preprocess image for better OCR accuracy on KTP
  Future<File?> _preprocessImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) return null;

      // 1. Upscale small images for better digit recognition
      if (image.width < 1500) {
        final scale = 1500.0 / image.width;
        image = img.copyResize(
          image,
          width: (image.width * scale).round(),
          height: (image.height * scale).round(),
          interpolation: img.Interpolation.cubic,
        );
      }

      // 2. Convert to grayscale
      image = img.grayscale(image);

      // 3. Moderate contrast (1.2 instead of 1.5 to preserve digit edge shapes like 5 vs 6)
      image = img.adjustColor(image, contrast: 1.2);

      // 4. Binary threshold - converts to pure B/W for cleaner digit shapes
      // This preserves the structural difference between 5 and 6 better than
      // continuous-tone sharpening which can merge similar curves
      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixel = image.getPixel(x, y);
          final lum = pixel.luminance;
          if (lum < 0.55) {
            image.setPixelRgb(x, y, 0, 0, 0);
          } else {
            image.setPixelRgb(x, y, 255, 255, 255);
          }
        }
      }

      // Save preprocessed image
      final processedBytes = img.encodePng(image);
      final processedFile = File(
        '${Directory.systemTemp.path}/ktp_preprocessed_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await processedFile.writeAsBytes(processedBytes);

      return processedFile;
    } catch (e) {
      debugPrint('Preprocessing failed: $e');
      return null;
    }
  }

  /// Rotate image file by [degrees] (90, 180, 270) using dart:ui
  Future<File> _rotateImageFile(File imageFile, int degrees) async {
    final bytes = await imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final radians = degrees * math.pi / 180;
    final isRightAngle = degrees == 90 || degrees == 270;
    final newWidth = isRightAngle ? image.height : image.width;
    final newHeight = isRightAngle ? image.width : image.height;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    canvas.translate(newWidth / 2.0, newHeight / 2.0);
    canvas.rotate(radians);
    canvas.translate(-image.width / 2.0, -image.height / 2.0);
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());

    final picture = recorder.endRecording();
    final rotatedImage = await picture.toImage(newWidth, newHeight);
    final byteData = await rotatedImage.toByteData(format: ui.ImageByteFormat.png);

    image.dispose();
    rotatedImage.dispose();

    final tempFile = File(
      '${Directory.systemTemp.path}/ktp_rotated_${degrees}_${DateTime.now().millisecondsSinceEpoch}.png',
    );
    await tempFile.writeAsBytes(byteData!.buffer.asUint8List());

    return tempFile;
  }

  /// Score how complete the parsed KTP data is
  int _scoreKtpData(KtpData data) {
    int score = 0;
    if (data.nik != null) score += 2;
    if (data.nama != null) score += 2;
    if (data.tempatLahir != null) score += 1;
    if (data.tanggalLahir != null) score += 1;
    if (data.jenisKelamin != null) score += 1;
    if (data.alamat != null) score += 1;
    if (data.agama != null) score += 1;
    if (data.pekerjaan != null) score += 1;
    return score;
  }

  void _parseKtpData(List<String> lines, KtpData ktpData, List<_PositionedLine> rawLines) {
    final usedLines = <int>{};
    int footerStartIndex = lines.length;
    for (var i = 0; i < lines.length; i++) {
      final upper = lines[i].toUpperCase();
      if (upper.contains('BERLAKU') || upper.contains('BERDAKU') ||
          upper.contains('SEUMUR')) {
        footerStartIndex = i;
        break;
      }
    }

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].toUpperCase();
      final nextLine = i + 1 < lines.length ? lines[i + 1] : '';
      final isFooter = i >= footerStartIndex;

      // NIK - 16 digit number
      if (ktpData.nik == null) {
        final nik = _extractNik(lines[i], line);
        if (nik != null) {
          ktpData.nik = nik;
          usedLines.add(i);
          continue;
        }
      }

      if (line == 'WK' || line == 'NK' || line == 'NIK') {
        usedLines.add(i);
        continue;
      }

      // === HEADER: Provinsi & Kabupaten/Kota ===
      if (ktpData.provinsi == null && !isFooter && line.contains('PROVINSI')) {
        ktpData.provinsi = _extractValue(lines[i], 'PROVINSI') ??
            lines[i].replaceAll(RegExp(r'PROVINSI', caseSensitive: false), '').trim();
        usedLines.add(i);
        continue;
      }

      if (ktpData.kabupatenKota == null && !isFooter &&
          (line.contains('KABUPATEN') || line.contains('KOTA')) &&
          !line.contains('KEL') && !line.contains('DESA') &&
          !line.contains('KECAMATAN')) {
        ktpData.kabupatenKota = _extractValue(lines[i], 'KABUPATEN') ??
            _extractValue(lines[i], 'KOTA') ??
            lines[i]
                .replaceAll(RegExp(r'KABUPATEN|KOTA', caseSensitive: false), '')
                .trim();
        if (ktpData.kabupatenKota != null && ktpData.kabupatenKota!.isEmpty) {
          if (nextLine.isNotEmpty && !_isLabel(nextLine)) {
            ktpData.kabupatenKota = nextLine.trim();
            usedLines.add(i + 1);
          } else {
            ktpData.kabupatenKota = null;
          }
        }
        usedLines.add(i);
        continue;
      }

      if (isFooter) continue;

      // === TEMPAT/TGL LAHIR ===
      if (_matchTtlLabel(line)) {
        String? ttlValue = _extractValue(lines[i], '');
        if (ttlValue == null || !_isTtlValue(ttlValue)) {
          final inlineMatch = RegExp(
            r'([A-Za-z][A-Za-z\s]+),\s*(\d{1,2}[\s\-/]\d{1,2}[\s\-/]\d{2,4})',
          ).firstMatch(lines[i]);
          if (inlineMatch != null) {
            ttlValue = '${inlineMatch.group(1)!.trim()}, ${inlineMatch.group(2)!.trim()}';
          }
        }
        if (ttlValue == null || !_isTtlValue(ttlValue)) {
          final stripped = lines[i]
              .replaceAll(RegExp(r'(Tempat|Ternpat|Tempatigi|Tgl|Tanggal|Lahir|TTL|/|:)', caseSensitive: false), '')
              .trim();
          if (stripped.isNotEmpty && _isTtlValue(stripped)) {
            ttlValue = stripped;
          }
        }

        if (ttlValue != null && _isTtlValue(ttlValue)) {
          _parseTtlValue(ttlValue, ktpData);
          usedLines.add(i);
        } else if (nextLine.isNotEmpty && _isTtlValue(nextLine)) {
          _parseTtlValue(nextLine, ktpData);
          usedLines.addAll([i, i + 1]);
        } else if (ttlValue != null && ttlValue.contains(',')) {
          _parseTtlValue(ttlValue, ktpData);
          usedLines.add(i);
        } else if (nextLine.isNotEmpty) {
          if (nextLine.contains(',')) {
            _parseTtlValue(nextLine, ktpData);
            usedLines.addAll([i, i + 1]);
          } else {
            ktpData.tempatLahir ??= nextLine.trim();
            usedLines.addAll([i, i + 1]);
            if (i + 2 < lines.length) {
              final dateLine = lines[i + 2].trim();
              if (RegExp(r'\d{1,2}[\s\-/]\d{1,2}[\s\-/]\d{4}').hasMatch(dateLine)) {
                ktpData.tanggalLahir ??= _extractDate(dateLine);
                usedLines.add(i + 2);
              }
            }
          }
        }
        continue;
      }

      // === NAMA ===
      if (line.contains('NAMA') &&
          !line.contains('KECAMATAN') &&
          !line.contains('KEL') &&
          !line.contains('DESA') &&
          !_matchTtlLabel(line)) {
        final value = _extractValue(lines[i], 'NAMA');
        if (value != null && !_isTtlValue(value)) {
          ktpData.nama = value;
          usedLines.add(i);
        } else if (value != null && _isTtlValue(value)) {
          if (ktpData.tempatLahir == null) {
            _parseTtlValue(value, ktpData);
          }
          usedLines.add(i);
        } else if (nextLine.isNotEmpty && !_isLabel(nextLine) &&
            !usedLines.contains(i + 1)) {
          if (!_isTtlValue(nextLine)) {
            ktpData.nama = nextLine;
            usedLines.addAll([i, i + 1]);
          } else {
            if (ktpData.tempatLahir == null) {
              _parseTtlValue(nextLine, ktpData);
            }
            usedLines.addAll([i, i + 1]);
          }
        }
        continue;
      }

      // === JENIS KELAMIN ===
      if (line.contains('JENIS KELAMIN') ||
          (line.contains('JENIS') && line.contains('KELAMIN')) ||
          (line.contains('JENIS') && line.contains('KETAMIN')) ||
          RegExp(r'JENIS\s*KEL[^/]', caseSensitive: false).hasMatch(line) ||
          RegExp(r'JENIS\s*KE[TL]', caseSensitive: false).hasMatch(line) ||
          RegExp(r'^JK\b').hasMatch(line)) {
        String? value = _extractValue(lines[i], 'JENIS KELAMIN') ??
            _extractValue(lines[i], 'JENIS KETAMIN') ??
            _extractValue(lines[i], 'JK');
        if (value == null) {
          value = lines[i]
              .replaceAll(RegExp(r'Jenis\s*(Kelamin|Ketamin|Kel\w*)', caseSensitive: false), '')
              .trim();
          if (value.isEmpty) value = null;
        }
        if (value != null) {
          value = value.replaceAll(
              RegExp(r'\s*GOL\.?\s*DARAH\s*:?\s*.*', caseSensitive: false), '').trim();
          final upperVal = value.toUpperCase();
          if (upperVal.contains('LAKI') ||
              upperVal.contains('PEREMPUAN') ||
              upperVal.contains('WANITA')) {
            if (upperVal.contains('LAKI') && !upperVal.contains('PEREMPUAN')) {
              ktpData.jenisKelamin = 'LAKI-LAKI';
            } else {
              ktpData.jenisKelamin = 'PEREMPUAN';
            }
          }
        }
        if (ktpData.jenisKelamin == null) {
          if (nextLine.toUpperCase().contains('LAKI') ||
              nextLine.toUpperCase().contains('PEREMPUAN')) {
            ktpData.jenisKelamin = nextLine
                .replaceAll(RegExp(r'\s*GOL\.?\s*DARAH\s*:?\s*.*', caseSensitive: false), '')
                .trim();
          }
        }
        usedLines.add(i);
        continue;
      }

      // Standalone gender line
      if (ktpData.jenisKelamin == null &&
          (line == 'LAKI-LAKI' || line == 'LAKI LAKI' ||
           line == 'PEREMPUAN' || line.startsWith('LAKI-LAKI') ||
           line.startsWith('PEREMPUAN'))) {
        ktpData.jenisKelamin = lines[i]
            .replaceAll(RegExp(r'\s*GOL\.?\s*DARAH\s*:?\s*.*', caseSensitive: false), '')
            .trim();
        usedLines.add(i);
        continue;
      }

      // === ALAMAT ===
      if (line.contains('ALAMAT') && !line.contains('GOL')) {
        String? alamat = _extractValue(lines[i], 'ALAMAT') ??
            (nextLine.isNotEmpty && !_isLabel(nextLine) ? nextLine : null);
        usedLines.add(i);
        if (alamat != null) {
          int j = i + 1;
          if (_extractValue(lines[i], 'ALAMAT') != null) {
            while (j < lines.length && j < footerStartIndex) {
              final contLine = lines[j].toUpperCase();
              if (_isLabel(lines[j]) || contLine.contains('RT') ||
                  contLine.contains('KEL') || contLine.contains('KEC') ||
                  usedLines.contains(j)) break;
              alamat = '$alamat ${lines[j].trim()}';
              usedLines.add(j);
              j++;
            }
          }
          ktpData.alamat = alamat;
        }
        continue;
      }

      // === RT/RW ===
      if (line.contains('RT/RW') || line.contains('RT RW') ||
          line.contains('RTRW') || line.contains('RI/RW') ||
          line.contains('RI RW')) {
        ktpData.rtRw = _extractValue(lines[i], 'RT/RW') ??
            _extractValue(lines[i], 'RI/RW') ??
            _extractValue(lines[i], 'RT RW') ??
            _extractValue(lines[i], 'RI RW') ??
            _extractValue(lines[i], 'RTRW') ??
            _extractRtRw(lines[i]);
        usedLines.add(i);
        continue;
      }

      // === KELURAHAN/DESA ===
      if (line.contains('KEL/DESA') || line.contains('KEL DESA') ||
          line.contains('KELBESA') || line.contains('KEL.DESA') ||
          (line.contains('KELURAHAN') && !line.contains('NAMA')) ||
          (line.contains('DESA') && !line.contains('NAMA') && !line.contains('KEL'))) {
        ktpData.kelurahan = _extractValue(lines[i], 'KEL/DESA') ??
            _extractValue(lines[i], 'KEL DESA') ??
            _extractValue(lines[i], 'KELBESA') ??
            _extractValue(lines[i], 'KEL.DESA') ??
            _extractValue(lines[i], 'KELURAHAN') ??
            _extractValue(lines[i], 'DESA') ??
            (nextLine.isNotEmpty && !_isLabel(nextLine) ? nextLine : null);
        usedLines.add(i);
        continue;
      }

      // === KECAMATAN ===
      if (line.contains('KECAMATAN') || line.startsWith('KEC ') ||
          line.startsWith('KEC:') || line.startsWith('KEC.')) {
        ktpData.kecamatan = _extractValue(lines[i], 'KECAMATAN') ??
            _extractValue(lines[i], 'KEC') ??
            (nextLine.isNotEmpty && !_isLabel(nextLine) ? nextLine : null);
        usedLines.add(i);
        continue;
      }

      // === AGAMA ===
      if (line.contains('AGAMA')) {
        ktpData.agama = _extractValue(lines[i], 'AGAMA') ??
            (nextLine.isNotEmpty && !_isLabel(nextLine) ? nextLine : null);
        usedLines.add(i);
        continue;
      }

      // === STATUS PERKAWINAN ===
      if (line.contains('STATUS PERKAWINAN') || line.contains('STATUS') &&
          (line.contains('KAWIN') || line.contains('BELUM'))) {
        final value = _extractValue(lines[i], 'STATUS PERKAWINAN') ??
            _extractValue(lines[i], 'STATUS');
        if (value != null) {
          ktpData.statusPerkawinan = value;
        } else if (nextLine.isNotEmpty &&
            (nextLine.toUpperCase().contains('KAWIN') ||
                nextLine.toUpperCase().contains('BELUM'))) {
          ktpData.statusPerkawinan = nextLine;
        }
        usedLines.add(i);
        continue;
      }

      // === PEKERJAAN ===
      if (line.contains('PEKERJAAN')) {
        String? pekerjaan = _extractValue(lines[i], 'PEKERJAAN') ??
            (nextLine.isNotEmpty && !_isLabel(nextLine) ? nextLine : null);
        if (pekerjaan != null) {
          pekerjaan = pekerjaan
              .replaceAll(RegExp(r'\s+KOTA\b.*', caseSensitive: false), '')
              .replaceAll(RegExp(r'\s+KABUPATEN\b.*', caseSensitive: false), '')
              .trim();
        }
        ktpData.pekerjaan = pekerjaan;
        usedLines.add(i);
        continue;
      }

      // === KEWARGANEGARAAN (skip) ===
      if (line.contains('KEWARGANEGARAAN') || line.contains('WNI') ||
          line.contains('WNA')) {
        usedLines.add(i);
        continue;
      }

      if (line.contains('BERLAKU') || line.contains('BERDAKU') ||
          line.contains('SEUMUR')) {
        usedLines.add(i);
        continue;
      }

      if (line.contains('GOL') && line.contains('DARAH')) {
        usedLines.add(i);
        continue;
      }
    }

    // === Fallback: pattern-based extraction for missing fields ===

    if (ktpData.tempatLahir == null || ktpData.tanggalLahir == null) {
      for (var i = 0; i < footerStartIndex; i++) {
        if (usedLines.contains(i)) continue;
        if (_isTtlValue(lines[i])) {
          _parseTtlValue(lines[i], ktpData);
          usedLines.add(i);
          break;
        }
      }
    }

    if (ktpData.nama != null && _isTtlValue(ktpData.nama!)) {
      if (ktpData.tempatLahir == null) {
        _parseTtlValue(ktpData.nama!, ktpData);
      }
      ktpData.nama = null;
    }

    // Fallback: NAMA - find unnamed line between NIK and TTL (positional)
    if (ktpData.nama == null) {
      int nikIdx = -1;
      int ttlIdx = -1;
      for (var i = 0; i < lines.length && i < footerStartIndex; i++) {
        final upper = lines[i].toUpperCase();
        if (nikIdx < 0 && (upper.contains('NIK') || upper.startsWith('WK ') ||
            upper.startsWith('NK ') || RegExp(r'\d{10,}').hasMatch(upper))) {
          nikIdx = i;
        }
        if (ttlIdx < 0 && _matchTtlLabel(upper)) {
          ttlIdx = i;
        }
      }
      if (nikIdx >= 0 && ttlIdx > nikIdx) {
        for (var i = nikIdx + 1; i < ttlIdx; i++) {
          if (usedLines.contains(i)) continue;
          final candidate = lines[i].trim();
          if (candidate.isNotEmpty && !_isLabel(candidate) &&
              !RegExp(r'^\d+$').hasMatch(candidate) &&
              candidate.length >= 3) {
            ktpData.nama = candidate;
            usedLines.add(i);
            break;
          }
        }
      }
    }

    // Extra fallback: NAMA — scan all unused non-label lines between start and footer
    // that look like a person name (mostly uppercase alpha, no digits, reasonable length)
    if (ktpData.nama == null) {
      // Find lines that contain "Nama" label (possibly garbled)
      int namaLabelIdx = -1;
      for (var i = 0; i < footerStartIndex; i++) {
        final upper = lines[i].toUpperCase();
        if (upper.contains('NAMA') || upper.contains('NANA') ||
            upper.startsWith('NAM ') || upper == 'NAM') {
          namaLabelIdx = i;
          usedLines.add(i);
          break;
        }
      }
      // If label found, next unused line is likely the name
      if (namaLabelIdx >= 0 && namaLabelIdx + 1 < footerStartIndex) {
        for (var i = namaLabelIdx + 1; i < footerStartIndex; i++) {
          if (usedLines.contains(i)) continue;
          final candidate = lines[i].trim();
          if (candidate.isNotEmpty && !_isLabel(candidate) &&
              candidate.length >= 3 && !RegExp(r'^\d+$').hasMatch(candidate)) {
            ktpData.nama = candidate;
            usedLines.add(i);
            break;
          }
        }
      }
    }

    // Fallback: scan unused lines for NIK
    if (ktpData.nik == null) {
      for (var i = 0; i < lines.length; i++) {
        if (usedLines.contains(i)) continue;
        final nik = _extractNik(lines[i], lines[i].toUpperCase());
        if (nik != null) {
          ktpData.nik = nik;
          usedLines.add(i);
          break;
        }
      }
    }

    // Extra fallback: smart NIK cleaning on merged lines
    if (ktpData.nik == null) {
      for (var i = 0; i < lines.length; i++) {
        final cleaned = _aggressiveNikClean(lines[i]);
        if (cleaned != null) {
          ktpData.nik = cleaned;
          usedLines.add(i);
          break;
        }
      }
    }

    // Extra fallback: extract NIK from raw OCR blocks (before line merging)
    if (ktpData.nik == null) {
      final rawTexts = rawLines.map((l) => l.text).toList();
      ktpData.nik = _extractBestNikFromLines(rawTexts);
      if (ktpData.nik != null) {
        debugPrint('=== NIK found from raw OCR blocks: ${ktpData.nik} ===');
      }
    }

    // Post-processing: fix common OCR text errors
    _postProcessOcrTextFields(ktpData);

    debugPrint('=== Parsed KTP Data ===');
    debugPrint(ktpData.toString());
    debugPrint('=======================');
  }

  void _postProcessOcrTextFields(KtpData ktpData) {
    if (ktpData.agama != null) {
      ktpData.agama = ktpData.agama!
          .replaceAll(RegExp(r'^1(?=SLA)', caseSensitive: false), 'I')
          .replaceAll(RegExp(r'^I5LAM', caseSensitive: false), 'ISLAM');
    }

    if (ktpData.provinsi != null) {
      var prov = ktpData.provinsi!;
      prov = prov.replaceAll(RegExp(r'^PROVINSI', caseSensitive: false), '').trim();
      prov = prov.replaceAll(RegExp(r'KALIMANIAN', caseSensitive: false), 'KALIMANTAN');
      prov = prov.replaceAllMapped(
        RegExp(r'(KALIMANTAN)(SELATAN|TENGAH|TIMUR|BARAT|UTARA)', caseSensitive: false),
        (m) => '${m.group(1)} ${m.group(2)}',
      );
      if (prov.isNotEmpty) ktpData.provinsi = prov;
    }

    if (ktpData.kelurahan != null) {
      var kel = ktpData.kelurahan!;
      kel = kel.replaceAll(RegExp(r'^(KELBESA|KEL\.?DESA|KEL/DESA)\s*', caseSensitive: false), '').trim();
      if (kel.isNotEmpty) ktpData.kelurahan = kel;
    }
  }

  String? _extractNik(String original, String lineUpper) {
    final candidates = <_NikCandidate>[];

    // Strategy 1: Exact 16 consecutive digits (highest confidence)
    final exactMatches = RegExp(r'(\d{16})').allMatches(original);
    for (final m in exactMatches) {
      candidates.add(_NikCandidate(m.group(1)!, 'exact', 20));
    }

    // Strategy 2: "NIK" label followed by value
    if (lineUpper.contains('NIK') ||
        RegExp(r'\bWK\b|\bNK\b').hasMatch(lineUpper)) {
      final afterNik = original.replaceFirst(
        RegExp(r'.*(NIK|WK|NK)\s*:?\s*', caseSensitive: false), '',
      );
      // Try exact digits after removing label + separators
      final cleaned = afterNik.replaceAll(RegExp(r'[\s.\-]'), '');
      if (cleaned.length >= 16) {
        final digitMatch = RegExp(r'(\d{16})').firstMatch(cleaned);
        if (digitMatch != null) {
          candidates.add(_NikCandidate(digitMatch.group(1)!, 'nik-label', 15));
        }
      }
      // Try smart OCR correction after label
      final corrected = _smartOcrDigitCorrection(afterNik);
      if (corrected.length >= 16) {
        final match = RegExp(r'(\d{16})').firstMatch(corrected);
        if (match != null) {
          candidates.add(_NikCandidate(match.group(1)!, 'nik-label-corrected', 10));
        }
      }
    }

    // Strategy 3: Digits with spaces/dots/dashes removed
    final noSep = original.replaceAll(RegExp(r'[\s.\-]'), '');
    if (noSep.length >= 16) {
      final match = RegExp(r'(\d{16})').firstMatch(noSep);
      if (match != null && !candidates.any((c) => c.value == match.group(1))) {
        candidates.add(_NikCandidate(match.group(1)!, 'no-sep', 18));
      }
    }

    // Strategy 4: Smart OCR correction (context-aware, less aggressive)
    if (original.length >= 14) {
      final corrected = _smartOcrDigitCorrection(original);
      if (corrected.length >= 16) {
        final match = RegExp(r'(\d{16})').firstMatch(corrected);
        if (match != null && !candidates.any((c) => c.value == match.group(1))) {
          candidates.add(_NikCandidate(match.group(1)!, 'smart-corrected', 5));
        }
      }
    }

    // Strategy 5: Legacy aggressive correction (lowest priority, only if nothing else found)
    if (original.length >= 16 && candidates.isEmpty) {
      final corrected = _ocrDigitCorrection(original);
      if (corrected.length == 16 && RegExp(r'^\d{16}$').hasMatch(corrected)) {
        candidates.add(_NikCandidate(corrected, 'aggressive-corrected', 1));
      }
    }

    if (candidates.isEmpty) return null;

    return _pickBestNikCandidate(candidates);
  }

  String? _aggressiveNikClean(String text) {
    // Count actual digits and digit-like characters
    final digitCount = text.replaceAll(RegExp(r'[^0-9]'), '').length;
    final digitLikeCount = text.replaceAll(RegExp(r'[^0-9OoIlZSBG|]'), '').length;
    // Must have at least 10 actual digits and 14 digit-like chars
    if (digitCount < 10 || digitLikeCount < 14) return null;

    final candidates = <_NikCandidate>[];

    // Try smart correction first
    final smartCorrected = _smartOcrDigitCorrection(text);
    if (smartCorrected.length >= 16) {
      final match = RegExp(r'(\d{16})').firstMatch(smartCorrected);
      if (match != null) {
        candidates.add(_NikCandidate(match.group(1)!, 'aggressive-smart', 3));
      }
    }

    // Try legacy correction as fallback
    final corrected = _ocrDigitCorrection(text);
    if (corrected.length >= 16) {
      final match = RegExp(r'(\d{16})').firstMatch(corrected);
      if (match != null) {
        candidates.add(_NikCandidate(match.group(1)!, 'aggressive-legacy', 1));
      }
    }

    if (candidates.isEmpty) return null;

    return _pickBestNikCandidate(candidates);
  }

  String _ocrDigitCorrection(String text) {
    return text
        .replaceAll(RegExp(r'[\s.\-:,]'), '')
        .replaceAll(RegExp(r'[Oo]'), '0')
        .replaceAll(RegExp(r'[IilL|]'), '1')
        .replaceAll(RegExp(r'[Zz]'), '2')
        .replaceAll(RegExp(r'[Ss]'), '5')
        .replaceAll(RegExp(r'[Bb]'), '8')
        .replaceAll(RegExp(r'[Gg]'), '9')
        .replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// Context-aware OCR digit correction - only corrects characters
  /// that are surrounded by digits (not global replacement)
  String _smartOcrDigitCorrection(String text) {
    final cleaned = text.replaceAll(RegExp(r'[\s.\-:,]'), '');

    // Only apply if the string is mostly digit-like (>55%)
    final digitCount = cleaned.replaceAll(RegExp(r'[^0-9]'), '').length;
    if (cleaned.length < 14 || digitCount < cleaned.length * 0.55) return '';

    final buffer = StringBuffer();
    for (var i = 0; i < cleaned.length; i++) {
      final ch = cleaned[i];
      if (RegExp(r'[0-9]').hasMatch(ch)) {
        buffer.write(ch);
        continue;
      }

      // Check if this character is in a digit context
      final prevIsDigit = i > 0 && RegExp(r'[0-9]').hasMatch(cleaned[i - 1]);
      final nextIsDigit =
          i < cleaned.length - 1 && RegExp(r'[0-9]').hasMatch(cleaned[i + 1]);

      if (prevIsDigit || nextIsDigit) {
        switch (ch) {
          case 'O':
          case 'o':
          case 'Q':
          case 'D':
            buffer.write('0');
            break;
          case 'I':
          case 'i':
          case 'l':
          case 'L':
          case '|':
          case '!':
            buffer.write('1');
            break;
          case 'Z':
          case 'z':
            buffer.write('2');
            break;
          case 'E':
            buffer.write('3');
            break;
          case 'A':
          case 'h':
            buffer.write('4');
            break;
          case 'S':
          case 's':
            buffer.write('5');
            break;
          case 'b':
            buffer.write('6');
            break;
          case 'T':
          case 'J':
            buffer.write('7');
            break;
          case 'B':
            buffer.write('8');
            break;
          case 'g':
          case 'q':
            buffer.write('9');
            break;
          default:
            // Unknown char in digit context - skip it
            break;
        }
      }
      // Character NOT in digit context → skip entirely (don't include)
    }

    return buffer.toString();
  }

  /// Score how valid a 16-digit string is as an Indonesian NIK
  /// Returns 0-100 score
  int _scoreNikStructure(String nik) {
    if (nik.length != 16 || !RegExp(r'^\d{16}$').hasMatch(nik)) return 0;

    int score = 40; // base score for being 16 digits

    // Check province code (digits 1-2)
    final provinceCode = int.parse(nik.substring(0, 2));
    if (_validProvinceCodes.contains(provinceCode)) {
      score += 25;
    } else {
      score -= 20;
    }

    // Check kabupaten code (digits 3-4) - should be 01-99
    final kabCode = int.parse(nik.substring(2, 4));
    if (kabCode >= 1 && kabCode <= 99) {
      score += 5;
    }

    // Check kecamatan code (digits 5-6) - should be 01-99
    final kecCode = int.parse(nik.substring(4, 6));
    if (kecCode >= 1 && kecCode <= 99) {
      score += 5;
    }

    // Check birth date (digits 7-12): DDMMYY
    final day = int.parse(nik.substring(6, 8));
    final month = int.parse(nik.substring(8, 10));

    // Day 01-31 or 41-71 (female: day + 40)
    if ((day >= 1 && day <= 31) || (day >= 41 && day <= 71)) {
      score += 10;
    } else {
      score -= 15;
    }

    // Month 01-12
    if (month >= 1 && month <= 12) {
      score += 10;
    } else {
      score -= 15;
    }

    // Sequential number (digits 13-16) should not be 0000
    final seq = int.parse(nik.substring(12, 16));
    if (seq > 0) {
      score += 5;
    }

    return score.clamp(0, 100);
  }

  /// Pick the best NIK from a list of candidates using structural validation
  String? _pickBestNikCandidate(List<_NikCandidate> candidates) {
    if (candidates.isEmpty) return null;

    // Generate 5↔6 swap variants for each candidate (OCR commonly confuses them)
    final expanded = <_NikCandidate>[...candidates];
    for (final c in candidates) {
      expanded.addAll(_generate56SwapCandidates(c));
    }

    // Remove duplicates, keeping highest priority
    final unique = <String, _NikCandidate>{};
    for (final c in expanded) {
      if (!unique.containsKey(c.value) ||
          c.priorityBonus > unique[c.value]!.priorityBonus) {
        unique[c.value] = c;
      }
    }

    final sorted = unique.values.toList()
      ..sort((a, b) {
        final scoreA = _scoreNikStructure(a.value) + a.priorityBonus;
        final scoreB = _scoreNikStructure(b.value) + b.priorityBonus;
        return scoreB.compareTo(scoreA);
      });

    debugPrint('=== NIK candidates (${sorted.length}) ===');
    for (final c in sorted.take(8)) {
      debugPrint(
        '  ${c.source}: ${c.value} (struct=${_scoreNikStructure(c.value)}, bonus=${c.priorityBonus})',
      );
    }

    return sorted.first.value;
  }

  /// Generate NIK candidates by swapping 5↔6 at positions that contain them
  /// Only swaps in structurally significant positions (province, date) to limit explosion
  List<_NikCandidate> _generate56SwapCandidates(_NikCandidate original) {
    final nik = original.value;
    if (nik.length != 16 || !RegExp(r'^\d{16}$').hasMatch(nik)) return [];

    // Find positions with 5 or 6
    final swapPositions = <int>[];
    for (var i = 0; i < nik.length; i++) {
      if (nik[i] == '5' || nik[i] == '6') {
        swapPositions.add(i);
      }
    }

    if (swapPositions.isEmpty) return [];

    // Only generate single-swap variants to keep it manageable
    final results = <_NikCandidate>[];
    for (final pos in swapPositions) {
      final chars = nik.split('');
      chars[pos] = chars[pos] == '5' ? '6' : '5';
      final swapped = chars.join();
      // Only keep if the swap improves the structural score
      if (_scoreNikStructure(swapped) > _scoreNikStructure(nik)) {
        results.add(_NikCandidate(
          swapped,
          '${original.source}+swap56@$pos',
          original.priorityBonus - 2, // slightly lower priority than original
        ));
      }
    }

    // Also try double-swaps for the first 6 digits (region codes)
    // which are most affected by 5/6 confusion
    if (swapPositions.where((p) => p < 6).length >= 2) {
      final regionSwaps = swapPositions.where((p) => p < 6).toList();
      for (var i = 0; i < regionSwaps.length; i++) {
        for (var j = i + 1; j < regionSwaps.length; j++) {
          final chars = nik.split('');
          chars[regionSwaps[i]] = chars[regionSwaps[i]] == '5' ? '6' : '5';
          chars[regionSwaps[j]] = chars[regionSwaps[j]] == '5' ? '6' : '5';
          final swapped = chars.join();
          if (_scoreNikStructure(swapped) > _scoreNikStructure(nik)) {
            results.add(_NikCandidate(
              swapped,
              '${original.source}+swap56@${regionSwaps[i]},${regionSwaps[j]}',
              original.priorityBonus - 4,
            ));
          }
        }
      }
    }

    return results;
  }

  /// Extract best NIK from a list of text lines (used for raw block & raw image fallback)
  String? _extractBestNikFromLines(List<String> texts) {
    final candidates = <_NikCandidate>[];

    for (final text in texts) {
      final upper = text.toUpperCase();

      // Direct 16-digit match
      final exactMatches = RegExp(r'(\d{16})').allMatches(text);
      for (final m in exactMatches) {
        candidates.add(_NikCandidate(m.group(1)!, 'raw-exact', 18));
      }

      // After NIK label
      if (upper.contains('NIK') ||
          RegExp(r'\bWK\b|\bNK\b').hasMatch(upper)) {
        final afterNik = text.replaceFirst(
          RegExp(r'.*(NIK|WK|NK)\s*:?\s*', caseSensitive: false), '',
        );
        final cleaned = afterNik.replaceAll(RegExp(r'[\s.\-]'), '');
        if (cleaned.length >= 16) {
          final m = RegExp(r'(\d{16})').firstMatch(cleaned);
          if (m != null) {
            candidates.add(_NikCandidate(m.group(1)!, 'raw-nik-label', 14));
          }
        }
        final corrected = _smartOcrDigitCorrection(afterNik);
        if (corrected.length >= 16) {
          final m = RegExp(r'(\d{16})').firstMatch(corrected);
          if (m != null) {
            candidates.add(_NikCandidate(m.group(1)!, 'raw-nik-corrected', 8));
          }
        }
      }

      // Remove separators
      final noSep = text.replaceAll(RegExp(r'[\s.\-]'), '');
      if (noSep.length >= 16 && noSep.length <= 20) {
        final m = RegExp(r'(\d{16})').firstMatch(noSep);
        if (m != null && !candidates.any((c) => c.value == m.group(1))) {
          candidates.add(_NikCandidate(m.group(1)!, 'raw-no-sep', 16));
        }
      }

      // Smart correction
      if (text.length >= 14 && text.length <= 22) {
        final corrected = _smartOcrDigitCorrection(text);
        if (corrected.length >= 16) {
          final m = RegExp(r'(\d{16})').firstMatch(corrected);
          if (m != null && !candidates.any((c) => c.value == m.group(1))) {
            candidates.add(_NikCandidate(m.group(1)!, 'raw-smart', 4));
          }
        }
      }
    }

    if (candidates.isEmpty) return null;

    // Only accept candidates with reasonable structural score
    final best = _pickBestNikCandidate(candidates);
    if (best != null && _scoreNikStructure(best) >= 30) {
      return best;
    }

    return best;
  }

  bool _matchTtlLabel(String lineUpper) {
    return (lineUpper.contains('TEMPAT') && lineUpper.contains('LAHIR')) ||
           (lineUpper.contains('TERNPAT') && lineUpper.contains('LAHIR')) ||
           (lineUpper.contains('TEMPAT') && lineUpper.contains('TGL')) ||
           lineUpper.contains('TEMPAT/TGL') ||
           lineUpper.contains('TGL LAHIR') ||
           lineUpper.contains('TGL.LAHIR') ||
           lineUpper.contains('TGL/LAHIR') ||
           RegExp(r'\bTTL\b').hasMatch(lineUpper);
  }

  bool _isTtlValue(String value) {
    if (value.contains(',') &&
        RegExp(r'\d{1,2}[\s\-/]\d{1,2}[\s\-/]\d{2,4}').hasMatch(value)) {
      return true;
    }
    if (RegExp(r'^\s*\d{1,2}[\s\-/]\d{1,2}[\s\-/]\d{2,4}\s*$').hasMatch(value)) {
      return true;
    }
    return false;
  }

  void _parseTtlValue(String value, KtpData ktpData) {
    if (value.contains(',')) {
      final commaIndex = value.indexOf(',');
      final city = value.substring(0, commaIndex).trim();
      final dateStr = value.substring(commaIndex + 1).trim();
      if (ktpData.tempatLahir == null && city.isNotEmpty) {
        ktpData.tempatLahir = city;
      }
      if (ktpData.tanggalLahir == null) {
        ktpData.tanggalLahir = _extractDate(dateStr);
      }
    } else {
      final date = _extractDate(value);
      if (ktpData.tanggalLahir == null && date != null) {
        ktpData.tanggalLahir = date;
      }
    }
  }

  String? _extractValue(String line, String label) {
    if (label.isEmpty) {
      final colonIndex = line.indexOf(':');
      if (colonIndex != -1 && colonIndex < line.length - 1) {
        return line.substring(colonIndex + 1).trim();
      }
      return null;
    }

    final patterns = [
      RegExp('$label\\s*:\\s*(.+)', caseSensitive: false),
      RegExp('$label\\s+(.+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(line);
      if (match != null && match.group(1) != null) {
        final value = match.group(1)!.trim();
        if (value.isNotEmpty) return value;
      }
    }
    return null;
  }

  String? _extractDate(String text) {
    final dateMatch = RegExp(r'(\d{1,2})[\s\-/](\d{1,2})[\s\-/](\d{4})').firstMatch(text);
    if (dateMatch != null) {
      final day = dateMatch.group(1)!.padLeft(2, '0');
      final month = dateMatch.group(2)!.padLeft(2, '0');
      final year = dateMatch.group(3);
      return '$day-$month-$year';
    }
    return text.trim();
  }

  String? _extractRtRw(String line) {
    final match = RegExp(r'(\d{1,3})\s*/\s*(\d{1,3})').firstMatch(line);
    if (match != null) {
      final rt = match.group(1)!.padLeft(3, '0');
      final rw = match.group(2)!.padLeft(3, '0');
      return '$rt/$rw';
    }
    return null;
  }

  bool _isLabel(String text) {
    final labels = [
      'NIK', 'WK', 'NAMA', 'TEMPAT', 'LAHIR', 'JENIS', 'KELAMIN', 'KETAMIN',
      'ALAMAT', 'RT/RW', 'RT RW', 'RTRW', 'RI/RW', 'KEL/DESA', 'KEL DESA',
      'KELBESA', 'KELURAHAN', 'KECAMATAN', 'KEC', 'AGAMA', 'STATUS',
      'PERKAWINAN', 'PEKERJAAN', 'KEWARGANEGARAAN', 'BERLAKU', 'BERDAKU',
      'SEUMUR', 'GOL', 'DARAH', 'PROVINSI', 'KABUPATEN', 'KOTA', 'TTL', 'TGL'
    ];
    final upper = text.toUpperCase().trim();
    return labels.any((label) => upper.startsWith(label));
  }

  void dispose() {
    _textRecognizer.close();
  }
}

/// Helper class to hold a text line with its position
class _PositionedLine {
  final String text;
  final double top;
  final double left;
  final double bottom;
  final double height;

  _PositionedLine({
    required this.text,
    required this.top,
    required this.left,
    required this.bottom,
    required this.height,
  });
}

/// Helper class for NIK candidate scoring
class _NikCandidate {
  final String value;
  final String source;
  final int priorityBonus;

  _NikCandidate(this.value, this.source, this.priorityBonus);

  @override
  String toString() => '_NikCandidate($value, $source, +$priorityBonus)';
}
