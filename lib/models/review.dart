class Review {
  final String id;
  final String reservationId;
  final String instructorId;
  final String userId;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.reservationId,
    required this.instructorId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'reservationId': reservationId,
        'instructorId': instructorId,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'comment': comment,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'],
        reservationId: json['reservationId'],
        instructorId: json['instructorId'],
        userId: json['userId'],
        userName: json['userName'],
        rating: json['rating'],
        comment: json['comment'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
