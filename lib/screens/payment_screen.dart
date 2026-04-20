import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/payment_method.dart';
import '../services/payment_service.dart';

/// 決済画面
class PaymentScreen extends StatefulWidget {
  final double amount; // 決済金額
  final String reservationId; // 予約ID
  final String instructorName; // 講師名
  final List<String>? reservationIds; // 複数予約ID

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.reservationId,
    required this.instructorName,
    this.reservationIds,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late PaymentMethod _selectedMethod;
  bool _isProcessing = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    // デフォルト決済方法を選択
    final paymentService = context.read<PaymentService>();
    _selectedMethod = paymentService.getDefaultPaymentMethod() ??
        paymentService.paymentMethods.first;
  }

  /// 決済を実行
  Future<void> _processPayment() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('利用規約に同意してください')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final paymentService = context.read<PaymentService>();
    final result = await paymentService.processReservationPayment(
      amount: widget.amount,
      method: _selectedMethod,
      reservationId: widget.reservationId,
      instructorId: 'inst_001',
      instructorName: widget.instructorName,
      userId: 'user_001',
    );

    setState(() => _isProcessing = false);

    if (mounted) {
      if (result.success) {
        // 成功時
        _showSuccessDialog(result);
      } else {
        // エラー時
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    }
  }

  /// 成功ダイアログを表示
  void _showSuccessDialog(PaymentResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('決済完了'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              '取引ID: ${result.transactionId}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ダイアログを閉じる
              Navigator.of(context).pop(true); // 前画面に戻る（成功を通知）
            },
            child: const Text('確認'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('決済'),
        elevation: 0,
      ),
      body: Consumer<PaymentService>(
        builder: (context, paymentService, _) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 決済内容
                  _buildPaymentSummary(),
                  const SizedBox(height: 32),

                  // 決済方法選択
                  _buildPaymentMethodSection(paymentService),
                  const SizedBox(height: 32),

                  // 利用規約
                  _buildTermsCheckbox(),
                  const SizedBox(height: 32),

                  // 決済ボタン
                  _buildPaymentButton(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 決済内容セクション
  Widget _buildPaymentSummary() {
    final count = widget.reservationIds?.length ?? 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '決済内容',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              _buildSummaryRow('講師名', widget.instructorName),
              const SizedBox(height: 8),
              _buildSummaryRow('予約ID', widget.reservationId),
              if (count > 1) ...[
                const SizedBox(height: 8),
                _buildSummaryRow('予約件数', '$count件'),
              ],
              const Divider(height: 24),
              _buildSummaryRow(
                '金額',
                '¥${widget.amount.toStringAsFixed(0)}',
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// サマリー行
  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            fontSize: isBold ? 16 : 14,
          ),
        ),
      ],
    );
  }

  /// 決済方法セクション
  Widget _buildPaymentMethodSection(PaymentService paymentService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '決済方法',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...paymentService.paymentMethods.map((method) {
          return _buildPaymentMethodCard(method);
        }).toList(),
      ],
    );
  }

  /// 決済方法カード
  Widget _buildPaymentMethodCard(PaymentMethod method) {
    final isSelected = _selectedMethod.id == method.id;
    final isAvailable = method.isAvailable;

    return GestureDetector(
      onTap:
          isAvailable ? () => setState(() => _selectedMethod = method) : null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Colors.deepPurple, width: 2)
                : Border.all(color: Colors.grey[300]!, width: 1),
            borderRadius: BorderRadius.circular(8),
            color:
                isSelected ? Colors.deepPurple.withValues(alpha: 0.05) : null,
          ),
          child: Row(
            children: [
              // チェックボックス
              Checkbox(
                value: isSelected,
                onChanged: isAvailable
                    ? (_) => setState(() => _selectedMethod = method)
                    : null,
                activeColor: Colors.deepPurple,
              ),
              const SizedBox(width: 12),

              // メソッド情報
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildMethodDetails(method),
                  ],
                ),
              ),

              // 利用不可バッジ
              if (!isAvailable)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '利用不可',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// メソッド詳細情報
  Widget _buildMethodDetails(PaymentMethod method) {
    switch (method.type) {
      case PaymentMethodType.creditCard:
        return Text(
          '有効期限: ${method.creditCard?.displayExpiry}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        );
      case PaymentMethodType.wallet:
        return Text(
          '残高: ¥${method.wallet?.balance.toStringAsFixed(0)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        );
      case PaymentMethodType.bankTransfer:
        return const Text(
          '振込手数料別途',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        );
    }
  }

  /// 利用規約チェックボックス
  Widget _buildTermsCheckbox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '利用規約',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Text(
            '・このサービスの利用規約に同意します\n'
            '・決済が正常に完了した場合、予約が確定されます\n'
            '・キャンセルポリシーに従います',
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text('利用規約に同意する'),
          value: _agreedToTerms,
          onChanged: (value) => setState(() => _agreedToTerms = value ?? false),
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  /// 決済ボタン
  Widget _buildPaymentButton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.deepPurple,
            disabledBackgroundColor: Colors.grey[300],
          ),
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  '¥${widget.amount.toStringAsFixed(0)}を決済する',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _isProcessing ? null : () => Navigator.pop(context),
          child: const Text('キャンセル'),
        ),
      ],
    );
  }
}
