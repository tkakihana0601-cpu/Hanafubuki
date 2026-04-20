import 'package:flutter/material.dart';

enum CalendarViewMode { week, month }

class DatePickerWidget extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;
  final bool showViewModeToggle;
  final bool showEarliestLabel;
  final String? earliestLabel;
  final Map<DateTime, List<Color>> availabilityColorsByDate;

  const DatePickerWidget({
    Key? key,
    required this.initialDate,
    required this.onDateSelected,
    this.showViewModeToggle = true,
    this.showEarliestLabel = false,
    this.earliestLabel,
    this.availabilityColorsByDate = const {},
  }) : super(key: key);

  @override
  State<DatePickerWidget> createState() => _DatePickerWidgetState();
}

class _DatePickerWidgetState extends State<DatePickerWidget> {
  late DateTime selectedDate;
  CalendarViewMode _viewMode = CalendarViewMode.week;
  late DateTime _visibleDate;

  @override
  void initState() {
    super.initState();
    selectedDate = DateUtils.dateOnly(widget.initialDate);
    _visibleDate = selectedDate;
  }

  @override
  void didUpdateWidget(covariant DatePickerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!DateUtils.isSameDay(oldWidget.initialDate, widget.initialDate)) {
      setState(() {
        selectedDate = DateUtils.dateOnly(widget.initialDate);
        _visibleDate = selectedDate;
      });
    }
  }

  void _selectDate(BuildContext context) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final maxDate = DateUtils.dateOnly(
      DateTime.now().add(const Duration(days: 90)),
    );
    final initial = selectedDate.isBefore(today)
        ? today
        : (selectedDate.isAfter(maxDate) ? maxDate : selectedDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: DateUtils.dateOnly(initial),
      firstDate: today,
      lastDate: maxDate,
      locale: const Locale('ja', 'JP'),
    );
    if (picked != null) {
      setState(() {
        selectedDate = DateUtils.dateOnly(picked);
        _visibleDate = selectedDate;
      });
      widget.onDateSelected(DateUtils.dateOnly(picked));
    }
  }

  DateTime _weekStart(DateTime date) {
    return DateUtils.dateOnly(date)
        .subtract(Duration(days: DateUtils.dateOnly(date).weekday - 1));
  }

  List<DateTime> _buildWeekDays(DateTime anchor) {
    final start = _weekStart(anchor);
    return List.generate(7, (i) => start.add(Duration(days: i)));
  }

  List<DateTime> _buildMonthDays(DateTime anchor) {
    final firstDay = DateTime(anchor.year, anchor.month, 1);
    final start = firstDay.subtract(Duration(days: firstDay.weekday - 1));
    return List.generate(42, (i) => start.add(Duration(days: i)));
  }

  List<Color> _colorsForDate(DateTime date) {
    final key = DateUtils.dateOnly(date);
    return widget.availabilityColorsByDate[key] ?? const [];
  }

  String _formatRangeLabel() {
    if (_viewMode == CalendarViewMode.month) {
      return '${_visibleDate.year}年${_visibleDate.month}月';
    }
    final start = _weekStart(_visibleDate);
    final end = start.add(const Duration(days: 6));
    return '${start.month}/${start.day} - ${end.month}/${end.day}';
  }

  void _goPrevious() {
    setState(() {
      if (_viewMode == CalendarViewMode.month) {
        _visibleDate = DateTime(_visibleDate.year, _visibleDate.month - 1, 1);
      } else {
        _visibleDate = _visibleDate.subtract(const Duration(days: 7));
      }
    });
  }

  void _goNext() {
    setState(() {
      if (_viewMode == CalendarViewMode.month) {
        _visibleDate = DateTime(_visibleDate.year, _visibleDate.month + 1, 1);
      } else {
        _visibleDate = _visibleDate.add(const Duration(days: 7));
      }
    });
  }

  String _formatDate(DateTime date) {
    final days = ['月', '火', '水', '木', '金', '土', '日'];
    final dayOfWeek = days[date.weekday - 1];
    return '${date.year}年${date.month}月${date.day}日（$dayOfWeek）';
  }

  @override
  Widget build(BuildContext context) {
    final days = _viewMode == CalendarViewMode.month
        ? _buildMonthDays(_visibleDate)
        : _buildWeekDays(_visibleDate);
    const weekLabels = ['月', '火', '水', '木', '金', '土', '日'];

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
          Row(
            children: [
              const Expanded(
                child: Text(
                  '日付を選択',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              if (widget.showViewModeToggle)
                SegmentedButton<CalendarViewMode>(
                  segments: const [
                    ButtonSegment(
                      value: CalendarViewMode.week,
                      label: Text('週'),
                    ),
                    ButtonSegment(
                      value: CalendarViewMode.month,
                      label: Text('月'),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (value) {
                    setState(() {
                      _viewMode = value.first;
                      _visibleDate = selectedDate;
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
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
                      Text(
                        _formatDate(selectedDate),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'タップして変更',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: Colors.deepPurple.shade300,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (widget.showEarliestLabel && widget.earliestLabel != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.flash_on, color: Colors.green, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '最短: ${widget.earliestLabel}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: _goPrevious,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  _formatRangeLabel(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: _goNext,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: weekLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 6),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.1,
            ),
            itemBuilder: (context, index) {
              final date = days[index];
              final isSelected = DateUtils.isSameDay(date, selectedDate);
              final isToday = DateUtils.isSameDay(date, DateTime.now());
              final isCurrentMonth = _viewMode == CalendarViewMode.week
                  ? true
                  : date.month == _visibleDate.month;
              final colors = _colorsForDate(date);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedDate = DateUtils.dateOnly(date);
                    _visibleDate = selectedDate;
                  });
                  widget.onDateSelected(DateUtils.dateOnly(date));
                },
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.deepPurple : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Colors.deepPurple
                          : (isToday ? Colors.green : Colors.grey.shade300),
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : (isCurrentMonth
                                  ? Colors.black
                                  : Colors.grey.shade400),
                        ),
                      ),
                      if (colors.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 2,
                          runSpacing: 2,
                          alignment: WrapAlignment.center,
                          children: colors
                              .take(4)
                              .map(
                                (color) => Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
