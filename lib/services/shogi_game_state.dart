import 'package:flutter/foundation.dart';
import '../main.dart';
import '../models/piece.dart';
import 'legal_move_validator.dart';
import 'move_finder.dart';
import 'captured_piece_manager.dart';
import 'draw_detector.dart';
import 'shogi_game_validator.dart';
import 'check_detector.dart';
import '../utils/kif_parser.dart';

// ゲーム状態を管理するクラス
class ShogiGameState extends ChangeNotifier {
  late Board board;
  bool isBlackTurn = true; // trueなら先手（黒）
  int moveCount = 0;
  List<Move> moveHistory = [];
  int? selectedRow;
  int? selectedCol;
  List<Position> possibleMoves = [];
  final CapturedPieceManager capturedPieces = CapturedPieceManager();
  final List<String> boardHistory = [];
  GameStatus gameStatus = GameStatus.normal;
  String gameMessage = '';
  final List<_GameSnapshot> _undoStack = [];
  final List<_GameSnapshot> _redoStack = [];
  List<KifMove> _kifMoves = [];
  int _kifPly = 0;
  bool _analysisMode = false;
  final List<VariationLine> _variations = [];

  bool get isAnalysisMode => _analysisMode;
  List<VariationLine> get variations => List.unmodifiable(_variations);

  bool get hasKif => _kifMoves.isNotEmpty;
  int get currentPly => _kifPly;
  int get totalPly => _kifMoves.length;

  ShogiGameState() {
    board = Board();
    _updateGameStatus();
  }

  // ゲームを初期化
  void resetGame() {
    board = Board();
    isBlackTurn = true;
    moveCount = 0;
    moveHistory.clear();
    selectedRow = null;
    selectedCol = null;
    possibleMoves.clear();
    capturedPieces.reset();
    boardHistory.clear();
    gameStatus = GameStatus.normal;
    gameMessage = '';
    _undoStack.clear();
    _redoStack.clear();
    _kifMoves = [];
    _kifPly = 0;
    _analysisMode = false;
    _variations.clear();
    notifyListeners();
  }

  void setAnalysisMode(bool value) {
    _analysisMode = value;
    selectedRow = null;
    selectedCol = null;
    possibleMoves.clear();
    notifyListeners();
  }

  // 駒を選択
  void selectPiece(int row, int col) {
    if (_analysisMode) {
      final piece = board.getPiece(row, col);
      if (selectedRow == row && selectedCol == col) {
        selectedRow = null;
        selectedCol = null;
        notifyListeners();
        return;
      }

      if (selectedRow != null && selectedCol != null) {
        movePieceFree(selectedRow!, selectedCol!, row, col);
        return;
      }

      if (piece.type == PieceType.empty) return;
      selectedRow = row;
      selectedCol = col;
      notifyListeners();
      return;
    }
    // ゲーム終了なら操作不可
    if (gameStatus == GameStatus.checkmate ||
        gameStatus == GameStatus.draw_threefoldRepetition ||
        gameStatus == GameStatus.loss_continuousCheck ||
        gameStatus == GameStatus.draw_jishogi ||
        gameStatus == GameStatus.loss_jishogi_black ||
        gameStatus == GameStatus.loss_jishogi_white) {
      return;
    }

    final piece = board.getPiece(row, col);

    // 同じ駒をクリック時は選択解除
    if (selectedRow == row && selectedCol == col) {
      selectedRow = null;
      selectedCol = null;
      possibleMoves.clear();
      notifyListeners();
      return;
    }

    // 相手の駒または空マスを選択した場合
    if (piece.type == PieceType.empty || piece.isBlack != isBlackTurn) {
      // 選択中の駒があれば移動を試みる
      if (selectedRow != null && selectedCol != null) {
        movePiece(selectedRow!, selectedCol!, row, col);
      }
      return;
    }

    // 自分の駒を選択
    selectedRow = row;
    selectedCol = col;

    // 王手放置をチェックした合法手を取得
    possibleMoves = LegalMoveValidator.getLegalMovesWithCheckValidation(
      board,
      row,
      col,
      isBlackTurn,
    ).map((m) => m.to).toList();

    notifyListeners();
  }

