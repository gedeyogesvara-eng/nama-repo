import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_app/screens/stage1_mental_screen.dart';
import 'package:frontend_app/screens/stage2_physical_screen.dart';
import 'package:frontend_app/screens/stage3_visual_screen.dart';
import 'package:frontend_app/screens/result_screen.dart';
import 'package:frontend_app/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'is_logged_in': false});
  });

  group('Screening Flow & Route Tests', () {
    testWidgets('Stage 1 renders and has continue button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Stage1MentalScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(Stage1MentalScreen), findsOneWidget);
      expect(find.text("Tahap 1: Draw & Talk"), findsOneWidget);
      expect(find.text("Lanjut ke Tahap 2 →"), findsOneWidget);
    });

    testWidgets('Stage 2 countdown sequence works: Bersiap... -> 3 -> 2 -> 1 -> Mulai!', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Stage2PhysicalScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));


      expect(find.text("Tahap 2: Gait Tracker"), findsOneWidget);
      expect(find.text("Mulai Berjalan (10 Detik)"), findsOneWidget);

      // Tap button to start countdown
      await tester.tap(find.text("Mulai Berjalan (10 Detik)"));
      await tester.pump();

      // Initial step shows 'Bersiap...'
      expect(find.text("Bersiap..."), findsOneWidget);

      // Advance 1s -> '3'
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("3"), findsOneWidget);

      // Advance 1s -> '2'
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("2"), findsOneWidget);

      // Advance 1s -> '1'
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("1"), findsOneWidget);

      // Advance 1s -> 'Mulai!'
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("Mulai!"), findsOneWidget);

      // Advance 1s -> Starts recording
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("Sedang Merekam Langkah..."), findsOneWidget);

      // Unmount to cleanly cancel active timers
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('Stage 3 renders camera button and gallery picker button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Stage3VisualScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text("Tahap 3: Visual & Sclera Scan"), findsOneWidget);
      expect(find.text("Buka Kamera (Ambil Foto)"), findsOneWidget);
      expect(find.text("📁 Pilih dari Galeri"), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    test('AIService fallback returns complete diagnosis when offline', () {
      final fallback = AIService.getFallbackDetectionData();
      expect(fallback['status'], equals('success'));
      expect(fallback['data_skrining'], isNotNull);
      expect(fallback['ai_recipes'], isNotEmpty);
      expect(fallback['data_skrining']['kategori_burnout'], isNotEmpty);
    });

    testWidgets('ResultScreen renders successfully with default/fallback data', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ResultScreen), findsOneWidget);
    });
  });
}
