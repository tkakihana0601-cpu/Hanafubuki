import 'package:flutter/foundation.dart';

class FavoriteInstructorService extends ChangeNotifier {
  final Set<String> _favorites = {};

  Set<String> get favorites => _favorites;

  bool isFavorite(String instructorId) => _favorites.contains(instructorId);

  void toggleFavorite(String instructorId) {
    if (_favorites.contains(instructorId)) {
      _favorites.remove(instructorId);
    } else {
      _favorites.add(instructorId);
    }
    notifyListeners();
  }
}