  // 駒を移動
  void movePiece(int fromRow, int fromCol, int toRow, int toCol,
      {bool shouldPromote = false}) {
    // 移動の有効性を検証
    final validation = ShogiGameValidator.validateMove(
      board,
      fromRow,
      fromCol,
      toRow,
      toCol,
      isBlackTurn,
      shouldPromote,
    );

    if (!validation.isValid) {
      gameMessage = validation.reason;
      notifyListeners();
      return;
    }

    _pushUndoSnapshot();
    _redoStack.clear();

    final piece = board.getPiece(fromRow, fromCol);
    final capturedPiece = board.getPiece(toRow, toCol);

    // 駒を移動
    var movedPiece = piece;

    // 成り判定
    if (shouldPromote &&
        ShogiGameValidator.canPromote(
            board, fromRow, fromCol, toRow, isBlackTurn)) {
      movedPiece = piece.promote();
    }

    // キャプチャが発生した場合は駒台に追加
    if (capturedPiece.type != PieceType.empty) {
      capturedPieces.capturePiece(capturedPiece, isBlackTurn);
    }

    board.squares[toRow][toCol] = movedPiece;
    board.squares[fromRow][fromCol] = Piece.empty;

    // 王手判定（相手が王手されているか）
    final isCheck = CheckDetector.isInCheck(board, !isBlackTurn);

    // 履歴に追加
    moveHistory.add(Move(
      from: _positionToString(fromRow, fromCol),
      to: _positionToString(toRow, toCol),
      piece: movedPiece.toDisplayString(),
      timestamp: DateTime.now(),
      isBlack: isBlackTurn,
      isCheck: isCheck,
    ));

    // 局面ハッシュを記録
    final hash = DrawDetector.getFullGameHash(
      board,
      !isBlackTurn,
      capturedPieces.blackCapturedPieces,
      capturedPieces.whiteCapturedPieces,
    );
    boardHistory.add(hash);

    // ターンを交代
    isBlackTurn = !isBlackTurn;
    moveCount++;

    // 選択状態をリセット
    selectedRow = null;
    selectedCol = null;
    possibleMoves.clear();

    // ゲーム状態を更新
    _updateGameStatus();

    notifyListeners();
  }

  void applyExternalMove(Move move) {
    final to = _parsePosition(move.to);
    if (to == null) return;

    if (move.from == '打') {
      final type = _pieceTypeFromDisplay(move.piece);
      if (type == PieceType.empty) return;
      capturedPieces.dropPiece(type, move.isBlack);
      board.squares[to.$1][to.$2] = Piece(type: type, isBlack: move.isBlack);
    } else {
      final from = _parsePosition(move.from);
      if (from == null) return;
      final captured = board.getPiece(to.$1, to.$2);
      if (captured.type != PieceType.empty) {
        capturedPieces.capturePiece(captured, move.isBlack);
      }
      final movingPiece = board.getPiece(from.$1, from.$2);
      final displayType = _pieceTypeFromDisplay(move.piece);
      final resolvedPiece = movingPiece.type == PieceType.empty
          ? Piece(type: displayType, isBlack: move.isBlack)
          : (movingPiece.type == displayType
              ? movingPiece
              : Piece(type: displayType, isBlack: move.isBlack));
      board.squares[to.$1][to.$2] = resolvedPiece;
      board.squares[from.$1][from.$2] = Piece.empty;
    }

    moveHistory.add(move);
    moveCount = moveHistory.length;
    isBlackTurn = !move.isBlack;
    selectedRow = null;
    selectedCol = null;
    possibleMoves.clear();
    _updateGameStatus();
    notifyListeners();
  }

  void movePieceFree(int fromRow, int fromCol, int toRow, int toCol) {
    if (!_analysisMode) return;
    final piece = board.getPiece(fromRow, fromCol);
    if (piece.type == PieceType.empty) return;

    _pushUndoSnapshot();
    _redoStack.clear();

    board.squares[toRow][toCol] = piece;
    board.squares[fromRow][fromCol] = Piece.empty;

    moveHistory.add(Move(
      from: _positionToString(fromRow, fromCol),
      to: _positionToString(toRow, toCol),
      piece: piece.toDisplayString(),
      timestamp: DateTime.now(),
      isBlack: isBlackTurn,
      isCheck: false,
    ));
    moveCount = moveHistory.length;
    selectedRow = null;
    selectedCol = null;
    possibleMoves.clear();
    notifyListeners();
  }

