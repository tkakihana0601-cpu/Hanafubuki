import 'package:flutter_test/flutter_test.dart';
import 'package:hachinana_shogi/models/payment_method.dart';
import 'package:hachinana_shogi/models/transaction.dart';
import 'package:hachinana_shogi/services/payment_service.dart';

void main() {
  group('PaymentService 単体テスト', () {
    test('決済正常系: ウォレット決済が成功し残高が減る', () async {
      final service = PaymentService();
      final wallet = service.paymentMethods
          .firstWhere((m) => m.type == PaymentMethodType.wallet);

      final result = await service.processReservationPayment(
        amount: 1000,
        method: wallet,
        reservationId: 'res_001',
        instructorId: 'inst_001',
        instructorName: '講師A',
        userId: 'user_001',
      );

      expect(result.success, isTrue);
      expect(service.walletBalance, 9000);
      expect(service.transactionHistory.length, 1);
      expect(
          service.transactionHistory.first.status, TransactionStatus.completed);
    });

    test('決済異常系: ウォレット残高不足で失敗する', () async {
      final service = PaymentService();
      final wallet = service.paymentMethods
          .firstWhere((m) => m.type == PaymentMethodType.wallet);

      final result = await service.processReservationPayment(
        amount: 20000,
        method: wallet,
        reservationId: 'res_002',
        instructorId: 'inst_001',
        instructorName: '講師A',
        userId: 'user_001',
      );

      expect(result.success, isFalse);
      expect(service.transactionHistory, isEmpty);
    });

    test('決済異常系: 利用不可カードは失敗記録が残る', () async {
      final service = PaymentService();
      final card = service.paymentMethods
          .firstWhere((m) => m.type == PaymentMethodType.creditCard);

      final result = await service.processReservationPayment(
        amount: 1000,
        method: card,
        reservationId: 'res_003',
        instructorId: 'inst_002',
        instructorName: '講師B',
        userId: 'user_002',
      );

      expect(result.success, isFalse);
      expect(service.transactionHistory.length, 1);
      expect(service.transactionHistory.first.status, TransactionStatus.failed);
    });
  });
}
