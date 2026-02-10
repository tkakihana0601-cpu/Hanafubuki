import 'dart:async';
import 'package:flutter/foundation.dart';
import 'match_service.dart';
import '../main.dart';

class MatchViewModel extends ChangeNotifier {
  final MatchService matchService;

  final String matchId;
  Board board;
  final List<Move> moves = [];
  Stream<Move>? _moveStream;
  StreamSubscription<Move>? _subscription;

  MatchViewModel({
    required this.matchService,
    required this.matchId,
    required this.board,
  });

  void init() {
    _moveStream = matchService.subscribeMoves(matchId);
    _subscription = _moveStream!.listen((move) {
      _onReceiveMove(move);
    });
  }

  Future<void> sendMove(Move move) async {
    // クライアント側で合法手チェックを行う想定
    board.applyMove(move);
    moves.add(move);
    notifyListeners();

    await matchService.sendMove(matchId, move);
  }

  void _onReceiveMove(Move move) {
    board.applyMove(move);
    moves.add(move);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
