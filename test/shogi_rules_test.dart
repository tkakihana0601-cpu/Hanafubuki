import 'package:flutter_test/flutter_test.dart';
import 'package:hachinana_shogi/main.dart';
import 'package:hachinana_shogi/models/piece.dart';
import 'package:hachinana_shogi/services/shogi_rules.dart';
import 'package:hachinana_shogi/services/shogi_game_validator.dart';

void main() {
  group('ShogiRules movement', () {
    test('Pawn moves forward one', () {
      final board = Board.empty();
      board.squares[6][4] = const Piece(type: PieceType.pawn, isBlack: true);

      expect(ShogiRules.canMovePiece(board, 6, 4, 5, 4, true), isTrue);
      expect(ShogiRules.canMovePiece(board, 6, 4, 7, 4, true), isFalse);
    });

    test('Lance path blocked', () {
      final board = Board.empty();
      board.squares[6][4] = const Piece(type: PieceType.lance, isBlack: true);
      board.squares[5][4] = const Piece(type: PieceType.pawn, isBlack: true);

      expect(ShogiRules.canMovePiece(board, 6, 4, 4, 4, true), isFalse);
    });

    test('Knight moves in correct L shape', () {
      final board = Board.empty();
      board.squares[7][4] = const Piece(type: PieceType.knight, isBlack: true);

      expect(ShogiRules.canMovePiece(board, 7, 4, 5, 3, true), isTrue);
      expect(ShogiRules.canMovePiece(board, 7, 4, 6, 3, true), isFalse);
    });

    test('Gold cannot move backward diagonally', () {
      final board = Board.empty();
      board.squares[4][4] = const Piece(type: PieceType.gold, isBlack: true);

      expect(ShogiRules.canMovePiece(board, 4, 4, 5, 3, true), isFalse);
      expect(ShogiRules.canMovePiece(board, 4, 4, 3, 3, true), isTrue);
    });
  });

  group('Promotion rules', () {
    test('Pawn must promote on last rank', () {
      final board = Board.empty();
      board.squares[1][4] = const Piece(type: PieceType.pawn, isBlack: true);

      expect(
        ShogiGameValidator.isMustPromote(board, 1, 4, 0, true),
        isTrue,
      );
    });

    test('Piece can promote when entering zone', () {
      final board = Board.empty();
      board.squares[3][4] = const Piece(type: PieceType.silver, isBlack: true);

      expect(
        ShogiGameValidator.canPromote(board, 3, 4, 2, true),
        isTrue,
      );
    });
  });
}
