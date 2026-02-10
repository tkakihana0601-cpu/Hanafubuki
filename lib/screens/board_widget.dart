import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../main.dart';
import '../models/piece.dart';
import '../services/move_finder.dart';
import '../services/board_theme_service.dart';

class BoardWidget extends StatelessWidget {
  final Board board;
  final Future<void> Function(int, int, int, int)? onMovePiece;
  final int? selectedRow;
  final int? selectedCol;
  final List<Position>? possibleMoves;
  final bool flipBoard;
  final BoardThemeData? themeData;

  const BoardWidget({
    super.key,
    required this.board,
    this.onMovePiece,
    this.selectedRow,
    this.selectedCol,
    this.possibleMoves,
    this.flipBoard = false,
    this.themeData,
  });

  @override
  Widget build(BuildContext context) {
    final theme = themeData ??
        const BoardThemeData(
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
        );
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.borderColor, width: 3),
        gradient: LinearGradient(
          colors: theme.boardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.borderColor.withValues(alpha: 0.2),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WoodGrainPainter(
                primary: theme.grainPrimary,
                accent: theme.grainAccent,
              ),
            ),
          ),
          GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 9,
            ),
            itemCount: 81, // 9x9 将棋盤
            itemBuilder: (context, index) {
              final displayRow = index ~/ 9;
              final displayCol = index % 9;
              final row = flipBoard ? 8 - displayRow : displayRow;
              final col = flipBoard ? 8 - displayCol : displayCol;
              final piece = board.getPiece(row, col);
              final isSelected = selectedRow == row && selectedCol == col;
              final isPossibleMove = possibleMoves?.any(
                    (p) => p.row == row && p.col == col,
                  ) ??
                  false;

              return GestureDetector(
                onTap: () async {
                  if (onMovePiece != null) {
                    await onMovePiece!(row, col, row, col);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.brown.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    color: isSelected
                        ? Colors.yellow.shade300
                        : isPossibleMove
                            ? Colors.green.shade200
                            : _getSquareColor(displayRow, displayCol, theme),
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isPossibleMove)
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.green.shade600,
                            ),
                          ),
                        if (piece.type != PieceType.empty)
                          ShogiPieceWidget(
                            piece: piece,
                            theme: theme,
                            flipBoard: flipBoard,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getSquareColor(
    int row,
    int col,
    BoardThemeData theme,
  ) {
    return theme.squareColor;
  }
}

class ShogiPieceWidget extends StatelessWidget {
  final Piece piece;
  final BoardThemeData theme;
  final bool flipBoard;

  const ShogiPieceWidget({
    super.key,
    required this.piece,
    required this.theme,
    this.flipBoard = false,
  });

  @override
  Widget build(BuildContext context) {
    final isBlack = piece.isBlack;
    final display = piece.toDisplayString().replaceAll('▲', '');

    final shape = ClipPath(
      clipper: _ShogiPieceClipper(),
      child: Container(
        width: 40,
        height: 36,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: theme.pieceGradient,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.0, 0.55, 1.0],
          ),
          border: Border.all(color: theme.pieceBorder, width: 1.1),
          boxShadow: [
            BoxShadow(
              color: theme.pieceBorder.withValues(alpha: 0.35),
              offset: const Offset(0, 2),
              blurRadius: 4,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 3),
            width: 20,
            height: 1.6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      ),
    );

    final angle =
        flipBoard ? (isBlack ? math.pi : 0.0) : (isBlack ? 0.0 : math.pi);

    return SizedBox(
      width: 40,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: angle,
            child: shape,
          ),
          Text(
            display,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.pieceText,
              fontFamily: theme.pieceFontFamily,
              fontFamilyFallback: const [
                'Noto Serif JP',
                'Hiragino Mincho ProN',
                'serif',
              ],
              letterSpacing: 0.4,
              shadows: [
                Shadow(
                  color: Colors.white.withValues(alpha: 0.6),
                  offset: const Offset(0, 1),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShogiPieceClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      // 上端の尖り（等腰三角形）
      ..moveTo(w * 0.5, 0)
      ..lineTo(w * 0.78, h * 0.22)
      // 下端の広い台形
      ..lineTo(w * 0.9, h * 0.9)
      ..lineTo(w * 0.1, h * 0.9)
      ..lineTo(w * 0.22, h * 0.22)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _WoodGrainPainter extends CustomPainter {
  final Color primary;
  final Color accent;

  _WoodGrainPainter({
    required this.primary,
    required this.accent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = primary.withValues(alpha: 0.18)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (double y = 5; y < size.height; y += 14) {
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(
          size.width * 0.3,
          y + 1.5,
          size.width * 0.6,
          y - 1.0,
        )
        ..quadraticBezierTo(
          size.width * 0.85,
          y + 1.5,
          size.width,
          y,
        );
      canvas.drawPath(path, paint);
    }

    final accent = Paint()
      ..color = this.accent.withValues(alpha: 0.08)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    for (double y = 10; y < size.height; y += 42) {
      final path = Path()
        ..moveTo(0, y)
        ..quadraticBezierTo(
          size.width * 0.25,
          y + 2.5,
          size.width * 0.55,
          y - 2.0,
        )
        ..quadraticBezierTo(
          size.width * 0.8,
          y + 2.0,
          size.width,
          y,
        );
      canvas.drawPath(path, accent);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
