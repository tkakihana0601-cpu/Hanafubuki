import 'package:flutter/material.dart';

enum BoardStyleType { classic, light, dark, green }

enum PieceStyleType { classic, flat, brush }

class BoardThemeSettings {
  final BoardStyleType boardStyle;
  final PieceStyleType pieceStyle;
  final bool autoFlip;

  const BoardThemeSettings({
    required this.boardStyle,
    required this.pieceStyle,
    required this.autoFlip,
  });

  BoardThemeSettings copyWith({
    BoardStyleType? boardStyle,
    PieceStyleType? pieceStyle,
    bool? autoFlip,
  }) {
    return BoardThemeSettings(
      boardStyle: boardStyle ?? this.boardStyle,
      pieceStyle: pieceStyle ?? this.pieceStyle,
      autoFlip: autoFlip ?? this.autoFlip,
    );
  }
}

class BoardThemeData {
  final List<Color> boardGradient;
  final Color squareColor;
  final Color borderColor;
  final Color grainPrimary;
  final Color grainAccent;
  final List<Color> pieceGradient;
  final Color pieceBorder;
  final Color pieceText;
  final String? pieceFontFamily;

  const BoardThemeData({
    required this.boardGradient,
    required this.squareColor,
    required this.borderColor,
    required this.grainPrimary,
    required this.grainAccent,
    required this.pieceGradient,
    required this.pieceBorder,
    required this.pieceText,
    required this.pieceFontFamily,
  });
}

class BoardThemeService extends ChangeNotifier {
  BoardThemeSettings _settings = const BoardThemeSettings(
    boardStyle: BoardStyleType.classic,
    pieceStyle: PieceStyleType.classic,
    autoFlip: true,
  );

  BoardThemeSettings get settings => _settings;

  void updateSettings(BoardThemeSettings settings) {
    _settings = settings;
    notifyListeners();
  }

  void updateBoardStyle(BoardStyleType style) {
    _settings = _settings.copyWith(boardStyle: style);
    notifyListeners();
  }

  void updatePieceStyle(PieceStyleType style) {
    _settings = _settings.copyWith(pieceStyle: style);
    notifyListeners();
  }

  void updateAutoFlip(bool value) {
    _settings = _settings.copyWith(autoFlip: value);
    notifyListeners();
  }

  BoardThemeData get themeData {
    final board = switch (_settings.boardStyle) {
      BoardStyleType.classic => const BoardThemeData(
          boardGradient: [Color(0xFFF1D9AA), Color(0xFFE1B877)],
          squareColor: Color(0xFFF1D2A1),
          borderColor: Color(0xFF5A3A20),
          grainPrimary: Color(0xFFB07A3E),
          grainAccent: Color(0xFF8A5A2B),
          pieceGradient: [
            Color(0xFFF6DEB5),
            Color(0xFFE9C48A),
            Color(0xFFD9A867)
          ],
          pieceBorder: Color(0xFF1B1B1B),
          pieceText: Color(0xFF3E2A14),
          pieceFontFamily: null,
        ),
      BoardStyleType.light => const BoardThemeData(
          boardGradient: [Color(0xFFF5E8C8), Color(0xFFEAD3A2)],
          squareColor: Color(0xFFF3DEB6),
          borderColor: Color(0xFF7A5A35),
          grainPrimary: Color(0xFFB68A55),
          grainAccent: Color(0xFF9B6B3C),
          pieceGradient: [
            Color(0xFFF7E7C8),
            Color(0xFFF1D6A2),
            Color(0xFFE6BC7E)
          ],
          pieceBorder: Color(0xFF3A2A1A),
          pieceText: Color(0xFF3E2A14),
          pieceFontFamily: null,
        ),
      BoardStyleType.dark => const BoardThemeData(
          boardGradient: [Color(0xFFD0B18B), Color(0xFFB28A5A)],
          squareColor: Color(0xFFC9A777),
          borderColor: Color(0xFF3D2A1A),
          grainPrimary: Color(0xFF7B4C24),
          grainAccent: Color(0xFF5A391B),
          pieceGradient: [
            Color(0xFFF1D7B5),
            Color(0xFFE0BC87),
            Color(0xFFCD9B5B)
          ],
          pieceBorder: Color(0xFF1A120B),
          pieceText: Color(0xFF2B1B0C),
          pieceFontFamily: null,
        ),
      BoardStyleType.green => const BoardThemeData(
          boardGradient: [Color(0xFFB9D6B5), Color(0xFF8FB58F)],
          squareColor: Color(0xFFB3D0AE),
          borderColor: Color(0xFF365136),
          grainPrimary: Color(0xFF6A8C6A),
          grainAccent: Color(0xFF4D6B4D),
          pieceGradient: [
            Color(0xFFF3E2C1),
            Color(0xFFE6CBA1),
            Color(0xFFD6B079)
          ],
          pieceBorder: Color(0xFF2B2B2B),
          pieceText: Color(0xFF3E2A14),
          pieceFontFamily: null,
        ),
    };

    return switch (_settings.pieceStyle) {
      PieceStyleType.classic => board,
      PieceStyleType.flat => BoardThemeData(
          boardGradient: board.boardGradient,
          squareColor: board.squareColor,
          borderColor: board.borderColor,
          grainPrimary: board.grainPrimary,
          grainAccent: board.grainAccent,
          pieceGradient: const [Color(0xFFF4E3C5), Color(0xFFF4E3C5)],
          pieceBorder: Colors.brown,
          pieceText: Colors.brown.shade800,
          pieceFontFamily: 'Noto Serif JP',
        ),
      PieceStyleType.brush => BoardThemeData(
          boardGradient: board.boardGradient,
          squareColor: board.squareColor,
          borderColor: board.borderColor,
          grainPrimary: board.grainPrimary,
          grainAccent: board.grainAccent,
          pieceGradient: const [Color(0xFFF7EAD1), Color(0xFFE9C892)],
          pieceBorder: const Color(0xFF4B3A22),
          pieceText: const Color(0xFF2D1D10),
          pieceFontFamily: 'Hiragino Mincho ProN',
        ),
    };
  }
}
