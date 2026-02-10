class MatchMoveLog {
  final String from;
  final String to;
  final String piece;
  final bool isBlack;
  final bool isCheck;
  final DateTime timestamp;
  final Duration? timeSpent;

  const MatchMoveLog({
    required this.from,
    required this.to,
    required this.piece,
    required this.isBlack,
    required this.isCheck,
    required this.timestamp,
    this.timeSpent,
  });
}

class ChatLogEntry {
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;

  const ChatLogEntry({
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
  });
}

class CallLogEntry {
  final String meetingId;
  final String userId;
  final String event;
  final DateTime timestamp;

  const CallLogEntry({
    required this.meetingId,
    required this.userId,
    required this.event,
    required this.timestamp,
  });
}

class MatchResult {
  final String result;
  final String message;

  const MatchResult({
    required this.result,
    required this.message,
  });
}

class MatchLog {
  final String matchId;
  final DateTime startedAt;
  DateTime? endedAt;
  String? senteUserId;
  String? goteUserId;
  final List<MatchMoveLog> moves;
  final List<ChatLogEntry> chats;
  final List<CallLogEntry> calls;
  final List<String> reports;
  MatchResult? result;

  MatchLog({
    required this.matchId,
    required this.startedAt,
    this.endedAt,
    this.senteUserId,
    this.goteUserId,
    List<MatchMoveLog>? moves,
    List<ChatLogEntry>? chats,
    List<CallLogEntry>? calls,
    List<String>? reports,
    this.result,
  })  : moves = moves ?? [],
        chats = chats ?? [],
        calls = calls ?? [],
        reports = reports ?? [];
}
