import '../models/reservation.dart';

class ReservationRepository {
  static final List<Reservation> _store = [];

  Future<Reservation?> create(
    String userId,
    String instructorId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final reservation = Reservation(
        id: 'res_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        instructorId: instructorId,
        start: start,
        end: end,
        status: 'pending',
      );
      _store.add(reservation);
      return reservation;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateStatus(String reservationId, String status) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final index = _store.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _store[index] = _store[index].copyWith(status: status);
      }
    } catch (e) {
      rethrow;
    }
  }

  List<Reservation> listAll() => List.unmodifiable(_store);
}
