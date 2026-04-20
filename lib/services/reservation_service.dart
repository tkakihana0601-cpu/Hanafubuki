import 'package:flutter/foundation.dart';
import '../models/reservation.dart';
import '../models/review.dart';
import '../repositories/reservation_repository.dart';

class ReservationService extends ChangeNotifier {
  final List<Reservation> _reservations = [];
  final ReservationRepository _repository = ReservationRepository();
  final Map<String, String> _kifStore = {};
  final Map<String, Review> _reviewStore = {};

  List<Reservation> get reservations => _reservations;

  Review? getReviewForReservation(String reservationId) {
    return _reviewStore[reservationId];
  }

  Future<void> addReview(Review review) async {
    _reviewStore[review.reservationId] = review;
    notifyListeners();
  }

  String getKifForReservation(String reservationId) {
    return _kifStore.putIfAbsent(reservationId, _buildSampleKif);
  }

  String _buildSampleKif() {
    return '''手合割：平手
先手：あなた
後手：指導者
手数----指手---------消費時間--
1 ７六歩(77)
2 ３四歩(33)
3 ２六歩(27)
4 ８四歩(83)
5 ７八銀(79)
6 ８五歩(84)
7 ７七角(88)
8 ３三角(22)
9 ４八銀(39)
10 ６二銀(71)
''';
  }

  Future<Reservation?> createReservation(
    String userId,
    String instructorId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final reservation =
          await _repository.create(userId, instructorId, start, end);
      if (reservation != null) {
        _reservations.add(reservation);
      }
      notifyListeners();
      return reservation;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> confirmReservation(String reservationId) async {
    try {
      await _repository.updateStatus(reservationId, 'confirmed');
      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _reservations[index] =
            _reservations[index].copyWith(status: 'confirmed');
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelReservation(String reservationId) async {
    try {
      await _repository.updateStatus(reservationId, 'cancelled');
      final index = _reservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        _reservations[index] =
            _reservations[index].copyWith(status: 'cancelled');
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }
}
