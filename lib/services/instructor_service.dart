import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/instructor.dart';
import '../models/schedule_slot.dart';
import '../repositories/instructor_repository.dart';

class InstructorService extends ChangeNotifier {
  final List<Instructor> _instructors = [];
  final InstructorRepository _repository = InstructorRepository();

  List<Instructor> get instructors => _instructors;

  Future<List<Instructor>> fetchInstructors() async {
    try {
      final result = await _repository.listInstructors();
      _instructors
        ..clear()
        ..addAll(result);
      notifyListeners();
      return _instructors;
    } catch (e) {
      rethrow;
    }
  }

  Future<Instructor?> fetchInstructorDetail(String instructorId) async {
    try {
      final instructor = await _repository.getInstructor(instructorId);
      return instructor;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addScheduleSlots(
    String instructorId,
    List<ScheduleSlot> slots,
  ) async {
    await _repository.addScheduleSlots(instructorId, slots);
    await fetchInstructors();
  }

  Future<void> addRecurringSlots({
    required String instructorId,
    required int weekday,
    required TimeOfDay startTime,
    required Duration duration,
    required int weeks,
  }) async {
    final now = DateTime.now();
    final slots = <ScheduleSlot>[];
    var base = DateTime(now.year, now.month, now.day);
    while (base.weekday != weekday) {
      base = base.add(const Duration(days: 1));
    }

    for (var i = 0; i < weeks; i++) {
      final day = base.add(Duration(days: 7 * i));
      final start = DateTime(
        day.year,
        day.month,
        day.day,
        startTime.hour,
        startTime.minute,
      );
      slots.add(
        ScheduleSlot(
          start: start,
          end: start.add(duration),
          isAvailable: true,
        ),
      );
    }

    await addScheduleSlots(instructorId, slots);
  }
}
