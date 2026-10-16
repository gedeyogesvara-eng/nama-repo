import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_app/main.dart';
import 'package:frontend_app/theme/theme_controller.dart';
import 'package:frontend_app/screens/dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await themeController.init();
    await themeController.setThemeMode(ThemeMode.light);
  });

  group('Dynamic ThemeMode & Settings Dark Mode Toggle Tests', () {
    testWidgets('1. ThemeController initializes with Light Mode and toggles to Dark Mode', (WidgetTester tester) async {
      expect(themeController.isDarkMode, isFalse);
      expect(themeController.themeModeNotifier.value, equals(ThemeMode.light));

      await themeController.setThemeMode(ThemeMode.dark);
      expect(themeController.isDarkMode, isTrue);
      expect(themeController.themeModeNotifier.value, equals(ThemeMode.dark));

      await themeController.toggleTheme();
      expect(themeController.isDarkMode, isFalse);
      expect(themeController.themeModeNotifier.value, equals(ThemeMode.light));
    });

    testWidgets('2. DepressionDetectionApp provides darkTheme with #121212 scaffoldBg and #314BB5 Deep Blue primary', (WidgetTester tester) async {
      await tester.pumpWidget(const DepressionDetectionApp());
      await tester.pumpAndSettle();

      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);

      final MaterialApp app = tester.widget(materialAppFinder);
      expect(app.darkTheme, isNotNull);
      expect(app.darkTheme!.scaffoldBackgroundColor, equals(const Color(0xFF121212)));
      expect(app.darkTheme!.colorScheme.primary, equals(const Color(0xFF314BB5)));
      expect(app.darkTheme!.colorScheme.surface, equals(const Color(0xFF1E1E1E)));
      expect(app.darkTheme!.colorScheme.onSurface, equals(Colors.white));

      // Light theme
      expect(app.theme!.scaffoldBackgroundColor, equals(const Color(0xFFF2F1EB)));
      expect(app.theme!.colorScheme.primary, equals(const Color(0xFF314BB5)));
    });

    testWidgets('3. Profile Settings modal contains Dark Mode Switch and toggle buttons', (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(480, 950));
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on profile avatar header to open settings modal
      final avatarFinder = find.byIcon(Icons.person_outline_rounded).first;
      expect(avatarFinder, findsOneWidget);
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      // Verify Modal opens
      expect(find.text('Profil & Akun Pengguna'), findsOneWidget);
      expect(find.text('Mode Gelap (Dark Mode)'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Tema Terang'), findsOneWidget);
      expect(find.text('Tema Gelap'), findsOneWidget);

      // Tap Switch to enable Dark Mode
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(themeController.isDarkMode, isTrue);

      // Tap "Tema Terang" button to switch back to Light Mode
      await tester.tap(find.text('Tema Terang'));
      await tester.pumpAndSettle();
      expect(themeController.isDarkMode, isFalse);

      // Tap "Tema Gelap" button to switch to Dark Mode
      await tester.tap(find.text('Tema Gelap'));
      await tester.pumpAndSettle();
      expect(themeController.isDarkMode, isTrue);
    });
  });
}
