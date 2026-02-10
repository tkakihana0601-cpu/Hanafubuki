import 'package:flutter_test/flutter_test.dart';
import 'package:hachinana_shogi/models/payment_method.dart';
import 'package:hachinana_shogi/models/transaction.dart';
import 'package:hachinana_shogi/services/payment_service.dart';
import 'package:hachinana_shogi/services/reservation_service.dart';

void main() {
  group('予約＋決済 結合テスト', () {
    test('結合(正常系): 予約後に決済が成功し取引が記録される', () async {
      final reservationService = ReservationService();
      final paymentService = PaymentService();
      final wallet = paymentService.paymentMethods
          .firstWhere((m) => m.type == PaymentMethodType.wallet);

      final reservation = await reservationService.createReservation(
        'user_100',
        'inst_100',
        DateTime(2026, 2, 1, 10, 0),
        DateTime(2026, 2, 1, 11, 0),
      );

      final result = await paymentService.processReservationPayment(
        amount: 2000,
        method: wallet,
        reservationId: reservation!.id,
        instructorId: 'inst_100',
        instructorName: '講師A',
        userId: 'user_100',
      );

      expect(result.success, isTrue);
      final tx = paymentService.getTransactionByReservationId(reservation.id);
      expect(tx, isNotNull);
      expect(tx?.status, TransactionStatus.completed);
    });

    test('結合(異常系): 利用不可カードで決済が失敗し失敗記録が残る', () async {
      final reservationService = ReservationService();
      final paymentService = PaymentService();
      final card = paymentService.paymentMethods
          .firstWhere((m) => m.type == PaymentMethodType.creditCard);

      final reservation = await reservationService.createReservation(
        'user_200',
        'inst_200',
        DateTime(2026, 2, 1, 12, 0),
        DateTime(2026, 2, 1, 13, 0),
      );

      final result = await paymentService.processReservationPayment(
        amount: 2000,
        method: card,
        reservationId: reservation!.id,
        instructorId: 'inst_200',
        instructorName: '講師B',
        userId: 'user_200',
      );

      expect(result.success, isFalse);
      final tx = paymentService.getTransactionByReservationId(reservation.id);
      expect(tx, isNotNull);
      expect(tx?.status, TransactionStatus.failed);
    });
  });
}
