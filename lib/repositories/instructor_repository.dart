import '../models/instructor.dart';
import '../models/schedule_slot.dart';

class InstructorRepository {
  static final List<Instructor> _store = _seedInstructors();

  static List<Instructor> _seedInstructors() {
    final now = DateTime.now();
    return [
      Instructor(
        id: 'inst_001',
        name: '佐藤 龍一',
        bio: '将棋歴25年。序盤研究と終盤力を伸ばします。',
        rating: 6.2,
        pricePerSession: 5000,
        schedule: _buildSchedule(now),
      ),
      Instructor(
        id: 'inst_002',
        name: '高橋 玲奈',
        bio: '女性向け指導も多数。中終盤の読みを強化。',
        rating: 5.6,
        pricePerSession: 4500,
        schedule: _buildSchedule(now.add(const Duration(days: 1))),
      ),
      Instructor(
        id: 'inst_003',
        name: '山本 恒一',
        bio: '初心者歓迎。駒の効率的な使い方を丁寧に。',
        rating: 5.0,
        pricePerSession: 3500,
        schedule: _buildSchedule(now.add(const Duration(days: 2))),
      ),
    ];
  }

  static List<ScheduleSlot> _buildSchedule(DateTime base) {
    final startDay = DateTime(base.year, base.month, base.day);
    final slots = <ScheduleSlot>[];
    for (var i = 0; i < 5; i++) {
      final day = startDay.add(Duration(days: i));
      slots.addAll([
        ScheduleSlot(
          start: day.add(const Duration(hours: 10)),
          end: day.add(const Duration(hours: 11)),
          isAvailable: true,
        ),
        ScheduleSlot(
          start: day.add(const Duration(hours: 13)),
          end: day.add(const Duration(hours: 14)),
          isAvailable: i.isEven,
        ),
        ScheduleSlot(
          start: day.add(const Duration(hours: 18)),
          end: day.add(const Duration(hours: 19)),
          isAvailable: true,
        ),
      ]);
    }
    return slots;
  }

  Future<Instructor?> getInstructor(String instructorId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      for (final instructor in _store) {
        if (instructor.id == instructorId) {
          return instructor;
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addScheduleSlots(
    String instructorId,
    List<ScheduleSlot> slots,
  ) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _store.indexWhere((i) => i.id == instructorId);
    if (index == -1) return;
    final current = _store[index];
    _store[index] = current.copyWith(
      schedule: [...current.schedule, ...slots],
    );
  }

  Future<List<Instructor>> listInstructors({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final safeOffset = offset < 0 ? 0 : offset;
      final start = safeOffset > _store.length ? _store.length : safeOffset;
      final end =
          (start + limit) > _store.length ? _store.length : (start + limit);
      return _store.sublist(start, end);
    } catch (e) {
      rethrow;
    }
  }
}
