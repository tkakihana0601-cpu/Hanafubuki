import 'package:flutter/material.dart';

/// 決済ステータス
enum TransactionStatus {
  pending, // 処理中
  completed, // 完了
  failed, // 失敗
  cancelled, // キャンセル
}

/// 決済トランザクション（取引記録）
class Transaction {
  final String id; // トランザクションID
  final String reservationId; // 予約ID
  final String userId; // ユーザーID
  final String instructorId; // 講師ID
  final String instructorName; // 講師名
  final double amount; // 金額
  final String paymentMethod; // 決済方法（credit/wallet/bank）
  final TransactionStatus status; // ステータス
  final DateTime createdAt; // 作成日時
  final DateTime? completedAt; // 完了日時
  final String? errorMessage; // エラーメッセージ

  Transaction({
    required this.id,
    required this.reservationId,
    required this.userId,
    required this.instructorId,
    required this.instructorName,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  /// ステータスの表示名
  String get statusLabel {
    switch (status) {
      case TransactionStatus.pending:
        return '処理中';
      case TransactionStatus.completed:
        return '完了';
      case TransactionStatus.failed:
        return '失敗';
      case TransactionStatus.cancelled:
        return 'キャンセル';
    }
  }

  /// ステータスの色
  get statusColor {
    switch (status) {
      case TransactionStatus.pending:
        return const Color(0xFFFFA500); // オレンジ
      case TransactionStatus.completed:
        return const Color(0xFF4CAF50); // 緑
      case TransactionStatus.failed:
        return const Color(0xFFF44336); // 赤
      case TransactionStatus.cancelled:
        return const Color(0xFF9E9E9E); // グレー
    }
  }

  /// 日付表示フォーマット（例：2024年1月15日）
  String get formattedDate {
    return '${createdAt.year}年${createdAt.month}月${createdAt.day}日';
  }

  /// 時刻表示フォーマット（例：14:30）
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// JSONへの変換
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reservationId': reservationId,
      'userId': userId,
      'instructorId': instructorId,
      'instructorName': instructorName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }

  /// JSONからの変換
  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String,
      reservationId: json['reservationId'] as String,
      userId: json['userId'] as String,
      instructorId: json['instructorId'] as String,
      instructorName: json['instructorName'] as String,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      status: TransactionStatus.values.firstWhere(
        (s) => s.toString() == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  /// copyWithメソッド
  Transaction copyWith({
    String? id,
    String? reservationId,
    String? userId,
    String? instructorId,
    String? instructorName,
    double? amount,
    String? paymentMethod,
    TransactionStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
  }) {
    return Transaction(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
      userId: userId ?? this.userId,
      instructorId: instructorId ?? this.instructorId,
      instructorName: instructorName ?? this.instructorName,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
