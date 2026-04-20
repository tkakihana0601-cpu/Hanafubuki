class CallSession {
  final String meetingId;
  final String attendeeId;
  final String joinToken;

  CallSession({
    required this.meetingId,
    required this.attendeeId,
    required this.joinToken,
  });

  Map<String, dynamic> toJson() => {
        'meetingId': meetingId,
        'attendeeId': attendeeId,
        'joinToken': joinToken,
      };

  factory CallSession.fromJson(Map<String, dynamic> json) => CallSession(
        meetingId: json['meetingId'],
        attendeeId: json['attendeeId'],
        joinToken: json['joinToken'],
      );

  CallSession copyWith({
    String? meetingId,
    String? attendeeId,
    String? joinToken,
  }) =>
      CallSession(
        meetingId: meetingId ?? this.meetingId,
        attendeeId: attendeeId ?? this.attendeeId,
        joinToken: joinToken ?? this.joinToken,
      );
}
