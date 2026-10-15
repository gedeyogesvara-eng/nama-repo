import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_app/main.dart';
import 'package:frontend_app/services/ai_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App smoke test loads successfully and handles splash delay', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const DepressionDetectionApp());
    expect(find.byType(DepressionDetectionApp), findsOneWidget);

    // Majukan waktu timer splash screen (1800 ms) agar timer selesai
    await tester.pump(const Duration(milliseconds: 2000));
    await tester.pump();
  });

  test('AIService defaultEndpoint resolves to local IPv4 for mobile', () {
    expect(AIService.localIPv4, isNotEmpty);
    expect(AIService.defaultEndpoint, contains(':5000/api/detect'));
    expect(
      AIService.defaultEndpoint,
      equals('http://${AIService.localIPv4}:5000/api/detect'),
    );
  });
}
