// 駒の種類
enum PieceType {
  // 先手（下）の駒
  pawn, // 歩
  lance, // 香車
  knight, // 桂馬
  silver, // 銀
  gold, // 金
  bishop, // 角行
  rook, // 飛車
  king, // 玉

  // 成った駒
  promotedPawn, // と
  promotedLance, // 成香
  promotedKnight, // 成桂
  promotedSilver, // 成銀
  horse, // 馬
  dragon, // 龍

  empty, // 空
}

// 駒
class Piece {
  final PieceType type;
  final bool isBlack; // true=先手（下）, false=後手（上）
  final bool isPromoted;

  const Piece({
    required this.type,
    required this.isBlack,
    this.isPromoted = false,
  });

  // 駒を文字列で表現
  String toDisplayString() {
    if (type == PieceType.empty) return '　';

    final typeStr = switch (type) {
      PieceType.pawn => '歩',
      PieceType.lance => '香',
      PieceType.knight => '桂',
      PieceType.silver => '銀',
      PieceType.gold => '金',
      PieceType.bishop => '角',
      PieceType.rook => '飛',
      PieceType.king => '玉',
      PieceType.promotedPawn => 'と',
      PieceType.promotedLance => '成香',
      PieceType.promotedKnight => '成桂',
      PieceType.promotedSilver => '成銀',
      PieceType.horse => '馬',
      PieceType.dragon => '龍',
      _ => '？',
    };

    return isBlack ? typeStr : '$typeStr▲';
  }

  // 駒をコピー
  Piece copyWith({
    PieceType? type,
    bool? isBlack,
    bool? isPromoted,
  }) =>
      Piece(
        type: type ?? this.type,
        isBlack: isBlack ?? this.isBlack,
        isPromoted: isPromoted ?? this.isPromoted,
      );

  // 駒を成る
  Piece promote() {
    final promotedType = switch (type) {
      PieceType.pawn => PieceType.promotedPawn,
      PieceType.lance => PieceType.promotedLance,
      PieceType.knight => PieceType.promotedKnight,
      PieceType.silver => PieceType.promotedSilver,
      PieceType.bishop => PieceType.horse,
      PieceType.rook => PieceType.dragon,
      _ => type,
    };
    return Piece(
      type: promotedType,
      isBlack: isBlack,
      isPromoted: true,
    );
  }

  // 駒の成りを戻す
  Piece unpromote() {
    final unpromotedType = switch (type) {
      PieceType.promotedPawn => PieceType.pawn,
      PieceType.promotedLance => PieceType.lance,
      PieceType.promotedKnight => PieceType.knight,
      PieceType.promotedSilver => PieceType.silver,
      PieceType.horse => PieceType.bishop,
      PieceType.dragon => PieceType.rook,
      _ => type,
    };
    return Piece(
      type: unpromotedType,
      isBlack: isBlack,
      isPromoted: false,
    );
  }

  static const empty = Piece(type: PieceType.empty, isBlack: true);
}
