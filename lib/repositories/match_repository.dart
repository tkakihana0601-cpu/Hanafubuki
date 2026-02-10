import '../main.dart';

class _MatchRecord {
  Board board;
  final List<Move> moves;

  _MatchRecord({required this.board, required this.moves});
}

class MatchRepository {
  static final Map<String, _MatchRecord> _store = {};

  Future<String?> create(
    String userId,
    String instructorId,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
      _store[matchId] = _MatchRecord(board: Board(), moves: []);
      return matchId;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateBoard(String matchId, Board board) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final record = _store[matchId];
      if (record != null) {
        record.board = board.copyWith();
      } else {
        _store[matchId] = _MatchRecord(board: board.copyWith(), moves: []);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addMove(String matchId, Move move) async {
    try {
      await Future.delayed(const Duration(milliseconds: 150));
      final record = _store[matchId];
      if (record != null) {
        record.moves.add(move);
      } else {
        _store[matchId] = _MatchRecord(board: Board(), moves: [move]);
      }
    } catch (e) {
      rethrow;
    }
  }

  _MatchRecord? getMatch(String matchId) => _store[matchId];
}
