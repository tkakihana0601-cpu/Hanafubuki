import '../models/piece.dart';
import '../main.dart';
import 'check_detector.dart';
import 'legal_move_validator.dart';
import 'captured_piece_manager.dart';
import 'drop_move_validator.dart';
import 'draw_detector.dart';

/// 将棋ゲームの検証と終局判定を行う統合クラス
class ShogiGameValidator {
  /// ゲームの状態を総合的に判定
  static GameStatus getGameStatus(
    Board board,
    bool isBlackTurn,
    List<String> boardHistory,
    String currentBoardHash,
    List<Move> moveHistory,
    CapturedPieceManager capturedManager,
  ) {
    // 合法手があるか
    final hasLegal = LegalMoveValidator.hasLegalMove(board, isBlackTurn);

    // 王手されているか
    final inCheck = CheckDetector.isInCheck(board, isBlackTurn);

    // 千日手か
    final isRepetition = DrawDetector.isThreefoldRepetition(
      boardHistory,
      currentBoardHash,
    );

    // 持将棋（双方の玉が相手陣に入った場合の点数判定）
    final jishogiResult = _checkJishogi(board, capturedManager);

    // 連続王手の千日手か（反則負け）
    final continuousCheckByPreviousPlayer = isRepetition &&
        DrawDetector.isContinuousCheckRepetition(
          moveHistory,
          !isBlackTurn,
        );

    // 終局判定
    if (!hasLegal) {
      if (inCheck) {
        return GameStatus.checkmate;
      } else {
        // 合法手がなく王手されていない = 詰み状態（通常は不可能だが念のため）
        return GameStatus.stalemate;
      }
    }

    if (isRepetition) {
      if (continuousCheckByPreviousPlayer) {
        return GameStatus.loss_continuousCheck;
      }
      return GameStatus.draw_threefoldRepetition;
    }

    if (jishogiResult != null) {
      return switch (jishogiResult) {
        _JishogiResult.draw => GameStatus.draw_jishogi,
        _JishogiResult.blackLoss => GameStatus.loss_jishogi_black,
        _JishogiResult.whiteLoss => GameStatus.loss_jishogi_white,
      };
    }

    if (inCheck) {
      return GameStatus.inCheck;
    }

    return GameStatus.normal;
  }

  /// 移動が有効か総合判定
  static MoveValidationResult validateMove(
      Board board, int fromRow, int fromCol, int toRow, int toCol, bool isBlack,
      [bool shouldPromote = false]) {
    // 盤外チェック
    if (!_isValidPos(toRow, toCol)) {
      return MoveValidationResult(
        isValid: false,
        reason: '盤外です',
      );
    }

    // 基本的な移動ルールをチェック
    if (!LegalMoveValidator.isMoveLegal(
      board,
      fromRow,
      fromCol,
      toRow,
      toCol,
      isBlack,
    )) {
      return MoveValidationResult(
        isValid: false,
        reason: 'ルール違反です',
      );
    }

    // 成りの必須判定
    if (LegalMoveValidator.mustPromote(
        board, fromRow, fromCol, toRow, isBlack)) {
      if (!shouldPromote) {
        return MoveValidationResult(
          isValid: false,
          reason: '成る必要があります',
        );
      }
    }

    return MoveValidationResult(isValid: true);
  }

  /// 駒の打ちが有効か総合判定
  static MoveValidationResult validateDrop(
    Board board,
    int toRow,
    int toCol,
    PieceType pieceType,
    bool isBlack,
    CapturedPieceManager capturedManager,
  ) {
    // 盤外チェック
    if (!_isValidPos(toRow, toCol)) {
      return MoveValidationResult(
        isValid: false,
        reason: '盤外です',
      );
    }

    // 空マスチェック
    if (board.getPiece(toRow, toCol).type != PieceType.empty) {
      return MoveValidationResult(
        isValid: false,
        reason: 'そのマスには駒があります',
      );
    }

    // 駒台チェック
    if (capturedManager.getCount(pieceType, isBlack) <= 0) {
      return MoveValidationResult(
        isValid: false,
        reason: 'その駒を持っていません',
      );
    }

    // 打ち可能位置チェック
    if (!DropMoveValidator.canDropPiece(
      board,
      toRow,
      toCol,
      pieceType,
      isBlack,
      capturedManager,
    )) {
      return MoveValidationResult(
        isValid: false,
        reason: 'その場所に駒を打てません',
      );
    }

    return MoveValidationResult(isValid: true);
  }