  void loadFromBoard(Board source) {
    board = Board.copy(source);
    isBlackTurn = true;
    moveCount = 0;
    moveHistory.clear();
    selectedRow = null;
    selectedCol = null;
    possibleMoves.clear();
    capturedPieces.reset();
    boardHistory.clear();
    gameStatus = GameStatus.normal;
    gameMessage = '';
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  VariationLine saveVariation({String? name}) {
    final line = VariationLine(
      id: 'var_${DateTime.now().millisecondsSinceEpoch}',
      name: name?.isNotEmpty == true ? name! : '変化${_variations.length + 1}',
      createdAt: DateTime.now(),
      boardSnapshot: Board.copy(board),
      moves: List<Move>.from(moveHistory),
    );
    _variations.insert(0, line);
    notifyListeners();
    return line;
  }

  void deleteVariation(String id) {
    _variations.removeWhere((v) => v.id == id);
    notifyListeners();
  }

  void loadVariation(String id) {
    if (_variations.isEmpty) return;
    final line = _variations.firstWhere(
      (v) => v.id == id,
      orElse: () => _variations.first,
    );
    board = Board.copy(line.boardSnapshot);
    moveHistory = List<Move>.from(line.moves);
    moveCount = moveHistory.length;
    isBlackTurn = moveHistory.length.isEven;
    selectedRow = null;
    selectedCol = null;
    possibleMoves.clear();
    notifyListeners();
  }

  // 駒を打つ
  bool dropPiece(PieceType pieceType, int toRow, int toCol) {
    // ゲーム終了なら操作不可
    if (isGameOver()) {
      return false;
    }

    final validation = ShogiGameValidator.validateDrop(
      board,
      toRow,
      toCol,
      pieceType,
      isBlackTurn,
      capturedPieces,
    );

    if (!validation.isValid) {
      gameMessage = validation.reason;
      notifyListeners();
      return false;
    }

    _pushUndoSnapshot();
    _redoStack.clear();

    // 駒台から削除
    if (!capturedPieces.dropPiece(pieceType, isBlackTurn)) {
      gameMessage = 'その駒を持っていません';
      notifyListeners();
      return false;
    }

    // 盤面に打つ
    final droppedPiece = Piece(type: pieceType, isBlack: isBlackTurn);
    board.squares[toRow][toCol] = droppedPiece;

    // 王手判定（相手が王手されているか）
    final isCheck = CheckDetector.isInCheck(board, !isBlackTurn);

    // 履歴に追加
    moveHistory.add(Move(
      from: '打',
      to: _positionToString(toRow, toCol),
      piece: droppedPiece.toDisplayString(),
      timestamp: DateTime.now(),
      isBlack: isBlackTurn,
      isCheck: isCheck,
    ));

    // 局面ハッシュを記録
    final hash = DrawDetector.getFullGameHash(
      board,
      !isBlackTurn,
      capturedPieces.blackCapturedPieces,
      capturedPieces.whiteCapturedPieces,
    );
    boardHistory.add(hash);

    // ターンを交代
    isBlackTurn = !isBlackTurn;
    moveCount++;

    // 選択状態をリセット
    selectedRow = null;
    selectedCol = null;
    possibleMoves.clear();

    // ゲーム状態を更新
    _updateGameStatus();

    notifyListeners();
    return true;
  }

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void undo() {
    if (!canUndo) return;
    _redoStack.add(_createSnapshot());
    final snapshot = _undoStack.removeLast();
    _restoreSnapshot(snapshot);
    _updateGameStatus();
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _undoStack.add(_createSnapshot());
    final snapshot = _redoStack.removeLast();
    _restoreSnapshot(snapshot);
    _updateGameStatus();
    notifyListeners();
  }

  // ゲーム状態を更新
  void _updateGameStatus() {
    final currentHash = DrawDetector.getFullGameHash(
      board,
      isBlackTurn,
      capturedPieces.blackCapturedPieces,
      capturedPieces.whiteCapturedPieces,
    );

    gameStatus = ShogiGameValidator.getGameStatus(
      board,
      isBlackTurn,
      boardHistory,
      currentHash,
      moveHistory,
      capturedPieces,
    );

    // メッセージを設定
    gameMessage = switch (gameStatus) {
      GameStatus.normal => isBlackTurn ? '先手のターン' : '後手のターン',
      GameStatus.inCheck => '王手です！',
      GameStatus.checkmate => _formatWinLoss(!_isCurrentPlayerBlack()),
      GameStatus.draw_threefoldRepetition => '千日手です（引き分け）',
      GameStatus.loss_continuousCheck =>
        _formatWinLoss(!_isCurrentPlayerBlack()),
      GameStatus.draw_jishogi => '持将棋です（引き分け）',
      GameStatus.loss_jishogi_black => _formatWinLoss(false),
      GameStatus.loss_jishogi_white => _formatWinLoss(true),
      GameStatus.stalemate => 'ステイルメイト（異常状態）',
    };
  }

  // 位置を文字列に変換
  String _positionToString(int row, int col) {
    const cols = ['9', '8', '7', '6', '5', '4', '3', '2', '1'];
    const rows = ['一', '二', '三', '四', '五', '六', '七', '八', '九'];
    return '${cols[col]}${rows[row]}';
  }

  (int, int)? _parsePosition(String position) {
    if (position.length < 2) return null;
    const cols = ['9', '8', '7', '6', '5', '4', '3', '2', '1'];
    const rows = ['一', '二', '三', '四', '五', '六', '七', '八', '九'];
    final col = cols.indexOf(position[0]);
    final row = rows.indexOf(position[1]);
    if (col == -1 || row == -1) return null;
    return (row, col);
  }

  PieceType _pieceTypeFromDisplay(String display) {
    final cleaned = display.replaceAll('▲', '');
    return switch (cleaned) {
      '歩' => PieceType.pawn,
      '香' => PieceType.lance,
      '桂' => PieceType.knight,
      '銀' => PieceType.silver,
      '金' => PieceType.gold,
      '角' => PieceType.bishop,
      '飛' => PieceType.rook,
      '玉' => PieceType.king,
      '王' => PieceType.king,
      'と' => PieceType.promotedPawn,
      '成香' => PieceType.promotedLance,
      '成桂' => PieceType.promotedKnight,
      '成銀' => PieceType.promotedSilver,
      '馬' => PieceType.horse,
      '龍' => PieceType.dragon,
      '竜' => PieceType.dragon,
      '成' => PieceType.promotedSilver,
      _ => PieceType.empty,
    };
  }

  // ゲームが終了したか確認
  bool isGameOver() {
    return gameStatus == GameStatus.checkmate ||
        gameStatus == GameStatus.draw_threefoldRepetition ||
        gameStatus == GameStatus.loss_continuousCheck ||
        gameStatus == GameStatus.draw_jishogi ||
        gameStatus == GameStatus.loss_jishogi_black ||
        gameStatus == GameStatus.loss_jishogi_white;
  }

  // 現在のプレイヤーが動ける駒があるか確認
  bool hasLegalMove() {
    final moves = LegalMoveValidator.getAllLegalMoves(board, isBlackTurn);
    return moves.isNotEmpty;
  }

  // 現在のプレイヤー名を取得
  String getCurrentPlayerName() {
    return isBlackTurn ? '先手' : '後手';
  }

  bool _isCurrentPlayerBlack() {
    return isBlackTurn;
  }

  String _formatWinLoss(bool winnerIsBlack) {
    return winnerIsBlack ? '先手勝利・後手敗北' : '後手勝利・先手敗北';
  }

  // 現在王手されているか
  bool isInCheck() {
    return gameStatus == GameStatus.inCheck;
  }

  String exportKif({String? title}) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    buffer.writeln('開始日時：${now.year}/${now.month}/${now.day}');
    if (title != null && title.isNotEmpty) {
      buffer.writeln('タイトル：$title');
    }
    buffer.writeln('手合割：平手');
    buffer.writeln('先手：先手');
    buffer.writeln('後手：後手');
    buffer.writeln('手数----指手---------');

    for (var i = 0; i < moveHistory.length; i++) {
      final move = moveHistory[i];
      final prefix = move.isBlack ? '▲' : '△';
      final piece = move.piece.replaceAll('▲', '');
      final to = move.to;
      final suffix =
          move.from == '打' ? '打' : '(${_toNumericPosition(move.from)})';
      buffer.writeln('${i + 1} $prefix$to$piece$suffix');
    }

    return buffer.toString();
  }

