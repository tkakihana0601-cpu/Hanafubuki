import 'package:flutter/foundation.dart';

class AppNavigationState extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  String getRouteName(int index) {
    switch (index) {
      case 0:
        return '/home';
      case 1:
        return '/reservations';
      case 2:
        return '/game';
      case 3:
        return '/mypage';
      default:
        return '/home';
    }
  }
}