  /// 位置が有効か
  static bool _isValidPos(int row, int col) {
    return row >= 0 && row < 9 && col >= 0 && col < 9;
  }

  /// 成りが必須か判定
  static bool isMustPromote(
      Board board, int fromRow, int fromCol, int toRow, bool isBlack) {
    return LegalMoveValidator.mustPromote(
        board, fromRow, fromCol, toRow, isBlack);
  }

  /// 成れるか判定
  static bool canPromote(
      Board board, int fromRow, int fromCol, int toRow, bool isBlack) {
    return LegalMoveValidator.canPromote(
        board, fromRow, fromCol, toRow, isBlack);
  }

  // 持将棋の判定（双方の玉が相手陣に入ったときの点数計算）
  static _JishogiResult? _checkJishogi(
    Board board,
    CapturedPieceManager capturedManager,
  ) {
    final blackKingPos = _findKingPosition(board, true);
    final whiteKingPos = _findKingPosition(board, false);

    if (blackKingPos == null || whiteKingPos == null) return null;

    final blackInCamp = blackKingPos.row <= 2;
    final whiteInCamp = whiteKingPos.row >= 6;

    if (!blackInCamp || !whiteInCamp) return null;

    final blackPoints = _calculatePoints(board, capturedManager, true);
    final whitePoints = _calculatePoints(board, capturedManager, false);

    const threshold = 24;

    if (blackPoints >= threshold && whitePoints >= threshold) {
      return _JishogiResult.draw;
    }

    if (blackPoints < threshold && whitePoints >= threshold) {
      return _JishogiResult.blackLoss;
    }

    if (whitePoints < threshold && blackPoints >= threshold) {
      return _JishogiResult.whiteLoss;
    }

    return _JishogiResult.draw;
  }

  static _KingPosition? _findKingPosition(Board board, bool isBlack) {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final piece = board.getPiece(row, col);
        if (piece.type == PieceType.king && piece.isBlack == isBlack) {
          return _KingPosition(row: row, col: col);
        }
      }
    }
    return null;
  }

  static int _calculatePoints(
    Board board,
    CapturedPieceManager capturedManager,
    bool isBlack,
  ) {
    var points = 0;

    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        final piece = board.getPiece(row, col);
        if (piece.type != PieceType.empty && piece.isBlack == isBlack) {
          points += _piecePointValue(piece.type);
        }
      }
    }

    final captured = isBlack
        ? capturedManager.blackCapturedPieces
        : capturedManager.whiteCapturedPieces;

    captured.forEach((type, count) {
      points += _piecePointValue(type) * count;
    });

    return points;
  }

  static int _piecePointValue(PieceType type) {
    return switch (type) {
      PieceType.rook ||
      PieceType.bishop ||
      PieceType.horse ||
      PieceType.dragon =>
        5,
      PieceType.king => 0,
      _ => 1,
    };
  }
}

/// ゲームの状態
enum GameStatus {
  normal, // 通常
  inCheck, // 王手
  checkmate, // 詰み（負け）
  draw_threefoldRepetition, // 千日手（引き分け）
  loss_continuousCheck, // 連続王手の千日手（反則負け）
  draw_jishogi, // 持将棋（引き分け）
  loss_jishogi_black, // 持将棋（先手の点不足）
  loss_jishogi_white, // 持将棋（後手の点不足）
  stalemate, // ステイルメイト（通常は将棋にない）
}

enum _JishogiResult {
  draw,
  blackLoss,
  whiteLoss,
}

class _KingPosition {
  final int row;
  final int col;

  _KingPosition({required this.row, required this.col});
}

/// 移動バリデーション結果
class MoveValidationResult {
  final bool isValid;
  final String reason;

  MoveValidationResult({
    required this.isValid,
    this.reason = '',
  });

  @override
  String toString() => isValid ? '有効' : '無効: $reason';
}
