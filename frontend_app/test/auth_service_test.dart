import 'package:flutter_test/flutter_test.dart';
import 'package:frontend_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
