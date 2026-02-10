class User {
  final String id;
  final String name;
  final String avatarUrl;
  final bool isInstructor;

  User({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.isInstructor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatarUrl': avatarUrl,
        'isInstructor': isInstructor,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        name: json['name'],
        avatarUrl: json['avatarUrl'],
        isInstructor: json['isInstructor'],
      );

  User copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    bool? isInstructor,
  }) =>
      User(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
        isInstructor: isInstructor ?? this.isInstructor,
      );
}
