import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sensors_plus/sensors_plus.dart';

/// Model respons hasil analisis aktivitas dari Somatic.AI Modul 3
class ActivityAnalysisResult {
  final bool isSuccess;
  final String label;
  final double confidence;
  final String? errorMessage;
  final Map<String, dynamic>? rawData;

  const ActivityAnalysisResult({
    required this.isSuccess,
    required this.label,
    required this.confidence,
    this.errorMessage,
    this.rawData,
  });

  factory ActivityAnalysisResult.fromJson(Map<String, dynamic> json) {
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

      return ActivityAnalysisResult(
        isSuccess: true,
        label: data['label']?.toString() ?? 'Aktivitas Tidak Dikenali',
        confidence: parsedConfidence,
        rawData: data,
      );
    }

    return ActivityAnalysisResult(
      isSuccess: false,
      label: 'Gagal menganalisis aktivitas',
      confidence: 0.0,
      errorMessage: json['message']?.toString() ?? 'Respons server tidak valid.',
      rawData: json,
    );
  }

  factory ActivityAnalysisResult.error(String message) {
    return ActivityAnalysisResult(
      isSuccess: false,
      label: 'Error',
      confidence: 0.0,
      errorMessage: message,
    );
  }

  @override
  String toString() =>
      'ActivityAnalysisResult(isSuccess: $isSuccess, label: "$label", confidence: $confidence%)';
}

/// Service untuk merekam data Accelerometer HP dan mengirimkannya ke
/// Somatic.AI Core Engine (FastAPI) Modul 3 (/api/analyze-activity).
class ActivitySensorService {
  /// Target jumlah baris data yang diminta oleh model 1D CNN: 150 baris x 3 kolom [X, Y, Z]
  static const int targetSampleCount = 150;

  /// Target frekuensi: 50 data/detik (setiap 20 milidetik)
  static const Duration defaultSamplingInterval = Duration(milliseconds: 20);

  /// Merekam data akselerometer selama 3 detik (atau hingga 150 sampel terkumpul).
  ///
  /// Mengembalikan array 2D [List<List<double>>] berdimensi tepat 150x3.
  /// [onProgress] menyediakan callback untuk mengupdate UI (contoh progress bar / count).
  static Future<List<List<double>>> recordAccelerometerData({
    Duration duration = const Duration(seconds: 3),
    Duration samplingInterval = defaultSamplingInterval,
    void Function(int currentCount, int targetCount)? onProgress,
  }) async {
    final completer = Completer<List<List<double>>>();
    final List<List<double>> samples = [];
    StreamSubscription<AccelerometerEvent>? subscription;
    Timer? timeoutTimer;

    void finishRecording() {
      if (completer.isCompleted) return;
      timeoutTimer?.cancel();
      subscription?.cancel();

      // Defensive handling: Pastikan hasil akhir tepat berdimensi 150 baris
      final List<List<double>> formattedSamples = List<List<double>>.from(samples);

      if (formattedSamples.length > targetSampleCount) {
        // Pangkas jika lebih dari 150
        formattedSamples.removeRange(targetSampleCount, formattedSamples.length);
      } else if (formattedSamples.length < targetSampleCount) {
        // Interpolasi/padding sampel terakhir jika perangkat mengirim kurang dari 150 dalam 3 detik
        final lastSample = formattedSamples.isNotEmpty
            ? formattedSamples.last
            : const [0.0, 9.81, 0.0]; // Gravitasi bumi default
        while (formattedSamples.length < targetSampleCount) {
          formattedSamples.add(List<double>.from(lastSample));
        }
      }

      completer.complete(formattedSamples);
    }

    try {
      // Stream accelerometer dengan interval 20ms (50Hz)
      final stream = accelerometerEventStream(samplingPeriod: samplingInterval);

      subscription = stream.listen(
        (event) {
          if (completer.isCompleted) return;

          samples.add([
            double.parse(event.x.toStringAsFixed(4)),
            double.parse(event.y.toStringAsFixed(4)),
            double.parse(event.z.toStringAsFixed(4)),
          ]);

          onProgress?.call(samples.length, targetSampleCount);

          // Hentikan tepat setelah terkumpul 150 data
          if (samples.length >= targetSampleCount) {
            finishRecording();
          }
        },
        onError: (error) {
          debugPrint('⚠️ [ActivitySensorService] Sensor error: $error');
          finishRecording();
        },
        cancelOnError: true,
      );

      // Batas waktu keamanan (3 detik + toleransi 500ms)
      timeoutTimer = Timer(duration + const Duration(milliseconds: 500), () {
        finishRecording();
      });
    } catch (e) {
      debugPrint('⚠️ [ActivitySensorService] Tidak dapat membuka sensor stream: $e');
      finishRecording();
    }

    return completer.future;
  }

  /// Mengirimkan data sensor akselerometer (150x3) via HTTP POST
  /// ke endpoint: http://<IP_SERVER_AI>:5000/api/analyze-activity
  static Future<ActivityAnalysisResult> sendSensorDataToAI({
    required List<List<double>> sensorData,
    required String ipServerAi,
    int port = 5000,
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    // Validasi dimensi sebelum dikirim
    if (sensorData.length != targetSampleCount ||
        sensorData.any((row) => row.length != 3)) {
      return ActivityAnalysisResult.error(
        'Dimensi data salah (${sensorData.length}x${sensorData.isNotEmpty ? sensorData[0].length : 0}). '
        'Wajib berdimensi 150x3.',
      );
    }

    final cleanIp = ipServerAi.trim().replaceAll(RegExp(r'^https?://|/+$'), '');
    final uri = Uri.parse('http://$cleanIp:$port/api/analyze-activity');
    final httpClient = client ?? http.Client();

    try {
      final requestBody = jsonEncode({
        "sensor_data": sensorData,
      });

      debugPrint('🚀 [ActivitySensorService] POST $uri (150 sampel data)');

      final response = await httpClient
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: requestBody,
          )
          .timeout(timeout);

      debugPrint('📥 [ActivitySensorService] HTTP ${response.statusCode}: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return ActivityAnalysisResult.fromJson(decoded);
      } else {
        return ActivityAnalysisResult.error(
          'Server merespons HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } on TimeoutException {
      return ActivityAnalysisResult.error(
        'Koneksi timeout ke server AI ($uri). Pastikan server FastAPI berjalan.',
      );
    } catch (e) {
      return ActivityAnalysisResult.error('Gagal menghubungi server AI: $e');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Helper komprehensif: Rekam sensor 3 detik lalu langsung kirim ke server AI
  static Future<ActivityAnalysisResult> recordAndAnalyze({
    required String ipServerAi,
    int port = 5000,
    void Function(int currentCount, int targetCount)? onProgress,
    http.Client? client,
  }) async {
    final sensorData = await recordAccelerometerData(onProgress: onProgress);
    return await sendSensorDataToAI(
      sensorData: sensorData,
      ipServerAi: ipServerAi,
      port: port,
      client: client,
    );
  }
}
