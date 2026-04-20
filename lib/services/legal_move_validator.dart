import '../models/piece.dart';
import '../main.dart';
import 'shogi_rules.dart';
import 'move_finder.dart';
import 'check_detector.dart';

/// 合法手の検証と生成を行うクラス
class LegalMoveValidator {
  /// 王手放置をチェックして、合法手のみを返す
  static List<MoveOption> getLegalMovesWithCheckValidation(
    Board board,
    int fromRow,
    int fromCol,
    bool isBlack,
  ) {
    final piece = board.getPiece(fromRow, fromCol);

    if (piece.type == PieceType.empty) return [];
    if (piece.isBlack != isBlack) return [];

    // 基本的な移動可能性をチェック
    final basicMoves =
        MoveFinder.getLegalMoves(board, fromRow, fromCol, isBlack);
    final legalMoves = <MoveOption>[];

    // 各移動について、王手放置していないか確認
    for (final move in basicMoves) {
      if (!CheckDetector.wouldBeInCheckAfterMove(
        board,
        fromRow,
        fromCol,
        move.to.row,
        move.to.col,
        isBlack,
      )) {
        legalMoves.add(move);
      }
    }

    return legalMoves;
  }

  /// 全ての合法手を返す（王手放置チェック済み）
  static List<MoveOption> getAllLegalMoves(Board board, bool isBlack) {
    final moves = <MoveOption>[];

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final piece = board.getPiece(row, col);
        if (piece.type != PieceType.empty && piece.isBlack == isBlack) {
          moves.addAll(
              getLegalMovesWithCheckValidation(board, row, col, isBlack));
        }
      }
    }

    return moves;
  }

  /// 特定の移動が合法手か判定
  static bool isMoveLegal(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    int toCol,
    bool isBlack,
  ) {
    // 基本的なルール確認
    if (!ShogiRules.canMovePiece(
        board, fromRow, fromCol, toRow, toCol, isBlack)) {
      return false;
    }

    // 王手放置していないか確認
    if (CheckDetector.wouldBeInCheckAfterMove(
      board,
      fromRow,
      fromCol,
      toRow,
      toCol,
      isBlack,
    )) {
      return false;
    }

    return true;
  }

  /// 詰みの判定（合法手がなく、王手されている）
  static bool isCheckmate(Board board, bool isBlack) {
    // 王手されているか確認
    if (!CheckDetector.isInCheck(board, isBlack)) {
      return false;
    }

    // 合法手があるか確認
    final legalMoves = getAllLegalMoves(board, isBlack);
    return legalMoves.isEmpty;
  }

  /// 動ける駒があるか（詰みでないか）
  static bool hasLegalMove(Board board, bool isBlack) {
    final moves = getAllLegalMoves(board, isBlack);
    return moves.isNotEmpty;
  }

  /// 王手されているか確認
  static bool isInCheck(Board board, bool isBlack) {
    return CheckDetector.isInCheck(board, isBlack);
  }

  /// 必ず成らなければならない移動か判定
  static bool mustPromote(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    bool isBlack,
  ) {
    final piece = board.getPiece(fromRow, fromCol);

    // 成り駒は成り直しできない
    if (piece.isPromoted) return false;

    // 相手陣でない場合は成る必要なし
    if (!ShogiRules.canPromote(fromRow, toRow, isBlack)) return false;

    // 成れない駒は成る必要なし
    if (!_canPiecePromote(piece)) return false;

    // 成り必須の条件をチェック
    return switch (piece.type) {
      // 歩が最終段に進む
      PieceType.pawn => toRow == (isBlack ? 0 : 8),

      // 香が最終段に進む
      PieceType.lance => toRow == (isBlack ? 0 : 8),

      // 桂が最終2段に進む
      PieceType.knight =>
        toRow == (isBlack ? 0 : 8) || toRow == (isBlack ? 1 : 7),
      _ => false,
    };
  }

  /// 成れるか判定
  static bool canPromote(
    Board board,
    int fromRow,
    int fromCol,
    int toRow,
    bool isBlack,
  ) {
    final piece = board.getPiece(fromRow, fromCol);

    // 成り駒は成り直しできない
    if (piece.isPromoted) return false;

    // 相手陣でない場合は成れない
    if (!ShogiRules.canPromote(fromRow, toRow, isBlack)) return false;

    // 成れない駒型
    if (!_canPiecePromote(piece)) return false;

    return true;
  }

  /// 駒が成れるか確認
  static bool _canPiecePromote(Piece piece) {
    return switch (piece.type) {
      PieceType.pawn ||
      PieceType.lance ||
      PieceType.knight ||
      PieceType.silver ||
      PieceType.bishop ||
      PieceType.rook =>
        true,
      _ => false,
    };
  }
}
