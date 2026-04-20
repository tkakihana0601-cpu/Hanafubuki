import 'package:flutter_test/flutter_test.dart';
import 'package:hachinana_shogi/services/reservation_service.dart';

void main() {
  group('ReservationService 単体テスト', () {
    test('予約作成正常系: 予約が作成されpendingになる', () async {
      final service = ReservationService();
      final start = DateTime(2026, 2, 1, 10, 0);
      final end = DateTime(2026, 2, 1, 11, 0);

      final reservation =
          await service.createReservation('user_1', 'inst_1', start, end);

      expect(reservation, isNotNull);
      expect(service.reservations.length, 1);
      expect(service.reservations.first.status, 'pending');
    });

    test('予約確定正常系: confirmedに更新される', () async {
      final service = ReservationService();
      final start = DateTime(2026, 2, 1, 12, 0);
      final end = DateTime(2026, 2, 1, 13, 0);
      final reservation =
          await service.createReservation('user_2', 'inst_2', start, end);

      await service.confirmReservation(reservation!.id);

      expect(service.reservations.first.status, 'confirmed');
    });

    test('予約キャンセル正常系: cancelledに更新される', () async {
      final service = ReservationService();
      final start = DateTime(2026, 2, 1, 14, 0);
      final end = DateTime(2026, 2, 1, 15, 0);
      final reservation =
          await service.createReservation('user_3', 'inst_3', start, end);

      await service.cancelReservation(reservation!.id);

      expect(service.reservations.first.status, 'cancelled');
    });

    test('予約更新異常系: 存在しないIDでも例外にならない', () async {
      final service = ReservationService();

      await service.confirmReservation('not_found');
      await service.cancelReservation('not_found');

      expect(service.reservations, isEmpty);
    });
  });
}
