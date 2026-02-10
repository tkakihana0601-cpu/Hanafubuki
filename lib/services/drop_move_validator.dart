import '../models/piece.dart';
import '../main.dart';
import 'captured_piece_manager.dart';
import 'legal_move_validator.dart';

/// 持ち駒の打ち（打ち駒）のバリデーションとロジック
class DropMoveValidator {
  /// 駒を打てるマスか判定
  static bool canDropPiece(
    Board board,
    int toRow,
    int toCol,
    PieceType pieceType,
    bool isBlack,
    CapturedPieceManager capturedManager,
  ) {
    // 空マスのみ打ち可能
    if (board.getPiece(toRow, toCol).type != PieceType.empty) {
      return false;
    }

    // 駒台に該当駒があるか確認
    if (capturedManager.getCount(pieceType, isBlack) <= 0) {
      return false;
    }

    // 駒の種類に応じた制約チェック
    if (!_canPieceDropInPosition(toRow, pieceType, isBlack)) {
      return false;
    }

    // 打ち歩詰めのチェック
    if (pieceType == PieceType.pawn) {
      if (_isDropPawnCheckmate(
        board,
        toRow,
        toCol,
        isBlack,
        capturedManager,
      )) {
        return false;
      }
    }

    // 二歩のチェック
    if (pieceType == PieceType.pawn) {
      if (_hasPlayerPawnInColumn(board, toCol, isBlack)) {
        return false;
      }
    }

    return true;
  }

  /// 駒を打つ位置が有効か（駒の種類による制約）
  static bool _canPieceDropInPosition(
      int row, PieceType pieceType, bool isBlack) {
    return switch (pieceType) {
      // 歩・香は最終段に打てない
      PieceType.pawn => row != (isBlack ? 0 : 8),
      PieceType.lance => row != (isBlack ? 0 : 8),

      // 桂は最終2段に打てない
      PieceType.knight => row != (isBlack ? 0 : 8) && row != (isBlack ? 1 : 7),

      // その他は制約なし
      _ => true,
    };
  }

  /// 打ち歩詰めか判定
  static bool _isDropPawnCheckmate(
    Board board,
    int toRow,
    int toCol,
    bool isBlack,
    CapturedPieceManager capturedManager,
  ) {
    // 仮想的に歩を打つ
    final tempBoard = Board.copy(board);
    tempBoard.squares[toRow][toCol] = Piece(
      type: PieceType.pawn,
      isBlack: isBlack,
    );

    // その歩で相手の玉に直接チェックを与えるか確認
    final kingPos = _findOpponentKing(tempBoard, isBlack);
    if (kingPos == null) return false;

    // 打った歩で玉を攻撃できるか確認
    final pawnRow = toRow;
    final direction = isBlack ? -1 : 1;

    // 歩の前方に玉があるか
    if (kingPos.row == pawnRow + direction && kingPos.col == toCol) {
      // 相手が逃げたり、歩を取ったりできるか確認
      // 逃げたり取ったりできない = 詰み = 打ち歩詰め
      return !_hasLegalMove(tempBoard, !isBlack, capturedManager);
    }

    return false;
  }

  /// 二歩の判定（同筋に既に歩があるか）
  static bool _hasPlayerPawnInColumn(Board board, int col, bool isBlack) {
    for (int row = 0; row < 9; row++) {
      final piece = board.getPiece(row, col);
      if (piece.type == PieceType.pawn && piece.isBlack == isBlack) {
        return true;
      }
    }
    return false;
  }

  /// 相手の玉の位置を検索
  static _KingPos? _findOpponentKing(Board board, bool isBlack) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final piece = board.getPiece(row, col);
        if (piece.type == PieceType.king && piece.isBlack != isBlack) {
          return _KingPos(row: row, col: col);
        }
      }
    }
    return null;
  }

  /// 駒が動ける手があるか確認
  static bool _hasLegalMove(
    Board board,
    bool isBlack,
    CapturedPieceManager capturedManager,
  ) {
    if (LegalMoveValidator.getAllLegalMoves(board, isBlack).isNotEmpty) {
      return true;
    }

    const dropOrder = [
      PieceType.pawn,
      PieceType.lance,
      PieceType.knight,
      PieceType.silver,
      PieceType.gold,
      PieceType.bishop,
      PieceType.rook,
    ];

    for (final type in dropOrder) {
      if (capturedManager.getCount(type, isBlack) <= 0) continue;
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          if (_canDropPieceIgnoringPawnMate(
            board,
            row,
            col,
            type,
            isBlack,
            capturedManager,
          )) {
            return true;
          }
        }
      }
    }

    return false;
  }

  static bool _canDropPieceIgnoringPawnMate(
    Board board,
    int toRow,
    int toCol,
    PieceType pieceType,
    bool isBlack,
    CapturedPieceManager capturedManager,
  ) {
    if (board.getPiece(toRow, toCol).type != PieceType.empty) {
      return false;
    }

    if (capturedManager.getCount(pieceType, isBlack) <= 0) {
      return false;
    }

    if (!_canPieceDropInPosition(toRow, pieceType, isBlack)) {
      return false;
    }

    if (pieceType == PieceType.pawn) {
      if (_hasPlayerPawnInColumn(board, toCol, isBlack)) {
        return false;
      }
    }

    return true;
  }
}

class _KingPos {
  final int row;
  final int col;
  _KingPos({required this.row, required this.col});
}
