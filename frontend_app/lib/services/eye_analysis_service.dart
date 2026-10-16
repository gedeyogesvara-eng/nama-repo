import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Tipe kegagalan validasi foto mata
enum EyeValidationError {
  none,
  imageTooDark,
  eyeNotDetected,
  corruptedImage,
  serverError,
}

/// Model respons hasil analisis mata / sklera dari Somatic.AI Modul 1
class EyeAnalysisResult {
  final bool isSuccess;
  final String label;
  final double confidence;
  final double? visualScore;
  final double? rawPrediction;
  final String? errorMessage;
  final EyeValidationError validationError;

  const EyeAnalysisResult({
    required this.isSuccess,
    required this.label,
    required this.confidence,
    this.visualScore,
    this.rawPrediction,
    this.errorMessage,
    this.validationError = EyeValidationError.none,
  });

  /// Menentukan apakah foto mata berhasil dideteksi dengan benar oleh AI
  /// (bukan foto gelap dan bukan mata tak terdeteksi)
  bool get isValidEye =>
      isSuccess && confidence > 0.0 && validationError == EyeValidationError.none;

  /// Indikasi foto terlalu gelap atau hitam pekat
  bool get isTooDark => validationError == EyeValidationError.imageTooDark;

  /// Indikasi mata/sklera tidak ditemukan pada foto
  bool get isEyeNotDetected => validationError == EyeValidationError.eyeNotDetected;

  /// Judul pesan ramah untuk UI
  String get feedbackTitle {
    switch (validationError) {
      case EyeValidationError.imageTooDark:
        return 'Pencahayaan Terlalu Gelap';
      case EyeValidationError.eyeNotDetected:
        return 'Mata Tidak Terdeteksi';
      case EyeValidationError.corruptedImage:
        return 'Format Foto Tidak Sesuai';
      case EyeValidationError.serverError:
        return 'Gagal Memproses Foto';
      case EyeValidationError.none:
        return 'Analisis Berhasil';
    }
  }

  /// Instruksi langkah perbaikan untuk ditampilkan kepada pengguna di UI
  String get feedbackInstruction {
    switch (validationError) {
      case EyeValidationError.imageTooDark:
        return 'Foto yang kamu ambil terlalu gelap atau hitam total. '
            'Silakan pindah ke ruangan yang lebih terang atau nyalakan lampu, lalu ambil ulang fotomu.';
      case EyeValidationError.eyeNotDetected:
        return 'Sistem tidak dapat menemukan posisi mata pada foto. '
            'Pastikan wajahmu menghadap lurus ke kamera dan buka matamu dengan jelas.';
      case EyeValidationError.corruptedImage:
        return 'Berkas foto tidak dapat dibaca oleh sistem. Silakan pilih atau ambil foto baru.';
      case EyeValidationError.serverError:
        return errorMessage ?? 'Terjadi kendala saat menghubungi server AI. Silakan coba sesaat lagi.';
      case EyeValidationError.none:
        return 'Mata berhasil dianalisis dengan tingkat keyakinan $confidence%.';
    }
  }

  factory EyeAnalysisResult.fromJson(Map<String, dynamic> json) {
    final status = json['status']?.toString().toLowerCase();

    if (status == 'success' && json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      final rawConfidence = data['confidence'];
      double parsedConfidence = 0.0;
      if (rawConfidence is num) {
        parsedConfidence = rawConfidence.toDouble();
      } else if (rawConfidence is String) {
        parsedConfidence = double.tryParse(rawConfidence) ?? 0.0;
      }

      final label = data['label']?.toString() ?? '';
      final lowerLabel = label.toLowerCase();

      // VALIDASI KRUSIAL: Backend mengirimkan status: "success", namun confidence: 0
      // dengan label khusus jika foto gelap atau mata tidak ditemukan
      EyeValidationError validationError = EyeValidationError.none;
      if (lowerLabel.contains('terlalu gelap') || lowerLabel.contains('hitam total')) {
        validationError = EyeValidationError.imageTooDark;
      } else if (lowerLabel.contains('tidak terdeteksi') || lowerLabel.contains('tidak ditemukan')) {
        validationError = EyeValidationError.eyeNotDetected;
      } else if (parsedConfidence == 0.0) {
        // Fallback jika backend mengirim confidence 0 tanpa string label spesifik di atas
        validationError = EyeValidationError.eyeNotDetected;
      }

      return EyeAnalysisResult(
        isSuccess: true,
        label: label,
        confidence: parsedConfidence,
        visualScore: (data['visual_score'] as num?)?.toDouble(),
        rawPrediction: (data['raw_prediction'] as num?)?.toDouble(),
        validationError: validationError,
      );
    }

    final message = json['message']?.toString() ?? 'Respons server tidak dikenali.';
    return EyeAnalysisResult(
      isSuccess: false,
      label: 'Error',
      confidence: 0.0,
      errorMessage: message,
      validationError: message.toLowerCase().contains('korup')
          ? EyeValidationError.corruptedImage
          : EyeValidationError.serverError,
    );
  }

  factory EyeAnalysisResult.error(String message) {
    return EyeAnalysisResult(
      isSuccess: false,
      label: 'Error',
      confidence: 0.0,
      errorMessage: message,
      validationError: EyeValidationError.serverError,
    );
  }

  @override
  String toString() =>
      'EyeAnalysisResult(isValid: $isValidEye, label: "$label", confidence: $confidence%, error: $validationError)';
}

/// Service untuk mengirim foto mata ke endpoint /api/analyze-eye
/// dan memvalidasi kejelasan foto sebelum masuk ke tahap diagnosis.
class EyeAnalysisService {
  /// Mengirim foto mata (bytes) ke endpoint: http://<IP_SERVER_AI>:5000/api/analyze-eye
  static Future<EyeAnalysisResult> analyzeEyeImage({
    required Uint8List imageBytes,
    required String ipServerAi,
    int port = 5000,
    String filename = 'eye_capture.jpg',
    http.Client? client,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    if (imageBytes.isEmpty) {
      return EyeAnalysisResult.error('Foto tidak boleh kosong.');
    }

    final cleanIp = ipServerAi.trim().replaceAll(RegExp(r'^https?://|/+$'), '');
    final uri = Uri.parse('http://$cleanIp:$port/api/analyze-eye');
    final httpClient = client ?? http.Client();

    try {
      final request = http.MultipartRequest('POST', uri);
      request.headers['Accept'] = 'application/json';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: filename,
        ),
      );

      debugPrint('🚀 [EyeAnalysisService] Mengunggah foto mata (${imageBytes.length} bytes) ke $uri');

      final streamedResponse = await httpClient.send(request).timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('📥 [EyeAnalysisService] HTTP ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return EyeAnalysisResult.fromJson(decoded);
      } else {
        return EyeAnalysisResult.error('Server merespons status ${response.statusCode}: ${response.body}');
      }
    } on TimeoutException {
      return EyeAnalysisResult.error(
        'Koneksi timeout ke server AI ($uri). Pastikan server FastAPI berjalan.',
      );
    } catch (e) {
      return EyeAnalysisResult.error('Gagal mengirim foto mata: $e');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
