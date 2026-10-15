import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    authService.client = MockClient((request) async {
      if (request.url.path == '/api/register' || request.url.path == '/api/login') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final email = body['email'] ?? 'user@example.com';
        final name = body['full_name'] ?? (email as String).split('@').first;
        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'OK',
            'user': {
              'user_id': 1,
              'full_name': name,
              'email': email,
              'recovery_score': 50,
              'zombie_stage': 'RECOVERING_HUMAN',
            },
          }),
          200,
        );
      }
      if (request.url.path == '/api/login/google-demo') {
        return http.Response(
          jsonEncode({
            'status': 'success',
            'message': 'OK',
            'user': {
              'user_id': 2,
              'full_name': 'Maulana Demo',
              'email': 'maul@gmail.com',
              'recovery_score': 65,
              'zombie_stage': 'RECOVERING_HUMAN',
            },
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'status': 'error', 'message': 'Not found'}), 404);
    });
  });

  group('AuthService Tests', () {
    test('Registrasi berhasil menyimpan profil pengguna maul', () async {
      final success = await authService.registerWithEmail(
        'maul@gmail.com',
        'password123',
        name: 'maul',
      );

      expect(success, isTrue);
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser!.displayName, equals('maul'));
      expect(authService.currentUser!.email, equals('maul@gmail.com'));
    });

    test('Login dengan email maul@gmail.com berhasil', () async {
      await authService.signOut();
      expect(authService.currentUser, isNull);

      final success = await authService.loginWithEmail(
        'maul@gmail.com',
        'password123',
      );

      expect(success, isTrue);
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser!.displayName, equals('maul'));
    });

    test('Logout mengosongkan user aktif', () async {
      await authService.signOut();
      expect(authService.currentUser, isNull);
    });

    test('Login Google fallback berhasil', () async {
      final success = await authService.loginWithGoogle();
      expect(success, isTrue);
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser!.displayName, contains('Maulana'));
    });
  });
}
