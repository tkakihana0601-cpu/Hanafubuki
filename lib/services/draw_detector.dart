import '../main.dart';
import '../models/piece.dart';

/// 千日手（同じ局面が4回繰り返される）を判定するクラス
class DrawDetector {
  /// 局面のハッシュ値を計算（Zobrist ハッシング相当）
  static String getBoardHash(Board board, bool isBlackTurn) {
    final buffer = StringBuffer();

    // 盤面をハッシュ化
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final piece = board.getPiece(row, col);
        buffer.write(_pieceToHash(piece));
      }
    }

    // 手番を追加
    buffer.write(isBlackTurn ? 'B' : 'W');

    return buffer.toString();
  }

  /// 駒をハッシュ文字に変換
  static String _pieceToHash(Piece piece) {
    if (piece.type == PieceType.empty) return '.';

    final typePart = switch (piece.type) {
      PieceType.pawn => 'p',
      PieceType.lance => 'l',
      PieceType.knight => 'n',
      PieceType.silver => 's',
      PieceType.gold => 'g',
      PieceType.bishop => 'b',
      PieceType.rook => 'r',
      PieceType.king => 'k',
      PieceType.promotedPawn => 'P',
      PieceType.promotedLance => 'L',
      PieceType.promotedKnight => 'N',
      PieceType.promotedSilver => 'S',
      PieceType.horse => 'H',
      PieceType.dragon => 'D',
      _ => '?',
    };

    final colorPart = piece.isBlack ? '1' : '0';
    return '$typePart$colorPart';
  }

  /// 同一局面の出現回数を数える
  static int countBoardRepetition(
    List<String> boardHistory,
    String currentBoardHash,
  ) {
    int count = 0;
    for (final hash in boardHistory) {
      if (hash == currentBoardHash) {
        count++;
      }
    }
    // 現在の局面も含める
    count++;
    return count;
  }

  /// 千日手か判定（同一局面が4回出現）
  static bool isThreefoldRepetition(
    List<String> boardHistory,
    String currentBoardHash,
  ) {
    return countBoardRepetition(boardHistory, currentBoardHash) >= 4;
  }

  /// 連続王手の千日手か判定
  /// Note: このメソッドは moveHistory も必要とするため、実装は別途
  static bool isContinuousCheckRepetition(
    List<Move> moveHistory,
    bool checkingPlayerIsBlack, {
    int requiredChecks = 4,
  }) {
    if (moveHistory.isEmpty) return false;

    var consecutiveChecks = 0;

    for (int i = moveHistory.length - 1; i >= 0; i--) {
      final move = moveHistory[i];

      if (move.isBlack != checkingPlayerIsBlack) {
        continue;
      }

      if (!move.isCheck) {
        return false;
      }

      consecutiveChecks++;
      if (consecutiveChecks >= requiredChecks) {
        return true;
      }
    }

    return false;
  }

  /// 局面の正規化（駒台を含むハッシュ）
  static String getFullGameHash(
    Board board,
    bool isBlackTurn,
    Map<PieceType, int> blackCaptured,
    Map<PieceType, int> whiteCaptured,
  ) {
    final buffer = StringBuffer();

    // 盤面ハッシュ
    buffer.write(getBoardHash(board, isBlackTurn));

    // 先手の駒台
    buffer.write('|B:');
    _appendCapturedHash(buffer, blackCaptured);

    // 後手の駒台
    buffer.write('|W:');
    _appendCapturedHash(buffer, whiteCaptured);

    return buffer.toString();
  }

  static void _appendCapturedHash(
    StringBuffer buffer,
    Map<PieceType, int> captured,
  ) {
    const order = [
      PieceType.rook,
      PieceType.bishop,
      PieceType.gold,
      PieceType.silver,
      PieceType.knight,
      PieceType.lance,
      PieceType.pawn,
    ];

    for (final type in order) {
      final count = captured[type] ?? 0;
      if (count > 0) {
        buffer.write('${type.name}:$count,');
      }
    }
  }

  /// ステイルメイト判定（将棋では通常発生しない）
  static bool isStalemate(
    Board board,
    bool isBlackTurn,
    bool hasLegalMoves,
  ) {
    // 将棋ではステイルメイトは通常発生しない
    // 持将棋などの特殊ルールでのみ考慮
    return !hasLegalMoves;
  }
}
