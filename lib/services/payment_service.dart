import 'package:flutter/foundation.dart';
import '../models/payment_method.dart';
import '../models/transaction.dart';

class PaymentResult {
  final bool success;
  final String transactionId;
  final String message;
  final DateTime timestamp;

  PaymentResult({
    required this.success,
    required this.transactionId,
    required this.message,
    required this.timestamp,
  });
}

class PaymentService extends ChangeNotifier {
  List<PaymentMethod> _paymentMethods = [];
  double _walletBalance = 10000.0;
  List<Transaction> _transactionHistory = [];

  List<PaymentMethod> get paymentMethods => _paymentMethods;
  double get walletBalance => _walletBalance;
  List<Transaction> get transactionHistory =>
      List.unmodifiable(_transactionHistory);

  PaymentService() {
    _initializeDummyPaymentMethods();
  }

  void _initializeDummyPaymentMethods() {
    _paymentMethods = [
      PaymentMethod(
        type: PaymentMethodType.creditCard,
        id: 'card_001',
        displayName: 'VISA ****1234',
        isDefault: true,
        creditCard: CreditCard(
          cardNumber: '1234',
          holderName: 'TARO YAMADA',
          expiryMonth: '12',
          expiryYear: '25',
        ),
      ),
      PaymentMethod(
        type: PaymentMethodType.wallet,
        id: 'wallet_001',
        displayName: 'ウォレット',
        wallet: Wallet(
          balance: _walletBalance,
          lastUpdated: DateTime.now(),
        ),
      ),
      PaymentMethod(
        type: PaymentMethodType.bankTransfer,
        id: 'bank_001',
        displayName: '銀行振込',
      ),
    ];
  }

  Future<PaymentResult> processReservationPayment({
    required double amount,
    required PaymentMethod method,
    required String reservationId,
    required String instructorId,
    required String instructorName,
    required String userId,
  }) async {
    try {
      if (!method.isAvailable) {
        _addTransactionRecord(
          reservationId: reservationId,
          instructorId: instructorId,
          instructorName: instructorName,
          userId: userId,
          amount: amount,
          method: method,
          status: TransactionStatus.failed,
          message: '${method.typeLabel}は利用できません',
        );
        return PaymentResult(
          success: false,
          transactionId: '',
          message: '${method.typeLabel}は利用できません',
          timestamp: DateTime.now(),
        );
      }

      late PaymentResult result;
      switch (method.type) {
        case PaymentMethodType.creditCard:
          result = await _processCardPayment(amount, method);
        case PaymentMethodType.wallet:
          result = await _processWalletPayment(amount, method);
        case PaymentMethodType.bankTransfer:
          result = await _processBankTransfer(amount, method);
      }

      if (result.success) {
        _addTransactionRecord(
          reservationId: reservationId,
          instructorId: instructorId,
          instructorName: instructorName,
          userId: userId,
          amount: amount,
          method: method,
          status: TransactionStatus.completed,
        );
      }

      return result;
    } catch (e) {
      _addTransactionRecord(
        reservationId: reservationId,
        instructorId: instructorId,
        instructorName: instructorName,
        userId: userId,
        amount: amount,
        method: method,
        status: TransactionStatus.failed,
        message: 'エラー: $e',
      );
      return PaymentResult(
        success: false,
        transactionId: '',
        message: 'エラー: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  Future<PaymentResult> _processCardPayment(
      double amount, PaymentMethod method) async {
    await Future.delayed(const Duration(seconds: 2));
    final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      message: '${method.creditCard?.maskedCardNumber}で決済完了',
      timestamp: DateTime.now(),
    );
  }

  Future<PaymentResult> _processWalletPayment(
      double amount, PaymentMethod method) async {
    if (_walletBalance < amount) {
      return PaymentResult(
        success: false,
        transactionId: '',
        message: 'ウォレット残高不足',
        timestamp: DateTime.now(),
      );
    }

    await Future.delayed(const Duration(seconds: 1));
    _walletBalance -= amount;
    notifyListeners();

    final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      message: 'ウォレットから¥${amount.toStringAsFixed(0)}を決済',
      timestamp: DateTime.now(),
    );
  }

  Future<PaymentResult> _processBankTransfer(
      double amount, PaymentMethod method) async {
    await Future.delayed(const Duration(seconds: 1));
    final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    return PaymentResult(
      success: true,
      transactionId: transactionId,
      message: '銀行振込手続き完了',
      timestamp: DateTime.now(),
    );
  }

  void addPaymentMethod(PaymentMethod method) {
    _paymentMethods.add(method);
    notifyListeners();
  }

  void removePaymentMethod(String methodId) {
    _paymentMethods.removeWhere((m) => m.id == methodId);
    notifyListeners();
  }

  void setDefaultPaymentMethod(String methodId) {
    for (var i = 0; i < _paymentMethods.length; i++) {
      _paymentMethods[i] = _paymentMethods[i].copyWith(
        isDefault: _paymentMethods[i].id == methodId,
      );
    }
    notifyListeners();
  }

  void chargeWallet(double amount) {
    _walletBalance += amount;
    for (var i = 0; i < _paymentMethods.length; i++) {
      if (_paymentMethods[i].type == PaymentMethodType.wallet) {
        _paymentMethods[i] = _paymentMethods[i].copyWith(
          wallet: Wallet(
            balance: _walletBalance,
            lastUpdated: DateTime.now(),
          ),
        );
      }
    }
    notifyListeners();
  }

  PaymentMethod? getDefaultPaymentMethod() {
    try {
      return _paymentMethods.firstWhere((m) => m.isDefault);
    } catch (e) {
      return _paymentMethods.isNotEmpty ? _paymentMethods.first : null;
    }
  }

  void _addTransactionRecord({
    required String reservationId,
    required String instructorId,
    required String instructorName,
    required String userId,
    required double amount,
    required PaymentMethod method,
    required TransactionStatus status,
    String? message,
  }) {
    final transactionId = 'txn_${DateTime.now().millisecondsSinceEpoch}';
    final transaction = Transaction(
      id: transactionId,
      reservationId: reservationId,
      userId: userId,
      instructorId: instructorId,
      instructorName: instructorName,
      amount: amount,
      paymentMethod: method.type.toString().split('.').last,
      status: status,
      createdAt: DateTime.now(),
      completedAt:
          status == TransactionStatus.completed ? DateTime.now() : null,
      errorMessage: status == TransactionStatus.failed ? message : null,
    );
    _transactionHistory.insert(0, transaction);
    notifyListeners();
  }

  List<Transaction> getUserTransactionHistory(String userId) {
    return _transactionHistory.where((t) => t.userId == userId).toList();
  }

  Transaction? getTransactionByReservationId(String reservationId) {
    try {
      return _transactionHistory.firstWhere(
        (t) => t.reservationId == reservationId,
      );
    } catch (e) {
      return null;
    }
  }

  void clearTransactionHistory() {
    _transactionHistory.clear();
    notifyListeners();
  }
}

extension PaymentMethodExt on PaymentMethod {
  PaymentMethod copyWith({
    PaymentMethodType? type,
    String? id,
    String? displayName,
    CreditCard? creditCard,
    Wallet? wallet,
    bool? isDefault,
  }) {
    return PaymentMethod(
      type: type ?? this.type,
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      creditCard: creditCard ?? this.creditCard,
      wallet: wallet ?? this.wallet,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
