import '../main.dart';
import '../models/piece.dart';
import 'shogi_rules.dart';

/// 王手（チェック）を判定するクラス
class CheckDetector {
  /// 指定の側の玉が相手の攻撃を受けているか判定
  static bool isInCheck(Board board, bool isBlackKing) {
    // 玉の位置を探す
    final kingPos = _findKingPosition(board, isBlackKing);
    if (kingPos == null) return false; // 玉が見つからない（異常）

    // 相手の全ての駒からこの玉が攻撃される位置にあるか確認
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final piece = board.getPiece(row, col);
        
        // 相手の駒をチェック
        if (piece.type != PieceType.empty && piece.isBlack != isBlackKing) {
          // この駒から玉の位置へ攻撃できるか判定
          if (ShogiRules.canMovePiece(
            board,
            row,
            col,
            kingPos.row,
            kingPos.col,
            piece.isBlack,
          )) {
            return true;
          }
        }
      }
    }

    return false;
  }

  /// 指定の駒の移動後に自玉が王手されるか判定
  static bool wouldBeInCheckAfterMove(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    bool isBlack,
  ) {
    // 仮想的に移動を実行した盤面を作成
    final tempBoard = Board.copy(board);
    final piece = tempBoard.getPiece(fromRow, fromCol);
    
    tempBoard.squares[toRow][toCol] = piece;
    tempBoard.squares[fromRow][fromCol] = Piece.empty;

    // 移動後に自玉が王手されているか確認
    return isInCheck(tempBoard, isBlack);
  }

  /// 玉の位置を検索
  static _KingPosition? _findKingPosition(Board board, bool isBlackKing) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final piece = board.getPiece(row, col);
        if (piece.type == PieceType.king && piece.isBlack == isBlackKing) {
          return _KingPosition(row: row, col: col);
        }
      }
    }
    return null;
  }

  /// 相手が指定位置に駒を置いて、その駒で自玉を直接攻撃できるか判定
  /// （打ち歩詰め判定に使用）
  static bool wouldDeliverCheckIfPlaced(
    Board board,
    int placementRow,
    int placementCol,
    PieceType pieceType,
    bool isOpponent,
  ) {
    // 玉の位置を探す
    final kingPos = _findKingPosition(board, !isOpponent);
    if (kingPos == null) return false;

    // 仮想的に駒を置く
    final tempBoard = Board.copy(board);
    tempBoard.squares[placementRow][placementCol] = Piece(
      type: pieceType,
      isBlack: isOpponent,
    );

    // 置いた駒で玉が攻撃される位置にあるか確認
    return ShogiRules.canMovePiece(
      tempBoard,
      placementRow,
      placementCol,
      kingPos.row,
      kingPos.col,
      isOpponent,
    );
  }

  /// 指定位置に玉を動かした後、その玉が王手されるか判定
  static bool wouldKingBeInCheckIfMoved(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    bool isBlack,
  ) {
    // 玉を仮想移動して確認
    return wouldBeInCheckAfterMove(board, fromRow, fromCol, toRow, toCol, isBlack);
  }

  /// 指定位置への玉の移動が有効か判定（相手に取られない）
  static bool isKingMoveLegal(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    bool isBlack,
  ) {
    // 元々ルール上で移動可能か確認
    if (!ShogiRules.canMovePiece(board, fromRow, fromCol, toRow, toCol, isBlack)) {
      return false;
    }

    // 移動後に王手されないか確認
    return !wouldBeInCheckAfterMove(board, fromRow, fromCol, toRow, toCol, isBlack);
  }
}

/// 玉の位置を表すクラス
class _KingPosition {
  final int row;
  final int col;

  _KingPosition({required this.row, required this.col});
}
