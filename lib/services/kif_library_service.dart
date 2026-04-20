import 'package:flutter/foundation.dart';
import '../models/kif_record.dart';

class KifLibraryService extends ChangeNotifier {
  final List<KifRecord> _records = [];

  List<KifRecord> get records => List.unmodifiable(_records);

  KifRecord addRecord({
    required String title,
    required String instructorName,
    required DateTime date,
    required List<String> tags,
    required String kif,
  }) {
    final record = KifRecord(
      id: 'kif_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      instructorName: instructorName,
      date: date,
      tags: tags,
      kif: kif,
      isCloudSynced: false,
      shareUrl: null,
    );
    _records.insert(0, record);
    notifyListeners();
    return record;
  }

  void updateTags(String id, List<String> tags) {
    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _records[index] = _records[index].copyWith(tags: tags);
    notifyListeners();
  }

  void syncToCloud(String id) {
    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1) return;
    _records[index] = _records[index].copyWith(isCloudSynced: true);
    notifyListeners();
  }

  String createShareUrl(String id) {
    final index = _records.indexWhere((r) => r.id == id);
    if (index == -1) return '';
    final existing = _records[index].shareUrl;
    if (existing != null && existing.isNotEmpty) return existing;
    final url = 'https://shogi.app/kif/$id';
    _records[index] = _records[index].copyWith(shareUrl: url);
    notifyListeners();
    return url;
  }

  List<KifRecord> search({
    String? keyword,
    String? instructor,
    DateTime? date,
    List<String>? tags,
  }) {
    return _records.where((record) {
      final matchesKeyword = keyword == null || keyword.isEmpty
          ? true
          : record.title.contains(keyword) ||
              record.instructorName.contains(keyword) ||
              record.tags.any((t) => t.contains(keyword));
      final matchesInstructor = instructor == null || instructor.isEmpty
          ? true
          : record.instructorName.contains(instructor);
      final matchesDate = date == null
          ? true
          : record.date.year == date.year &&
              record.date.month == date.month &&
              record.date.day == date.day;
      final matchesTags = tags == null || tags.isEmpty
          ? true
          : tags.every((tag) => record.tags.contains(tag));
      return matchesKeyword && matchesInstructor && matchesDate && matchesTags;
    }).toList();
  }
}
