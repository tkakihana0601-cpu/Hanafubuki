import '../models/user.dart';

class UserRepository {
  static final Map<String, User> _store = {};

  Future<User?> getUser(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 250));
      if (_store.containsKey(userId)) {
        return _store[userId];
      }
      final fallback = User(
        id: userId,
        name: 'ユーザー${userId.substring(0, userId.length.clamp(1, 6))}',
        avatarUrl: 'https://via.placeholder.com/150',
        isInstructor: false,
      );
      _store[userId] = fallback;
      return fallback;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> createUser(String name, String email, String password) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final user = User(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        avatarUrl: 'https://via.placeholder.com/150',
        isInstructor: false,
      );
      _store[user.id] = user;
      return user;
    } catch (e) {
      rethrow;
    }
  }
}
