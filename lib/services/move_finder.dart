import '../models/piece.dart';
import '../main.dart';
import 'shogi_rules.dart';

// マスを表す座標
class Position {
  final int row;
  final int col;

  Position(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '($row, $col)';
}

// 移動を表すクラス
class MoveOption {
  final Position from;
  final Position to;
  final bool canPromote;

  MoveOption({
    required this.from,
    required this.to,
    this.canPromote = false,
  });

  @override
  String toString() =>
      '${from.row}${from.col} → ${to.row}${to.col}${canPromote ? '(成可)' : ''}';
}

// 合法手を生成するクラス
class MoveFinder {
  // 指定位置の駒の全ての合法手を取得
  static List<MoveOption> getLegalMoves(
    Board board,
    int fromRow,
    int fromCol,
    bool isBlack,
  ) {
    final piece = board.getPiece(fromRow, fromCol);

    if (piece.type == PieceType.empty) return [];
    if (piece.isBlack != isBlack) return [];

    final moves = <MoveOption>[];

    // 全マスをチェック
    for (int toRow = 0; toRow < 9; toRow++) {
      for (int toCol = 0; toCol < 9; toCol++) {
        if (ShogiRules.canMovePiece(
          board,
          fromRow,
          fromCol,
          toRow,
          toCol,
          isBlack,
        )) {
          final canPromote = ShogiRules.canPromote(fromRow, toRow, isBlack) &&
              _canPiecePromote(piece);

          moves.add(MoveOption(
            from: Position(fromRow, fromCol),
            to: Position(toRow, toCol),
            canPromote: canPromote,
          ));
        }
      }
    }

    return moves;
  }

  // ボード全体の合法手を取得
  static List<MoveOption> getAllLegalMoves(Board board, bool isBlack) {
    final moves = <MoveOption>[];

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final piece = board.getPiece(row, col);
        if (piece.type != PieceType.empty && piece.isBlack == isBlack) {
          moves.addAll(getLegalMoves(board, row, col, isBlack));
        }
      }
    }

    return moves;
  }

  // 駒が成れるか確認
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

  // 可能な移動を取得（成りは含めない）
  static List<Position> getPossibleDestinations(
    Board board,
    int fromRow,
    int fromCol,
    bool isBlack,
  ) {
    final moves = getLegalMoves(board, fromRow, fromCol, isBlack);
    return moves.map((m) => m.to).toList();
  }
}
