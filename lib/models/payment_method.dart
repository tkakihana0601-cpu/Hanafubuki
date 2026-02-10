/// 決済方法の種類
enum PaymentMethodType {
  creditCard, // クレジットカード
  wallet, // ウォレット（アプリ内残高）
  bankTransfer // 銀行振込
}

/// クレジットカードの情報
class CreditCard {
  final String cardNumber; // カード番号（最後の4桁のみ表示）
  final String holderName; // カード所有者名
  final String expiryMonth; // 有効期限（月）
  final String expiryYear; // 有効期限（年）

  CreditCard({
    required this.cardNumber,
    required this.holderName,
    required this.expiryMonth,
    required this.expiryYear,
  });

  /// カード番号の表示形式（例：**** **** **** 1234）
  String get maskedCardNumber => '**** **** **** $cardNumber';

  /// 有効期限の表示形式（例：12/25）
  String get displayExpiry => '$expiryMonth/$expiryYear';

  /// カードが有効期限内か確認
  bool get isValid {
    final now = DateTime.now();
    final expiryDate =
        DateTime(int.parse('20$expiryYear'), int.parse(expiryMonth) + 1, 0);
    return now.isBefore(expiryDate);
  }
}

/// ウォレット（アプリ内残高）の情報
class Wallet {
  final double balance; // 残高
  final DateTime lastUpdated; // 最終更新日時

  Wallet({
    required this.balance,
    required this.lastUpdated,
  });

  /// 十分な残高があるか確認
  bool hasEnoughBalance(double amount) => balance >= amount;
}

/// 決済方法を表すクラス
class PaymentMethod {
  final PaymentMethodType type;
  final String id; // 決済方法の一意識別子
  final String displayName; // 表示名（例：「VISA ****1234」）
  final CreditCard? creditCard;
  final Wallet? wallet;
  final bool isDefault; // デフォルト決済方法か

  PaymentMethod({
    required this.type,
    required this.id,
    required this.displayName,
    this.creditCard,
    this.wallet,
    this.isDefault = false,
  });

  /// 利用可能か確認
  bool get isAvailable {
    switch (type) {
      case PaymentMethodType.creditCard:
        return creditCard?.isValid ?? false;
      case PaymentMethodType.wallet:
        return wallet != null;
      case PaymentMethodType.bankTransfer:
        return true; // 銀行振込は常に利用可能
    }
  }

  /// 表示用の種類名
  String get typeLabel {
    switch (type) {
      case PaymentMethodType.creditCard:
        return 'クレジットカード';
      case PaymentMethodType.wallet:
        return 'ウォレット';
      case PaymentMethodType.bankTransfer:
        return '銀行振込';
    }
  }
}
