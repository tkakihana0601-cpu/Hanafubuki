import '../models/piece.dart';

class KifMove {
  final int toRow;
  final int toCol;
  final int? fromRow;
  final int? fromCol;
  final bool isDrop;
  final bool promote;
  final PieceType? dropPieceType;

  KifMove({
    required this.toRow,
    required this.toCol,
    this.fromRow,
    this.fromCol,
    required this.isDrop,
    required this.promote,
    this.dropPieceType,
  });
}

class KifParser {
  static List<KifMove> parse(String kif) {
    final moves = <KifMove>[];
    final lines = kif.split(RegExp(r'\r?\n'));
    int? lastToRow;
    int? lastToCol;

    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      if (!RegExp(r'^\d+\s').hasMatch(line)) {
        continue;
      }

      var body = line.replaceFirst(RegExp(r'^\d+\s+'), '');
      body = body.replaceFirst(
          RegExp(r'\s*\(\d{2}:\d{2}\/\d{2}:\d{2}:\d{2}\)\s*$'), '');

      if (body.startsWith('投了')) {
        break;
      }

      int toRow;
      int toCol;
      String rest;

      if (body.startsWith('同')) {
        if (lastToRow == null || lastToCol == null) {
          throw const FormatException('同一手の参照先がありません');
        }
        toRow = lastToRow;
        toCol = lastToCol;
        rest = body.substring(1).trim();
      } else {
        if (body.length < 2) {
          throw FormatException('手の解析に失敗しました: $body');
        }
        final toPart = body.substring(0, 2);
        rest = body.substring(2).trim();
        final pos = _parseToPosition(toPart);
        toRow = pos.$1;
        toCol = pos.$2;
      }

      final promote = rest.contains('成') && !rest.contains('不成');
      final isDrop = rest.contains('打');

      if (isDrop) {
        final pieceText = rest.replaceAll('打', '').replaceAll('成', '').trim();
        final dropType = _pieceTypeFromKif(pieceText);
        if (dropType == null) {
          throw FormatException('打ち駒の種別解析に失敗しました: $rest');
        }
        moves.add(KifMove(
          toRow: toRow,
          toCol: toCol,
          isDrop: true,
          promote: false,
          dropPieceType: dropType,
        ));
      } else {
        final match = RegExp(r'\((\d)(\d)\)').firstMatch(rest);
        if (match == null) {
          throw FormatException('移動元座標が見つかりません: $rest');
        }
        final fromFile = int.parse(match.group(1)!);
        final fromRank = int.parse(match.group(2)!);
        final fromRow = fromRank - 1;
        final fromCol = 9 - fromFile;

        moves.add(KifMove(
          toRow: toRow,
          toCol: toCol,
          fromRow: fromRow,
          fromCol: fromCol,
          isDrop: false,
          promote: promote,
        ));
      }

      lastToRow = toRow;
      lastToCol = toCol;
    }

    return moves;
  }

  static (int, int) _parseToPosition(String toPart) {
    final file = _normalizeDigit(toPart[0]);
    final rank = _normalizeRank(toPart[1]);
    if (file == null || rank == null) {
      throw FormatException('座標の解析に失敗しました: $toPart');
    }
    final row = rank - 1;
    final col = 9 - file;
    return (row, col);
  }

  static int? _normalizeDigit(String ch) {
    const map = {
      '１': 1,
      '２': 2,
      '３': 3,
      '４': 4,
      '５': 5,
      '６': 6,
      '７': 7,
      '８': 8,
      '９': 9,
      '1': 1,
      '2': 2,
      '3': 3,
      '4': 4,
      '5': 5,
      '6': 6,
      '7': 7,
      '8': 8,
      '9': 9,
    };
    return map[ch];
  }

  static int? _normalizeRank(String ch) {
    const map = {
      '一': 1,
      '二': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
    };
    return map[ch];
  }

  static PieceType? _pieceTypeFromKif(String text) {
    return switch (text) {
      '歩' => PieceType.pawn,
      '香' => PieceType.lance,
      '桂' => PieceType.knight,
      '銀' => PieceType.silver,
      '金' => PieceType.gold,
      '角' => PieceType.bishop,
      '飛' => PieceType.rook,
      '玉' => PieceType.king,
      '王' => PieceType.king,
      _ => null,
    };
  }
}
