import 'package:flutter/foundation.dart';
import '../models/match_log.dart';

class MatchLogService extends ChangeNotifier {
  final Map<String, MatchLog> _logs = {};

  MatchLog ensureLog({
    required String matchId,
    DateTime? startedAt,
    String? senteUserId,
    String? goteUserId,
  }) {
    final existing = _logs[matchId];
    if (existing != null) {
      if (senteUserId != null) {
        existing.senteUserId ??= senteUserId;
      }
      if (goteUserId != null) {
        existing.goteUserId ??= goteUserId;
      }
      return existing;
    }
    final log = MatchLog(
      matchId: matchId,
      startedAt: startedAt ?? DateTime.now(),
      senteUserId: senteUserId,
      goteUserId: goteUserId,
    );
    _logs[matchId] = log;
    notifyListeners();
    return log;
  }

  MatchLog? getLog(String matchId) => _logs[matchId];

  void addMove(String matchId, MatchMoveLog move) {
    final log = ensureLog(matchId: matchId);
    log.moves.add(move);
    notifyListeners();
  }

  void addChat(String matchId, ChatLogEntry chat) {
    final log = ensureLog(matchId: matchId);
    log.chats.add(chat);
    notifyListeners();
  }

  void addCall(String matchId, CallLogEntry call) {
    final log = ensureLog(matchId: matchId);
    log.calls.add(call);
    notifyListeners();
  }

  void addReport(String matchId, String reportId) {
    final log = ensureLog(matchId: matchId);
    log.reports.add(reportId);
    notifyListeners();
  }

  void setResult(String matchId, MatchResult result) {
    final log = ensureLog(matchId: matchId);
    log.result = result;
    log.endedAt = DateTime.now();
    notifyListeners();
  }
}
