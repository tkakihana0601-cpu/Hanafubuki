import '../models/piece.dart';
import '../main.dart';

// 将棋のルールを定義するクラス
class ShogiRules {
  // 駒が指定方向に移動できるか確認
  static bool canMovePiece(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    bool isBlack,
  ) {
    final piece = board.getPiece(fromRow, fromCol);

    // 駒がない
    if (piece.type == PieceType.empty) return false;

    // 駒の色が一致しない
    if (piece.isBlack != isBlack) return false;

    // 同じ位置
    if (fromRow == toRow && fromCol == toCol) return false;

    // 盤外
    if (!_isValidPosition(toRow, toCol)) return false;

    // 目的地に同じ色の駒がある
    final targetPiece = board.getPiece(toRow, toCol);
    if (targetPiece.type != PieceType.empty && targetPiece.isBlack == isBlack) {
      return false;
    }

    // 駒ごとのルールで判定
    return _canPieceMove(board, fromRow, fromCol, toRow, toCol, piece);
  }

  // 駒の種類に応じた移動ルール
  static bool _canPieceMove(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    Piece piece,
  ) {
    final rowDiff = (toRow - fromRow).abs();
    final colDiff = (toCol - fromCol).abs();

    return switch (piece.type) {
      PieceType.pawn => _canPawnMove(fromRow, toRow, colDiff, piece.isBlack),
      PieceType.lance =>
        _canLanceMove(board, fromRow, fromCol, toRow, toCol, piece.isBlack),
      PieceType.knight =>
        _canKnightMove(rowDiff, colDiff, fromRow, toRow, piece.isBlack),
      PieceType.silver =>
        _canSilverMove(rowDiff, colDiff, fromRow, toRow, piece.isBlack),
      PieceType.gold =>
        _canGoldMove(fromRow, toRow, rowDiff, colDiff, piece.isBlack),
      PieceType.bishop =>
        _canBishopMove(board, fromRow, fromCol, toRow, toCol, rowDiff, colDiff),
      PieceType.rook =>
        _canRookMove(board, fromRow, fromCol, toRow, toCol, rowDiff, colDiff),
      PieceType.king => _canKingMove(rowDiff, colDiff),
      PieceType.promotedPawn => _canGoldMove(
          fromRow, toRow, rowDiff, colDiff, piece.isBlack), // と金は金と同じ
      PieceType.promotedLance =>
        _canGoldMove(fromRow, toRow, rowDiff, colDiff, piece.isBlack),
      PieceType.promotedKnight =>
        _canGoldMove(fromRow, toRow, rowDiff, colDiff, piece.isBlack),
      PieceType.promotedSilver =>
        _canGoldMove(fromRow, toRow, rowDiff, colDiff, piece.isBlack),
      PieceType.horse =>
        _canHorseMove(board, fromRow, fromCol, toRow, toCol, rowDiff, colDiff),
      PieceType.dragon =>
        _canDragonMove(board, fromRow, fromCol, toRow, toCol, rowDiff, colDiff),
      _ => false,
    };
  }

  // 歩の移動
  static bool _canPawnMove(
    int fromRow,
    int toRow,
    int colDiff,
    bool isBlack,
  ) {
    if (colDiff != 0) return false;
    final direction = isBlack ? -1 : 1;
    return toRow - fromRow == direction;
  }

  // 香車の移動
  static bool _canLanceMove(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    bool isBlack,
  ) {
    final direction = isBlack ? -1 : 1;
    // 同じ列にあり、正しい方向に移動している
    if (fromCol != toCol) return false;
    if ((toRow - fromRow).abs() == 0) return false;
    if ((toRow > fromRow) != (direction > 0)) return false;
    // 経路が塞がっていないか確認
    return _isPathClear(board, fromRow, fromCol, toRow, toCol);
  }

  // 桂馬の移動
  static bool _canKnightMove(
    int rowDiff,
    int colDiff,
    int fromRow,
    int toRow,
    bool isBlack,
  ) {
    if (rowDiff != 2 || colDiff != 1) return false;
    final direction = isBlack ? -1 : 1;
    return toRow - fromRow == 2 * direction;
  }

