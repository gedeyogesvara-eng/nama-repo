import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/main.dart';
import 'package:frontend_app/screens/welcome_screen.dart';
import 'package:frontend_app/screens/stage1_mental_screen.dart';
import 'package:frontend_app/screens/stage2_physical_screen.dart';
import 'package:frontend_app/screens/result_screen.dart';
import 'package:frontend_app/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Screening Flow & Route Tests', () {
    testWidgets('Stage 1 renders and has continue button', (WidgetTester tester) async {
      await tester.pumpWidget(const DepressionDetectionApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(WelcomeScreen));
      Navigator.pushNamed(context, '/stage1');
      await tester.pumpAndSettle();

      expect(find.byType(Stage1MentalScreen), findsOneWidget);
      expect(find.text("Tahap 1: Draw & Talk"), findsOneWidget);
      expect(find.text("Lanjut ke Tahap 2 →"), findsOneWidget);
    });

    testWidgets('Stage 1 to Stage 2 button transitions properly', (WidgetTester tester) async {
      await tester.pumpWidget(const DepressionDetectionApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(WelcomeScreen));
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const Stage1MentalScreen()),
      );
      await tester.pumpAndSettle();

<<<<<<< HEAD
      // Tap button Lanjut ke Tahap 2
      final continueButton = find.text("Lanjut ke Tahap 2 →");
      expect(continueButton, findsOneWidget);
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      for (final w in find.byType(Widget).evaluate()) {
        if (w.widget.runtimeType.toString().contains('Stage')) {
          debugPrint("FOUND STAGE WIDGET: ${w.widget.runtimeType}");
        }
      }

      // Harus berpindah ke Stage 2
      expect(find.byType(Stage2PhysicalScreen), findsOneWidget);
=======

>>>>>>> db2c97a0d2c07050246713beb2ec9a3f1bd32ba9
      expect(find.text("Tahap 2: Gait Tracker"), findsOneWidget);
    });

    test('AIService fallback returns complete diagnosis when offline', () {
      final fallback = AIService.getFallbackDetectionData();
      expect(fallback['status'], equals('success'));
      expect(fallback['data_skrining'], isNotNull);
      expect(fallback['ai_recipes'], isNotEmpty);
      expect(fallback['data_skrining']['kategori_burnout'], isNotEmpty);
    });

    testWidgets('ResultScreen renders successfully with default/fallback data', (WidgetTester tester) async {
      await tester.pumpWidget(const DepressionDetectionApp());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(WelcomeScreen));
      Navigator.pushNamed(context, '/result');
      await tester.pumpAndSettle();

      expect(find.byType(ResultScreen), findsOneWidget);
    });
  });
}
