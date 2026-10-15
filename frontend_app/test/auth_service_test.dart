import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_app/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

  group('AuthService with SharedPreferences Simulation', () {
    test('1. checkLoginStatus returns false initially', () async {
      final isLoggedIn = await authService.checkLoginStatus();
      expect(isLoggedIn, isFalse);
      expect(authService.currentUser, isNull);
    });

    test('2. registerWithEmail saves user and sets is_logged_in to true', () async {
      final result = await authService.registerWithEmail(
        'Budi Pratama',
        'budi@example.com',
        'password123',
      );

      expect(result, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_name'), equals('Budi Pratama'));
      expect(prefs.getString('user_email'), equals('budi@example.com'));
      expect(prefs.getString('user_password'), equals('password123'));
      expect(prefs.getBool('is_logged_in'), isTrue);

      expect(authService.currentUser?.displayName, equals('Budi Pratama'));
      expect(authService.currentUser?.email, equals('budi@example.com'));

      final status = await authService.checkLoginStatus();
      expect(status, isTrue);
    });

    test('3. loginWithEmail succeeds with correct credentials', () async {
      SharedPreferences.setMockInitialValues({
        'user_name': 'Siti Rahma',
        'user_email': 'siti@example.com',
        'user_password': 'secretPassword',
        'is_logged_in': false,
      });

      final result = await authService.loginWithEmail(
        'siti@example.com',
        'secretPassword',
      );

      expect(result, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_logged_in'), isTrue);
      expect(authService.currentUser?.displayName, equals('Siti Rahma'));
    });

    test('4. loginWithEmail throws Exception on incorrect password', () async {
      SharedPreferences.setMockInitialValues({
        'user_name': 'Siti Rahma',
        'user_email': 'siti@example.com',
        'user_password': 'secretPassword',
        'is_logged_in': false,
      });

      expect(
        () async => await authService.loginWithEmail(
          'siti@example.com',
          'wrongPassword',
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Email atau Password salah'),
        )),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_logged_in'), isFalse);
    });

    test('5. logout sets is_logged_in to false', () async {
      SharedPreferences.setMockInitialValues({
        'user_name': 'Budi Pratama',
        'user_email': 'budi@example.com',
        'user_password': 'password123',
        'is_logged_in': true,
      });

      await authService.logout();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_logged_in'), isFalse);
      expect(authService.currentUser, isNull);

      final status = await authService.checkLoginStatus();
      expect(status, isFalse);
    });
  });

  group('AuthService Demo & Integration Tests', () {
    test('Registrasi berhasil menyimpan profil pengguna maul', () async {
      final success = await authService.registerWithEmail(
        'maul',
        'maul@gmail.com',
        'password123',
      );

      expect(success, isTrue);
      expect(authService.currentUser, isNotNull);
      expect(authService.currentUser!.displayName, equals('maul'));
      expect(authService.currentUser!.email, equals('maul@gmail.com'));
    });

    test('Login dengan akun bawaan maul@gmail.com berhasil', () async {
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
