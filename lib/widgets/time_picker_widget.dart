import 'package:flutter/material.dart';

class TimePickerWidget extends StatefulWidget {
  final DateTime? initialTime;
  final Function(DateTime) onTimeSelected;

  const TimePickerWidget({
    Key? key,
    this.initialTime,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  State<TimePickerWidget> createState() => _TimePickerWidgetState();
}

class _TimePickerWidgetState extends State<TimePickerWidget> {
  late DateTime selectedTime;

  @override
  void initState() {
    super.initState();
    selectedTime = widget.initialTime ?? DateTime(2024, 1, 1, 10, 0);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '時間を選択',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          // 時間範囲タブ
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildTimeSlot('10:00 - 11:00', 10),
                _buildTimeSlot('11:00 - 12:00', 11),
                _buildTimeSlot('13:00 - 14:00', 13),
                _buildTimeSlot('14:00 - 15:00', 14),
                _buildTimeSlot('15:00 - 16:00', 15),
                _buildTimeSlot('19:00 - 20:00', 19),
                _buildTimeSlot('20:00 - 21:00', 20),
                _buildTimeSlot('21:00 - 22:00', 21),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 選択時間表示
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.deepPurple.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '選択した時間',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_formatTime(selectedTime)} - ${_formatTime(selectedTime.add(const Duration(hours: 1)))}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.access_time,
                  color: Colors.deepPurple.shade300,
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlot(String timeRange, int hour) {
    final isSelected = selectedTime.hour == hour;
    final time = DateTime(2024, 1, 1, hour, 0);

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTime = time;
        });
        widget.onTimeSelected(time);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
          ),
        ),
        child: Text(
          timeRange,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
