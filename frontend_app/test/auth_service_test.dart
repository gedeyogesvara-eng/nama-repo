import 'package:flutter_test/flutter_test.dart';
<<<<<<< HEAD
import 'package:shared_preferences/shared_preferences.dart';
=======
>>>>>>> da0e86a6b9b4d28cbbbb7d93e01b295eae945c05
import 'package:frontend_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

<<<<<<< HEAD
  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
=======
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
>>>>>>> da0e86a6b9b4d28cbbbb7d93e01b295eae945c05
    });
  });
}
