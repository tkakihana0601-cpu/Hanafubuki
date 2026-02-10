class Reservation {
  final String id;
  final String userId;
  final String instructorId;
  final DateTime start;
  final DateTime end;
  final String status; // pending, confirmed, cancelled, completed

  Reservation({
    required this.id,
    required this.userId,
    required this.instructorId,
    required this.start,
    required this.end,
    required this.status,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'instructorId': instructorId,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
        'status': status,
      };

  factory Reservation.fromJson(Map<String, dynamic> json) => Reservation(
        id: json['id'],
        userId: json['userId'],
        instructorId: json['instructorId'],
        start: DateTime.parse(json['start']),
        end: DateTime.parse(json['end']),
        status: json['status'],
      );

  Reservation copyWith({
    String? id,
    String? userId,
    String? instructorId,
    DateTime? start,
    DateTime? end,
    String? status,
  }) =>
      Reservation(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        instructorId: instructorId ?? this.instructorId,
        start: start ?? this.start,
        end: end ?? this.end,
        status: status ?? this.status,
      );
}
