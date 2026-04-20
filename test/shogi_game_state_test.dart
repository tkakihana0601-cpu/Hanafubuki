import 'package:flutter_test/flutter_test.dart';
import 'package:hachinana_shogi/main.dart';
import 'package:hachinana_shogi/models/piece.dart';
import 'package:hachinana_shogi/services/shogi_game_state.dart';

void main() {
  group('ShogiGameState basic flow', () {
    test('Move updates turn and move count', () {
      final state = ShogiGameState();
      state.board = Board.empty();
      state.board.squares[6][4] =
          const Piece(type: PieceType.pawn, isBlack: true);
      state.board.squares[2][4] =
          const Piece(type: PieceType.pawn, isBlack: false);

      state.selectPiece(6, 4);
      state.movePiece(6, 4, 5, 4);

      expect(state.moveCount, 1);
      expect(state.isBlackTurn, isFalse);
      expect(state.board.getPiece(5, 4).type, PieceType.pawn);
    });

    test('Drop piece uses captured stock', () {
      final state = ShogiGameState();
      state.board = Board.empty();
      state.capturedPieces.capturePiece(
        const Piece(type: PieceType.pawn, isBlack: false),
        true,
      );

      final dropped = state.dropPiece(PieceType.pawn, 4, 4);
      expect(dropped, isTrue);
      expect(state.board.getPiece(4, 4).type, PieceType.pawn);
      expect(state.capturedPieces.getCount(PieceType.pawn, true), 0);
    });

    test('Promotion applies when requested', () {
      final state = ShogiGameState();
      state.board = Board.empty();
      state.board.squares[1][4] =
          const Piece(type: PieceType.pawn, isBlack: true);

      state.movePiece(1, 4, 0, 4, shouldPromote: true);

      expect(state.board.getPiece(0, 4).type, PieceType.promotedPawn);
      expect(state.moveCount, 1);
      expect(state.isBlackTurn, isFalse);
    });

    test('Undo and redo restore position', () {
      final state = ShogiGameState();
      state.board = Board.empty();
      state.board.squares[6][4] =
          const Piece(type: PieceType.pawn, isBlack: true);

      state.movePiece(6, 4, 5, 4);
      expect(state.board.getPiece(5, 4).type, PieceType.pawn);

      state.undo();
      expect(state.board.getPiece(6, 4).type, PieceType.pawn);
      expect(state.board.getPiece(5, 4).type, PieceType.empty);

      state.redo();
      expect(state.board.getPiece(5, 4).type, PieceType.pawn);
    });

    test('Illegal move does not update state', () {
      final state = ShogiGameState();
      state.board = Board.empty();
      state.board.squares[6][4] =
          const Piece(type: PieceType.pawn, isBlack: true);

      state.movePiece(6, 4, 7, 4);

      expect(state.moveCount, 0);
      expect(state.board.getPiece(6, 4).type, PieceType.pawn);
      expect(state.board.getPiece(7, 4).type, PieceType.empty);
    });
  });
}
