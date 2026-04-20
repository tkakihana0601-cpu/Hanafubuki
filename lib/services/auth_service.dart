import 'package:flutter/foundation.dart';
import '../models/user.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  String? _authToken;
  String? _currentEmail;
  final Map<String, String> _passwordStore = {};

  User? get currentUser => _currentUser;
  String? get authToken => _authToken;
  String? get currentEmail => _currentEmail;
  bool get isAuthenticated => _currentUser != null && _authToken != null;

  /// ログイン処理
  /// 本来はCognito or バックエンドのAuthサービスと連携
  Future<void> login(String email, String password) async {
    try {
      // バリデーション
      if (email.isEmpty) {
        throw Exception('メールアドレスを入力してください');
      }
      if (password.isEmpty) {
        throw Exception('パスワードを入力してください');
      }

      // メールアドレス形式のバリデーション
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z0-9]+$',
      );
      if (!emailRegex.hasMatch(email)) {
        throw Exception('メールアドレスの形式が正しくありません');
      }

      // 実際の実装では、ここでバックエンドのAPIを呼び出す
      // POST /auth/login
      // Response: { token, user: { id, name, email, avatarUrl, isInstructor } }

      // ローカルテスト用: ダミーユーザーを生成
      await Future.delayed(const Duration(milliseconds: 800));

      if (_passwordStore.containsKey(email)) {
        if (_passwordStore[email] != password) {
          throw Exception('パスワードが正しくありません');
        }
      } else {
        _passwordStore[email] = password;
      }

      _authToken = 'dummy_token_${DateTime.now().millisecondsSinceEpoch}';
      _currentEmail = email;
      _currentUser = User(
        id: 'user_${email.hashCode}',
        name: email.split('@')[0],
        avatarUrl: 'https://via.placeholder.com/150',
        isInstructor: false,
      );

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// 新規登録処理
  /// 本来はCognito or バックエンドのAuthサービスと連携
  Future<void> signup(
    String email,
    String password, {
    bool isInstructor = false,
  }) async {
    try {
      // バリデーション
      if (email.isEmpty) {
        throw Exception('メールアドレスを入力してください');
      }
      if (password.isEmpty) {
        throw Exception('パスワードを入力してください');
      }

      if (password.length < 6) {
        throw Exception('パスワードは6文字以上である必要があります');
      }

      // メールアドレス形式のバリデーション
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z0-9]+$',
      );
      if (!emailRegex.hasMatch(email)) {
        throw Exception('メールアドレスの形式が正しくありません');
      }

      // 実際の実装では、ここでバックエンドのAPIを呼び出す
      // POST /auth/signup
      // Body: { email, password, isInstructor }
      // Response: { token, user: { id, name, email, avatarUrl, isInstructor } }

      // ローカルテスト用: ダミーユーザーを生成
      await Future.delayed(const Duration(milliseconds: 800));

      if (_passwordStore.containsKey(email)) {
        throw Exception('このメールアドレスは既に登録されています');
      }
      _passwordStore[email] = password;

      _authToken = 'dummy_token_${DateTime.now().millisecondsSinceEpoch}';
      _currentEmail = email;
      _currentUser = User(
        id: 'user_${email.hashCode}',
        name: email.split('@')[0],
        avatarUrl: 'https://via.placeholder.com/150',
        isInstructor: isInstructor,
      );

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// ログアウト処理
  Future<void> logout() async {
    try {
      // 実際の実装では、ここでバックエンドのAPIを呼び出す
      // POST /auth/logout
      // DELETE トークンをサーバーから削除

      _authToken = null;
      _currentUser = null;
      _currentEmail = null;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// 現在のユーザー情報を取得
  Future<User?> getCurrentUser() async {
    try {
      // 実際の実装では、ここでバックエンドから現在のユーザー情報を取得
      // GET /auth/me (Bearer token required)

      return _currentUser;
    } catch (e) {
      rethrow;
    }
  }

  /// トークンをリフレッシュ
  Future<void> refreshToken() async {
    try {
      // 実際の実装では、ここでバックエンドでトークンをリフレッシュ
      // POST /auth/refresh

      await Future.delayed(const Duration(milliseconds: 500));
      _authToken = 'dummy_token_${DateTime.now().millisecondsSinceEpoch}';
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  /// パスワードリセット（ダミー実装）
  Future<void> resetPassword(String email, String newPassword) async {
    try {
      if (email.isEmpty) {
        throw Exception('メールアドレスを入力してください');
      }

      if (newPassword.isEmpty) {
        throw Exception('新しいパスワードを入力してください');
      }

      if (newPassword.length < 6) {
        throw Exception('パスワードは6文字以上である必要があります');
      }

      final emailRegex = RegExp(
        r'^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z0-9]+$',
      );
      if (!emailRegex.hasMatch(email)) {
        throw Exception('メールアドレスの形式が正しくありません');
      }

      if (!_passwordStore.containsKey(email)) {
        throw Exception('このメールアドレスは登録されていません');
      }

      // 実際の実装ではバックエンドにリセット要求を送る
      // POST /auth/password/reset
      await Future.delayed(const Duration(milliseconds: 800));

      _passwordStore[email] = newPassword;
    } catch (e) {
      rethrow;
    }
  }

  /// 講師としてのプロフィール登録
  Future<void> registerAsInstructor({
    required String bio,
    required int pricePerSession,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('ユーザーがログインしていません');
      }

      // 実際の実装では、ここでバックエンドのAPIを呼び出す
      // POST /instructors/register

      await Future.delayed(const Duration(milliseconds: 800));

      _currentUser = User(
        id: _currentUser!.id,
        name: _currentUser!.name,
        avatarUrl: _currentUser!.avatarUrl,
        isInstructor: true,
      );

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile({required String name}) async {
    try {
      if (_currentUser == null) {
        throw Exception('ユーザーがログインしていません');
      }
      _currentUser = _currentUser!.copyWith(name: name);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