  // 銀の移動
  static bool _canSilverMove(
    int rowDiff,
    int colDiff,
    int fromRow,
    int toRow,
    bool isBlack,
  ) {
    if (rowDiff != 1 || colDiff > 1) return false;
    final direction = isBlack ? -1 : 1;
    final isForward = (toRow - fromRow) == direction;
    // 前方：3方向（前左・前・前右）
    if (isForward) {
      return true;
    }
    // 後ろ：左右の対角線のみ
    return colDiff == 1;
  }

  // 金の移動
  static bool _canGoldMove(
    int fromRow,
    int toRow,
    int rowDiff,
    int colDiff,
    bool isBlack,
  ) {
    if (rowDiff > 1 || colDiff > 1) return false;
    if (rowDiff == 0 && colDiff == 0) return false;

    final direction = isBlack ? -1 : 1;
    final isForward = (toRow - fromRow) == direction;

    // 横移動は可
    if (rowDiff == 0 && colDiff == 1) return true;
    // 前方向は直進/斜めとも可
    if (isForward) return true;
    // 後ろは直進のみ
    return rowDiff == 1 && colDiff == 0;
  }

  // 角行の移動
  static bool _canBishopMove(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    int rowDiff,
    int colDiff,
  ) {
    if (rowDiff != colDiff) return false;
    return _isPathClear(board, fromRow, fromCol, toRow, toCol);
  }

  // 飛車の移動
  static bool _canRookMove(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    int rowDiff,
    int colDiff,
  ) {
    if (rowDiff != 0 && colDiff != 0) return false;
    return _isPathClear(board, fromRow, fromCol, toRow, toCol);
  }

  // 馬（成角）の移動
  static bool _canHorseMove(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    int rowDiff,
    int colDiff,
  ) {
    // 斜め移動は角と同じ
    if (rowDiff == colDiff) {
      return _isPathClear(board, fromRow, fromCol, toRow, toCol);
    }
    // 前後左右に1マス動ける
    if ((rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1)) {
      return true;
    }
    return false;
  }

  // 龍（成飛）の移動
  static bool _canDragonMove(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    int rowDiff,
    int colDiff,
  ) {
    // 前後左右の移動は飛と同じ
    if (rowDiff == 0 || colDiff == 0) {
      return _isPathClear(board, fromRow, fromCol, toRow, toCol);
    }
    // 斜めに1マス動ける
    if (rowDiff == 1 && colDiff == 1) {
      return true;
    }
    return false;
  }

  // 玉の移動
  static bool _canKingMove(int rowDiff, int colDiff) {
    return rowDiff <= 1 && colDiff <= 1 && (rowDiff > 0 || colDiff > 0);
  }

  // 経路が障害物で塞がっていないか確認
  static bool _isPathClear(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
  ) {
    final rowStep = toRow > fromRow ? 1 : (toRow < fromRow ? -1 : 0);
    final colStep = toCol > fromCol ? 1 : (toCol < fromCol ? -1 : 0);

    var row = fromRow + rowStep;
    var col = fromCol + colStep;

    while (row != toRow || col != toCol) {
      if (board.getPiece(row, col).type != PieceType.empty) {
        return false;
      }
      row += rowStep;
      col += colStep;
    }

    return true;
  }

  // 成れるか確認（移動元または移動先が相手陣）
  static bool canPromote(int fromRow, int toRow, bool isBlack) {
    return _isPromotionZoneRow(fromRow, isBlack) ||
        _isPromotionZoneRow(toRow, isBlack);
  }

  static bool _isPromotionZoneRow(int row, bool isBlack) {
    if (isBlack) {
      // 先手は相手陣（0-2行目）
      return row <= 2;
    } else {
      // 後手は相手陣（6-8行目）
      return row >= 6;
    }
  }

  // 位置が有効か確認
  static bool _isValidPosition(int row, int col) {
    return row >= 0 && row < 9 && col >= 0 && col < 9;
  }
}
