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
      expect(find.text("Tahap 1: Curhat Suara"), findsOneWidget);
      expect(find.text("Lanjut ke Tahap 2 →"), findsOneWidget);
    });

    testWidgets('Stage 2 shows countdown 3, 2, 1, Mulai! before 10s recording starts', (WidgetTester tester) async {
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

      // Fase aba-aba pertama: '3'
      expect(find.text("3"), findsOneWidget);
      expect(find.text("Fase Aba-aba Berjalan"), findsOneWidget);
      expect(find.text("Bersiap Melangkah (3)..."), findsOneWidget);

      // Setelah 1 detik: '2'
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("2"), findsOneWidget);
      expect(find.text("Bersiap Melangkah (2)..."), findsOneWidget);

      // Setelah 1 detik: '1'
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("1"), findsOneWidget);
      expect(find.text("Bersiap Melangkah (1)..."), findsOneWidget);

      // Setelah 1 detik: 'Mulai!'
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("Mulai!"), findsOneWidget);
      expect(find.text("Mulai Melangkah!"), findsWidgets);

      // Setelah 'Mulai!' selesai ditampilkan (1 detik), BARULAH perekaman sensor berjalan
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("Sedang Merekam Langkah..."), findsOneWidget);
      expect(find.text("10s"), findsOneWidget);

      // Perekaman sensor berjalan selama 10 detik (misal turun ke 9s)
      await tester.pump(const Duration(seconds: 1));
      expect(find.text("9s"), findsOneWidget);

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

      expect(find.text("Tahap 3: Foto Mata"), findsOneWidget);
      expect(find.text("Ambil Foto Mata"), findsOneWidget);
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

    testWidgets('ResultScreen renders successfully with relaxation suggestion button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ResultScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ResultScreen), findsOneWidget);
      expect(find.text("Mari Rileks Sejenak"), findsOneWidget);
    });
  });
}