  bool importKif(String kif) {
    try {
      _kifMoves = KifParser.parse(kif);
      return goToPly(_kifMoves.length);
    } catch (e) {
      return false;
    }
  }

  bool goToPly(int ply) {
    if (!hasKif) return false;
    final target = ply.clamp(0, _kifMoves.length);
    return _replayToPly(target);
  }

  bool stepForward() => goToPly(_kifPly + 1);

  bool stepBack() => goToPly(_kifPly - 1);

  bool _replayToPly(int ply) {
    _resetForReplay();
    _kifPly = ply;
    for (int i = 0; i < ply; i++) {
      final move = _kifMoves[i];
      if (move.isDrop) {
        final ok = dropPiece(move.dropPieceType!, move.toRow, move.toCol);
        if (!ok) return false;
        continue;
      }
      if (move.fromRow == null || move.fromCol == null) return false;
      final before = moveCount;
      movePiece(
        move.fromRow!,
        move.fromCol!,
        move.toRow,
        move.toCol,
        shouldPromote: move.promote,
      );
      if (moveCount == before) return false;
    }
    _updateGameStatus();
    notifyListeners();
    return true;
  }

  void _resetForReplay() {
    board = Board();
    isBlackTurn = true;
    moveCount = 0;
    moveHistory.clear();
    selectedRow = null;
    selectedCol = null;
    possibleMoves.clear();
    capturedPieces.reset();
    boardHistory.clear();
    gameStatus = GameStatus.normal;
    gameMessage = '';
    _undoStack.clear();
    _redoStack.clear();
  }

