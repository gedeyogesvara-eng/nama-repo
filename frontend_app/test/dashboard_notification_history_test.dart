import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_app/screens/dashboard_screen.dart';
import 'package:frontend_app/screens/history_screen.dart';
import 'package:frontend_app/services/history_service.dart';
import 'package:frontend_app/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dashboard, History & Notification Tests', () {
    testWidgets('1. Dashboard renders empty state when historyList is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.text("EMO-SENSE AI"), findsOneWidget);
      expect(find.textContaining("Goals"), findsWidgets);
    });

    testWidgets('2. HistoryScreen renders empty state when historyList is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(find.text("Riwayat Skrining"), findsOneWidget);
    });

    test('3. AIService inserts diagnosis into historyList and saves to SharedPreferences', () async {
      final mockApiResponse = {
        'status': 'success',
        'data_skrining': {
          'id_skrining': 'SCR-TEST-001',
          'kategori_burnout': 'Kondisi Prima (Sehat)',
          'tingkat_depresi': 'Kondisi Prima (Sehat)',
          'skor_akustik': 90,
          'skor_motorik': 88,
          'skor_sklera': 92,
        },
      };

      final saved = await HistoryService.addDiagnosisFromApi(mockApiResponse);
      expect(saved, isNotEmpty);
      expect(saved['title'], equals('Kondisi Prima (Sehat)'));

      final list = await HistoryService.getHistoryList();
      expect(list.length, equals(1));
      expect(list.first['id'], equals('SCR-TEST-001'));
    });

    test('4. NotificationService records and retrieves real notification state', () async {
      await notificationService.clearNotificationHistory();
      var history = await notificationService.getNotificationHistory();
      expect(history, isEmpty);

      // Trigger zombie warning notification
      await notificationService.showZombieWarningNotification();
      history = await notificationService.getNotificationHistory();
      expect(history.length, equals(1));
      expect(history.first['type'], equals('warning'));
      expect(history.first['title'], contains('Zombie/Burnout'));

      // Trigger schedule 24h reminder
      await notificationService.scheduleNextDayReminder();
      history = await notificationService.getNotificationHistory();
      expect(history.length, equals(2));
      expect(history.first['type'], equals('reminder'));
    });

    testWidgets('5. Tapping Notification Bell shows reminder SnackBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Notification Bell icon
      final bellFinder = find.byIcon(Icons.notifications_active_outlined);
      expect(bellFinder, findsOneWidget);
      await tester.tap(bellFinder);
      await tester.pumpAndSettle();

      expect(find.text("Pengingat skrining aktif setiap jam 19.00 WIB"), findsOneWidget);
    });

    test('6. NotificationService zoned scheduling for screening and goals', () async {
      await notificationService.clearNotificationHistory();

      // Jadwalkan skrining
      final screeningTime = DateTime.now().add(const Duration(hours: 2));
      await notificationService.scheduleScreeningReminder(
        screeningDateTime: screeningTime,
        minutesBefore: 15,
      );

      var history = await notificationService.getNotificationHistory();
      expect(history.length, equals(1));
      expect(history.first['title'], equals('Yuk, luangkan waktu sejenak untuk skrining!'));
      expect(history.first['body'], contains('15 menit'));

      // Jadwalkan goal routine reminder
      await notificationService.scheduleGoalReminder(
        goalId: 42,
        goalTitle: 'Detoks Layar 30 Menit',
        time: const TimeOfDay(hour: 20, minute: 0),
      );

      history = await notificationService.getNotificationHistory();
      expect(history.length, equals(2));
      expect(history.first['title'], equals('Waktunya menyelesaikan goals pemulihanmu hari ini!'));
      expect(history.first['body'], contains('Detoks Layar 30 Menit'));

      // Test cancel goal reminder
      await notificationService.cancelGoalReminder(42);
    });
  });
}
