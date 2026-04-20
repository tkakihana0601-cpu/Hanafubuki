import 'package:flutter/foundation.dart';
import '../models/notification_item.dart';

class NotificationService extends ChangeNotifier {
  final List<NotificationItem> _items = [];

  List<NotificationItem> get items => List.unmodifiable(_items);

  void addNotification({
    required String title,
    required String message,
  }) {
    _items.insert(
      0,
      NotificationItem(
        id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        message: message,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markAsRead(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(isRead: true);
    notifyListeners();
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
  }
}
