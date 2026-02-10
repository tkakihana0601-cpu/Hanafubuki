import 'package:flutter_test/flutter_test.dart';
import 'package:hachinana_shogi/services/auth_service.dart';

void main() {
  group('AuthService 単体テスト', () {
    test('ログイン正常系: 正常なメール/パスワードでログインできる', () async {
      final service = AuthService();
      await service.login('user@example.com', 'password123');

      expect(service.isAuthenticated, isTrue);
      expect(service.currentUser, isNotNull);
      expect(service.currentUser?.name, 'user');
    });

    test('ログイン異常系: メール形式が不正なら例外', () async {
      final service = AuthService();

      expect(
        () => service.login('invalid_email', 'password123'),
        throwsA(isA<Exception>()),
      );
    });

    test('サインアップ正常系: 新規登録できる', () async {
      final service = AuthService();
      await service.signup('newuser@example.com', 'password123');

      expect(service.isAuthenticated, isTrue);
      expect(service.currentUser?.name, 'newuser');
    });

    test('パスワードリセット異常系: 未登録メールは例外', () async {
      final service = AuthService();

      expect(
        () => service.resetPassword('missing@example.com', 'password123'),
        throwsA(isA<Exception>()),
      );
    });

    test('パスワードリセット正常系: 新しいパスワードでログインできる', () async {
      final service = AuthService();
      await service.signup('reset@example.com', 'password123');
      await service.resetPassword('reset@example.com', 'newpassword123');

      await service.login('reset@example.com', 'newpassword123');
      expect(service.isAuthenticated, isTrue);
    });
  });
}
