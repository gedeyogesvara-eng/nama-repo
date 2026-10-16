import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_app/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('HomeScreen Interactive Theme Switcher Tests', () {
    testWidgets('1. HomeScreen renders initially in Dark Mode with lukisan_malam.svg', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(initialDarkMode: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text("Beranda Utama"), findsOneWidget);
      expect(find.text("Nama Aplikasi"), findsOneWidget);
      expect(find.text("Maintain your emotions"), findsOneWidget);
      expect(find.text("Skrining"), findsOneWidget);
      expect(find.text("Riwayat"), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_outlined), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);

      // Check SvgPicture is rendered
      expect(find.byType(SvgPicture), findsWidgets);
    });

    testWidgets('2. Tapping interactive painting toggles between Dark Mode and Light Mode', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(initialDarkMode: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      // Tap on the painting
      await tester.tap(find.byType(SvgPicture).first);
      // Wait for 550ms AnimatedSwitcher to complete
      await tester.pump(const Duration(milliseconds: 800));

      // Should now show snackbar for Light Mode / Mode Siang
      expect(find.text("Beralih ke Tema Terang (Siang)"), findsOneWidget);

      // Tap again to switch back to Dark Mode
      await tester.tap(find.byType(SvgPicture).last);
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text("Beralih ke Tema Gelap (Malam)"), findsOneWidget);
    });

    testWidgets('3. Tapping Notification Bell opens notifications modal', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(initialDarkMode: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      final bellFinder = find.byIcon(Icons.notifications_active_outlined);
      expect(bellFinder, findsOneWidget);

      await tester.tap(bellFinder);
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text("Notifikasi Sistem"), findsOneWidget);
    });

    testWidgets('4. Tapping Logout shows confirmation dialog', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 900));
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(initialDarkMode: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 600));

      final logoutFinder = find.byIcon(Icons.logout_rounded);
      expect(logoutFinder, findsOneWidget);

      await tester.ensureVisible(logoutFinder);
      await tester.tap(logoutFinder);
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text("Konfirmasi Keluar"), findsOneWidget);
      expect(find.text("Batal"), findsOneWidget);
      expect(find.text("Keluar"), findsOneWidget);
    });
  });
}
