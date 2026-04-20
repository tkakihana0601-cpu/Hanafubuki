class ScheduleSlot {
  final DateTime start;
  final DateTime end;
  final bool isAvailable;

  ScheduleSlot({
    required this.start,
    required this.end,
    required this.isAvailable,
  });

  Map<String, dynamic> toJson() => {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'isAvailable': isAvailable,
      };

  factory ScheduleSlot.fromJson(Map<String, dynamic> json) => ScheduleSlot(
        start: DateTime.parse(json['start']),
        end: DateTime.parse(json['end']),
        isAvailable: json['isAvailable'],
      );

  ScheduleSlot copyWith({
    DateTime? start,
    DateTime? end,
    bool? isAvailable,
  }) =>
      ScheduleSlot(
        start: start ?? this.start,
        end: end ?? this.end,
        isAvailable: isAvailable ?? this.isAvailable,
      );
}
