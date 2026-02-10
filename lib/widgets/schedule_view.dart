import 'package:flutter/material.dart';
import '../models/schedule_slot.dart';
import '../screens/reservation_screen.dart';

class ScheduleView extends StatelessWidget {
  final List<ScheduleSlot> schedule;

  const ScheduleView({
    Key? key,
    required this.schedule,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 利用可能なスケジュールをフィルタリング
    final availableSlots = schedule.where((slot) => slot.isAvailable).toList();

    if (availableSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '現在利用可能なスケジュールがありません',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: availableSlots.length,
      itemBuilder: (context, index) {
        final slot = availableSlots[index];
        return _buildScheduleCard(context, slot, index);
      },
    );
  }

  Widget _buildScheduleCard(
    BuildContext context,
    ScheduleSlot slot,
    int index,
  ) {
    final dayOfWeek = _getDayOfWeek(slot.start);
    final timeRange = '${_formatTime(slot.start)} - ${_formatTime(slot.end)}';
    final dateStr = _formatDate(slot.start);

    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$dateStr $timeRange を予約しますか？'),
            action: SnackBarAction(
              label: '予約',
              onPressed: () {
                // 予約画面へ遷移
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ReservationScreen(),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日付と曜日
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dayOfWeek,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 時間
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  timeRange,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '予約可能',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getDayOfWeek(DateTime dateTime) {
    final days = ['月', '火', '水', '木', '金', '土', '日'];
    return '（${days[dateTime.weekday - 1]}）';
  }
}