  String _toNumericPosition(String pos) {
    if (pos.length < 2) return '';
    final file = pos[0];
    final rankKanji = pos[1];
    final rank = switch (rankKanji) {
      '一' => '1',
      '二' => '2',
      '三' => '3',
      '四' => '4',
      '五' => '5',
      '六' => '6',
      '七' => '7',
      '八' => '8',
      '九' => '9',
      _ => '',
    };
    if (file.isEmpty || rank.isEmpty) return '';
    return '$file$rank';
  }

  void _pushUndoSnapshot() {
    _undoStack.add(_createSnapshot());
  }

  _GameSnapshot _createSnapshot() {
    return _GameSnapshot(
      board: Board.copy(board),
      isBlackTurn: isBlackTurn,
      moveCount: moveCount,
      moveHistory: List<Move>.from(moveHistory),
      selectedRow: selectedRow,
      selectedCol: selectedCol,
      possibleMoves: List<Position>.from(possibleMoves),
      blackCaptured: Map<PieceType, int>.from(
        capturedPieces.blackCapturedPieces,
      ),
      whiteCaptured: Map<PieceType, int>.from(
        capturedPieces.whiteCapturedPieces,
      ),
      boardHistory: List<String>.from(boardHistory),
      gameStatus: gameStatus,
      gameMessage: gameMessage,
    );
  }

  void _restoreSnapshot(_GameSnapshot snapshot) {
    board = Board.copy(snapshot.board);
    isBlackTurn = snapshot.isBlackTurn;
    moveCount = snapshot.moveCount;
    moveHistory = List<Move>.from(snapshot.moveHistory);
    selectedRow = snapshot.selectedRow;
    selectedCol = snapshot.selectedCol;
    possibleMoves = List<Position>.from(snapshot.possibleMoves);
    capturedPieces.blackCapturedPieces
      ..clear()
      ..addAll(snapshot.blackCaptured);
    capturedPieces.whiteCapturedPieces
      ..clear()
      ..addAll(snapshot.whiteCaptured);
    boardHistory
      ..clear()
      ..addAll(snapshot.boardHistory);
    gameStatus = snapshot.gameStatus;
    gameMessage = snapshot.gameMessage;
  }
}

class _GameSnapshot {
  final Board board;
  final bool isBlackTurn;
  final int moveCount;
  final List<Move> moveHistory;
  final int? selectedRow;
  final int? selectedCol;
  final List<Position> possibleMoves;
  final Map<PieceType, int> blackCaptured;
  final Map<PieceType, int> whiteCaptured;
  final List<String> boardHistory;
  final GameStatus gameStatus;
  final String gameMessage;

  _GameSnapshot({
    required this.board,
    required this.isBlackTurn,
    required this.moveCount,
    required this.moveHistory,
    required this.selectedRow,
    required this.selectedCol,
    required this.possibleMoves,
    required this.blackCaptured,
    required this.whiteCaptured,
    required this.boardHistory,
    required this.gameStatus,
    required this.gameMessage,
  });
}

class VariationLine {
  final String id;
  final String name;
  final DateTime createdAt;
  final Board boardSnapshot;
  final List<Move> moves;

  VariationLine({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.boardSnapshot,
    required this.moves,
  });
}
