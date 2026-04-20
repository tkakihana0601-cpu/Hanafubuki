import 'package:flutter_test/flutter_test.dart';
import 'package:hachinana_shogi/main.dart';
import 'package:hachinana_shogi/models/piece.dart';
import 'package:hachinana_shogi/services/captured_piece_manager.dart';
import 'package:hachinana_shogi/services/drop_move_validator.dart';

void main() {
  group('Drop rules', () {
    test('Cannot drop pawn on occupied square', () {
      final board = Board.empty();
      final captured = CapturedPieceManager();
      captured.capturePiece(
        const Piece(type: PieceType.pawn, isBlack: false),
        true,
      );
      board.squares[4][4] = const Piece(type: PieceType.pawn, isBlack: true);

      expect(
        DropMoveValidator.canDropPiece(
          board,
          4,
          4,
          PieceType.pawn,
          true,
          captured,
        ),
        isFalse,
      );
    });

    test('Cannot drop pawn on last rank', () {
      final board = Board.empty();
      final captured = CapturedPieceManager();
      captured.capturePiece(
        const Piece(type: PieceType.pawn, isBlack: false),
        true,
      );

      expect(
        DropMoveValidator.canDropPiece(
          board,
          0,
          4,
          PieceType.pawn,
          true,
          captured,
        ),
        isFalse,
      );
    });

    test('Double pawn in column is rejected', () {
      final board = Board.empty();
      final captured = CapturedPieceManager();
      captured.capturePiece(
        const Piece(type: PieceType.pawn, isBlack: false),
        true,
      );
      board.squares[5][4] = const Piece(type: PieceType.pawn, isBlack: true);

      expect(
        DropMoveValidator.canDropPiece(
          board,
          4,
          4,
          PieceType.pawn,
          true,
          captured,
        ),
        isFalse,
      );
    });
  });
}
