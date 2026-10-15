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
      expect(
        find.text("Belum ada riwayat diagnosis. Lakukan tes pertama Anda hari ini!"),
        findsOneWidget,
      );
    });

    testWidgets('2. HistoryScreen renders empty state when historyList is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HistoryScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(
        find.text("Belum ada riwayat diagnosis. Lakukan tes pertama Anda hari ini!"),
        findsOneWidget,
      );
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

    testWidgets('5. Tapping Notification Bell opens modal with real notifications', (WidgetTester tester) async {
      // Add a notification first
      await notificationService.addNotificationToHistory(
        title: "Peringatan Tes",
        body: "Isi notifikasi tes",
        type: "warning",
      );

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

      // Verify modal opened and shows real notification from state
      expect(find.text("Notifikasi Sistem"), findsOneWidget);
      expect(find.text("Peringatan Tes"), findsOneWidget);
    });
  });
}
