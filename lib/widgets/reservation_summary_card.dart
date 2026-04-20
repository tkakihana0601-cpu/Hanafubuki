import 'package:flutter/material.dart';

class ReservationSummaryCard extends StatelessWidget {
  final String instructorName;
  final List<DateTime> selectedTimes;
  final int pricePerHour;

  const ReservationSummaryCard({
    Key? key,
    required this.instructorName,
    required this.selectedTimes,
    required this.pricePerHour,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    final weekdays = ['月', '火', '水', '木', '金', '土', '日'];
    final dayOfWeek = weekdays[date.weekday % 7];
    return '${date.year}年${date.month}月${date.day}日（$dayOfWeek）';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(int price) {
    return '¥${price.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final sortedTimes = [...selectedTimes]..sort((a, b) => a.compareTo(b));
    final dateSet = sortedTimes
        .map((time) => DateTime(time.year, time.month, time.day))
        .toSet();
    final dateLabel =
        dateSet.length == 1 ? _formatDate(sortedTimes.first) : '複数日';
    final totalHours = sortedTimes.length;
    final totalPrice = pricePerHour * totalHours;
    final timeLabel = totalHours == 1
        ? '${_formatTime(sortedTimes.first)} - ${_formatTime(sortedTimes.first.add(const Duration(hours: 1)))}'
        : sortedTimes
            .map((time) =>
                '${_formatTime(time)} - ${_formatTime(time.add(const Duration(hours: 1)))}')
            .join('\n');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.deepPurple.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.deepPurple,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '予約確認',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // 講師名
          _buildSummaryRow(
            icon: Icons.person,
            label: '講師',
            value: instructorName,
          ),
          const SizedBox(height: 12),

          // 日付
          _buildSummaryRow(
            icon: Icons.calendar_today,
            label: '日付',
            value: dateLabel,
          ),
          const SizedBox(height: 12),

          // 時間
          _buildSummaryRow(
            icon: Icons.access_time,
            label: '時間',
            value: timeLabel,
          ),
          const SizedBox(height: 12),

          // 時間
          _buildSummaryRow(
            icon: Icons.hourglass_empty,
            label: '所要時間',
            value: '$totalHours時間',
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // 価格
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '合計金額',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  _formatPrice(totalPrice),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 注記
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'キャンセルは予約時間の24時間前まで可能です',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.deepPurple.shade300,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
