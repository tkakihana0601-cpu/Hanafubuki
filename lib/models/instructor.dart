import 'schedule_slot.dart';

class Instructor {
  final String id;
  final String name;
  final String bio;
  final double rating;
  final int pricePerSession;
  final List<ScheduleSlot> schedule;

  Instructor({
    required this.id,
    required this.name,
    required this.bio,
    required this.rating,
    required this.pricePerSession,
    required this.schedule,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bio': bio,
        'rating': rating,
        'pricePerSession': pricePerSession,
        'schedule': schedule.map((s) => s.toJson()).toList(),
      };

  factory Instructor.fromJson(Map<String, dynamic> json) => Instructor(
        id: json['id'],
        name: json['name'],
        bio: json['bio'],
        rating: (json['rating'] as num).toDouble(),
        pricePerSession: json['pricePerSession'],
        schedule: (json['schedule'] as List)
            .map((s) => ScheduleSlot.fromJson(s))
            .toList(),
      );

  Instructor copyWith({
    String? id,
    String? name,
    String? bio,
    double? rating,
    int? pricePerSession,
    List<ScheduleSlot>? schedule,
  }) =>
      Instructor(
        id: id ?? this.id,
        name: name ?? this.name,
        bio: bio ?? this.bio,
        rating: rating ?? this.rating,
        pricePerSession: pricePerSession ?? this.pricePerSession,
        schedule: schedule ?? this.schedule,
      );
}
