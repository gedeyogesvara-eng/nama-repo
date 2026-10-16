import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:frontend_app/services/activity_sensor_service.dart';
import 'package:frontend_app/services/eye_analysis_service.dart';
import 'package:frontend_app/widgets/eye_validation_dialog.dart';

void main() {
  group('1. Modul 3: Activity Sensor Service & Data Parsing Tests', () {
    test('ActivityAnalysisResult parses successful JSON response properly', () {
      final json = {
        "status": "success",
        "data": {
          "label": "Berlari (Langkah Cepat/Guncangan Tinggi)",
          "confidence": 98.5
        }
      };

      final result = ActivityAnalysisResult.fromJson(json);

      expect(result.isSuccess, isTrue);
      expect(result.label, equals("Berlari (Langkah Cepat/Guncangan Tinggi)"));
      expect(result.confidence, equals(98.5));
      expect(result.errorMessage, isNull);
    });

    test('ActivitySensorService rejects invalid sensor array dimensions without making HTTP request', () async {
      // Hanya 5 baris, padahal wajib 150 baris
      final invalidData = List.generate(5, (_) => [0.1, 9.8, 0.2]);

      final result = await ActivitySensorService.sendSensorDataToAI(
        sensorData: invalidData,
        ipServerAi: '127.0.0.1',
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('150x3'));
    });

    test('ActivitySensorService sends HTTP POST with formatted 150x3 JSON body', () async {
      final validData = List.generate(150, (i) => [i * 0.1, 9.81, 0.05]);

      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/api/analyze-activity'));
        expect(request.headers['Content-Type'], contains('application/json'));

        final body = jsonDecode(request.body);
        expect(body['sensor_data'], isA<List>());
        expect((body['sensor_data'] as List).length, equals(150));
        expect((body['sensor_data'] as List).first.length, equals(3));

        return http.Response(
          jsonEncode({
            "status": "success",
            "data": {
              "label": "Berlari (Langkah Cepat/Guncangan Tinggi)",
              "confidence": 98.5
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final result = await ActivitySensorService.sendSensorDataToAI(
        sensorData: validData,
        ipServerAi: '127.0.0.1',
        client: mockClient,
      );

      expect(result.isSuccess, isTrue);
      expect(result.label, equals("Berlari (Langkah Cepat/Guncangan Tinggi)"));
      expect(result.confidence, equals(98.5));
    });
  });

  group('2. Modul 1: Eye Analysis Validation & Error Handling Tests', () {
    test('Valid eye response produces isValidEye = true and validationError = none', () {
      final json = {
        "status": "success",
        "data": {
          "label": "Normal (Sehat)",
          "confidence": 94.2,
          "visual_score": 15.0,
          "raw_prediction": 0.942
        }
      };

      final result = EyeAnalysisResult.fromJson(json);

      expect(result.isValidEye, isTrue);
      expect(result.isTooDark, isFalse);
      expect(result.isEyeNotDetected, isFalse);
      expect(result.confidence, equals(94.2));
      expect(result.validationError, equals(EyeValidationError.none));
    });

    test('Backend response with confidence: 0 and "Gambar terlalu gelap/hitam total" flags isTooDark', () {
      final json = {
        "status": "success",
        "data": {
          "label": "Gambar terlalu gelap/hitam total",
          "confidence": 0
        }
      };

      final result = EyeAnalysisResult.fromJson(json);

      // KUNCI: Tidak boleh dianggap valid / normal!
      expect(result.isValidEye, isFalse);
      expect(result.isTooDark, isTrue);
      expect(result.isEyeNotDetected, isFalse);
      expect(result.validationError, equals(EyeValidationError.imageTooDark));
      expect(result.feedbackTitle, contains('Terlalu Gelap'));
      expect(result.feedbackInstruction, contains('terlalu gelap'));
    });

    test('Backend response with confidence: 0 and "Mata tidak terdeteksi pada gambar" flags isEyeNotDetected', () {
      final json = {
        "status": "success",
        "data": {
          "label": "Mata tidak terdeteksi pada gambar",
          "confidence": 0
        }
      };

      final result = EyeAnalysisResult.fromJson(json);

      expect(result.isValidEye, isFalse);
      expect(result.isTooDark, isFalse);
      expect(result.isEyeNotDetected, isTrue);
      expect(result.validationError, equals(EyeValidationError.eyeNotDetected));
      expect(result.feedbackTitle, contains('Mata Tidak Terdeteksi'));
    });

    testWidgets('EyeValidationDialog renders correct UI and handles onRetake callback', (WidgetTester tester) async {
      bool retakeCalled = false;
      final darkResult = EyeAnalysisResult.fromJson({
        "status": "success",
        "data": {
          "label": "Gambar terlalu gelap/hitam total",
          "confidence": 0
        }
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EyeValidationDialog(
              result: darkResult,
              onRetake: () {
                retakeCalled = true;
              },
            ),
          ),
        ),
      );

      // Pastikan teks judul dan instruksi muncul
      expect(find.text('Pencahayaan Terlalu Gelap'), findsOneWidget);
      expect(find.textContaining('terlalu gelap atau hitam total'), findsOneWidget);
      expect(find.text('Ambil Ulang'), findsOneWidget);

      // Tekan tombol 'Ambil Ulang'
      await tester.tap(find.text('Ambil Ulang'));
      await tester.pump();

      expect(retakeCalled, isTrue);
    });
  });
}
