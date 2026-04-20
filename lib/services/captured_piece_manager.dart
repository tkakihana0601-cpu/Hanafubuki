import '../models/piece.dart';
import '../main.dart';

/// 持ち駒（駒台）を管理するクラス
class CapturedPieceManager {
  // 先手の持ち駒
  final Map<PieceType, int> blackCapturedPieces = {
    PieceType.pawn: 0,
    PieceType.lance: 0,
    PieceType.knight: 0,
    PieceType.silver: 0,
    PieceType.gold: 0,
    PieceType.bishop: 0,
    PieceType.rook: 0,
  };

  // 後手の持ち駒
  final Map<PieceType, int> whiteCapturedPieces = {
    PieceType.pawn: 0,
    PieceType.lance: 0,
    PieceType.knight: 0,
    PieceType.silver: 0,
    PieceType.gold: 0,
    PieceType.bishop: 0,
    PieceType.rook: 0,
  };

  /// 駒を捕獲（駒台に追加）
  void capturePiece(Piece piece, bool capturerIsBlack) {
    if (piece.type == PieceType.empty || piece.type == PieceType.king) {
      return; // 玉は駒台に追加されない
    }

    // 成駒を元に戻す
    final baseType = _getBasePieceType(piece.type);

    final container =
        capturerIsBlack ? blackCapturedPieces : whiteCapturedPieces;
    container[baseType] = (container[baseType] ?? 0) + 1;
  }

  /// 駒を打つ（駒台から移動）
  bool dropPiece(PieceType type, bool isBlack) {
    if (type == PieceType.empty || type == PieceType.king) {
      return false; // 玉は打てない
    }

    // 成駒は打ち下ろせない（元の駒を打つ）
    final baseType = _getBasePieceType(type);

    final container = isBlack ? blackCapturedPieces : whiteCapturedPieces;
    if ((container[baseType] ?? 0) <= 0) {
      return false; // 駒がない
    }

    container[baseType] = (container[baseType] ?? 0) - 1;
    return true;
  }

  /// 駒の枚数を取得
  int getCount(PieceType type, bool isBlack) {
    if (type == PieceType.empty || type == PieceType.king) {
      return 0;
    }

    final baseType = _getBasePieceType(type);
    final container = isBlack ? blackCapturedPieces : whiteCapturedPieces;
    return container[baseType] ?? 0;
  }

  /// 駒台をリセット
  void reset() {
    blackCapturedPieces.forEach((key, _) => blackCapturedPieces[key] = 0);
    whiteCapturedPieces.forEach((key, _) => whiteCapturedPieces[key] = 0);
  }

  /// 成駒から元の駒に戻す
  static PieceType _getBasePieceType(PieceType type) {
    return switch (type) {
      PieceType.promotedPawn => PieceType.pawn,
      PieceType.promotedLance => PieceType.lance,
      PieceType.promotedKnight => PieceType.knight,
      PieceType.promotedSilver => PieceType.silver,
      PieceType.horse => PieceType.bishop,
      PieceType.dragon => PieceType.rook,
      _ => type,
    };
  }

  /// 駒台の文字列表現
  String getDisplayString(bool isBlack) {
    final container = isBlack ? blackCapturedPieces : whiteCapturedPieces;
    final parts = <String>[];

    final order = [
      PieceType.rook,
      PieceType.bishop,
      PieceType.gold,
      PieceType.silver,
      PieceType.knight,
      PieceType.lance,
      PieceType.pawn,
    ];

    for (final type in order) {
      final count = container[type] ?? 0;
      if (count > 0) {
        final name = _getPieceName(type);
        parts.add(count > 1 ? '$name×$count' : name);
      }
    }

    return parts.isEmpty ? 'なし' : parts.join('、');
  }

  /// 駒の名前を取得
  static String _getPieceName(PieceType type) {
    return switch (type) {
      PieceType.pawn => '歩',
      PieceType.lance => '香',
      PieceType.knight => '桂',
      PieceType.silver => '銀',
      PieceType.gold => '金',
      PieceType.bishop => '角',
      PieceType.rook => '飛',
      _ => '？',
    };
  }

  /// 二歩の判定（同じ筋に歩があるか）
  bool hasDoublePlayersInColumn(Board board, int col, bool isBlack) {
    return _hasPlayerPawnInColumn(board, col, isBlack);
  }

  /// ボード上で同じ筋に自分の歩があるか確認
  bool _hasPlayerPawnInColumn(Board board, int col, bool isBlack) {
    for (int row = 0; row < 9; row++) {
      final piece = board.getPiece(row, col);
      if (piece.type == PieceType.pawn && piece.isBlack == isBlack) {
        return true;
      }
    }
    return false;
  }
}
