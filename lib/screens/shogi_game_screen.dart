import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/shogi_game_state.dart';
import '../services/board_theme_service.dart';
import '../services/kif_library_service.dart';
import 'board_widget.dart';
import 'kif_library_screen.dart';
import '../services/shogi_game_validator.dart';
import '../services/legal_move_validator.dart';
import '../services/drop_move_validator.dart';
import '../models/piece.dart';
import '../utils/kif_download.dart';

class ShogiGameScreen extends StatefulWidget {
  const ShogiGameScreen({super.key});

  @override
  State<ShogiGameScreen> createState() => _ShogiGameScreenState();
}

class _ShogiGameScreenState extends State<ShogiGameScreen> {
  PieceType? _selectedDropPieceType;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ShogiGameState(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('将棋'),
          centerTitle: true,
          backgroundColor: Colors.brown.shade800,
          actions: [
            IconButton(
              onPressed: () => _showBoardThemeSheet(context),
              icon: const Icon(Icons.palette),
              tooltip: '盤面カスタマイズ',
            ),
            IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const KifLibraryScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.folder_open),
              tooltip: '棋譜ライブラリ',
            ),
            IconButton(
              onPressed: () => _showKifImportDialog(
                context,
                context.read<ShogiGameState>(),
              ),
              icon: const Icon(Icons.upload_file),
              tooltip: 'KIF入力',
            ),
            IconButton(
              onPressed: () => _showMoveHints(
                context,
                context.read<ShogiGameState>(),
              ),
              icon: const Icon(Icons.lightbulb),
              tooltip: 'ヒント',
            ),
          ],
        ),
        body: Consumer<ShogiGameState>(
          builder: (context, gameState, _) {
            return LayoutBuilder(
              builder: (context, constraints) {
                const infoHeight = 96.0;
                const capturedHeight = 44.0;
                const moveListHeight = 72.0;
                const buttonHeight = 56.0;
                const verticalGaps = 24.0;

                final available = constraints.maxHeight -
                    infoHeight -
                    capturedHeight * 2 -
                    moveListHeight -
                    buttonHeight -
                    verticalGaps;

                final boardSize = available > 0
                    ? available.clamp(220.0, constraints.maxWidth)
                    : 220.0;

                return Column(
                  children: [
                    // ゲーム情報
                    Container(
                      height: infoHeight,
                      color: const Color(0xFFF6E4C4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${gameState.getCurrentPlayerName()}のターン',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '手数: ${gameState.moveCount}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          _buildStatusBanner(gameState),
                        ],
                      ),
                    ),
                    _buildCapturedRow(
                      label: '後手の持ち駒',
                      pieces: gameState.capturedPieces.whiteCapturedPieces,
                      isSelectable: !gameState.isBlackTurn,
                      height: capturedHeight,
                      themeData: context.watch<BoardThemeService>().themeData,
                      flipBoard:
                          context.watch<BoardThemeService>().settings.autoFlip
                              ? !gameState.isBlackTurn
                              : false,
                      ownerIsBlack: false,
                    ),
                    // 盤面
                    SizedBox(
                      height: boardSize,
                      width: boardSize,
                      child: BoardWidget(
                        board: gameState.board,
                        selectedRow: gameState.selectedRow,
                        selectedCol: gameState.selectedCol,
                        onMovePiece: (row, col, _, __) async {
                          await _handleBoardTap(context, gameState, row, col);
                        },
                        possibleMoves: gameState.possibleMoves,
                        flipBoard:
                            context.watch<BoardThemeService>().settings.autoFlip
                                ? !gameState.isBlackTurn
                                : false,
                        themeData: context.watch<BoardThemeService>().themeData,
                      ),
                    ),
                    _buildCapturedRow(
                      label: '先手の持ち駒',
                      pieces: gameState.capturedPieces.blackCapturedPieces,
                      isSelectable: gameState.isBlackTurn,
                      height: capturedHeight,
                      themeData: context.watch<BoardThemeService>().themeData,
                      flipBoard:
                          context.watch<BoardThemeService>().settings.autoFlip
                              ? !gameState.isBlackTurn
                              : false,
                      ownerIsBlack: true,
                    ),
                    // 手数表示
                    Container(
                      height: moveListHeight,
                      color: const Color(0xFFF6E4C4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (gameState.hasKif) _buildKifControls(gameState),
                          const Text(
                            '手数：',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Expanded(
                            child: ListView.builder(
                              itemCount: gameState.moveHistory.length,
                              itemBuilder: (context, index) {
                                final move = gameState.moveHistory[index];
                                final isActive = gameState.hasKif &&
                                    gameState.currentPly == index + 1;
                                return InkWell(
                                  onTap: gameState.hasKif
                                      ? () => gameState.goToPly(index + 1)
                                      : null,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Text(
                                      '${index + 1}. ${move.piece}: ${move.from} → ${move.to}',
                                      style: TextStyle(
                                        fontWeight: isActive
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ボタン
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: SizedBox(
                        height: buttonHeight,
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  gameState.resetGame();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('新しいゲーム'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.brown.shade700,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _showKifDialog(context, gameState),
                                icon: const Icon(Icons.download),
                                label: const Text('KIF出力'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleBoardTap(
    BuildContext context,
    ShogiGameState gameState,
    int row,
    int col,
  ) async {
    if (_selectedDropPieceType != null) {
      final dropped = gameState.dropPiece(_selectedDropPieceType!, row, col);
      if (mounted && dropped) {
        setState(() => _selectedDropPieceType = null);
      }
      return;
    }

    final selectedRow = gameState.selectedRow;
    final selectedCol = gameState.selectedCol;

    if (selectedRow != null && selectedCol != null) {
      final isPossibleMove =
          gameState.possibleMoves.any((p) => p.row == row && p.col == col);

      if (isPossibleMove) {
        final mustPromote = ShogiGameValidator.isMustPromote(
          gameState.board,
          selectedRow,
          selectedCol,
          row,
          gameState.isBlackTurn,
        );

        final canPromote = ShogiGameValidator.canPromote(
          gameState.board,
          selectedRow,
          selectedCol,
          row,
          gameState.isBlackTurn,
        );

        if (mustPromote) {
          gameState.movePiece(selectedRow, selectedCol, row, col,
              shouldPromote: true);
          return;
        }

        if (canPromote) {
          final shouldPromote = await _showPromotionDialog(context);
          gameState.movePiece(selectedRow, selectedCol, row, col,
              shouldPromote: shouldPromote ?? false);
          return;
        }
      }
    }

    gameState.selectPiece(row, col);
  }

  Widget _buildCapturedRow({
    required String label,
    required Map<PieceType, int> pieces,
    required bool isSelectable,
    double height = 48,
    required BoardThemeData themeData,
    required bool flipBoard,
    required bool ownerIsBlack,
  }) {
    const order = [
      PieceType.rook,
      PieceType.bishop,
      PieceType.gold,
      PieceType.silver,
      PieceType.knight,
      PieceType.lance,
      PieceType.pawn,
    ];

    final tiles = order
        .where((type) => (pieces[type] ?? 0) > 0)
        .map(
          (type) => _buildCapturedTile(
            type: type,
            count: pieces[type] ?? 0,
            isSelectable: isSelectable,
            themeData: themeData,
            flipBoard: flipBoard,
            ownerIsBlack: ownerIsBlack,
          ),
        )
        .toList();

    return Container(
      height: height,
      color: Colors.brown.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: tiles.isEmpty
                ? const Text('なし')
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: tiles
                          .map(
                            (tile) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: tile,
                            ),
                          )
                          .toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedTile({
    required PieceType type,
    required int count,
    required bool isSelectable,
    required BoardThemeData themeData,
    required bool flipBoard,
    required bool ownerIsBlack,
  }) {
    final isSelected = _selectedDropPieceType == type;
    final piece = Piece(type: type, isBlack: ownerIsBlack);

    return Opacity(
      opacity: isSelectable ? 1 : 0.6,
      child: InkWell(
        onTap: isSelectable
            ? () {
                setState(() {
                  _selectedDropPieceType = isSelected ? null : type;
                });
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? Colors.orange.shade100 : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.brown.shade400 : Colors.transparent,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ShogiPieceWidget(
                piece: piece,
                theme: themeData,
                flipBoard: flipBoard,
              ),
              Positioned(
                right: -6,
                bottom: -6,
                child: _buildCapturedCountBadge(count),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapturedCountBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.brown.shade700,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '×$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildStatusBanner(ShogiGameState gameState) {
    final isGameOver = gameState.isGameOver();
    final message = gameState.gameMessage.isNotEmpty
        ? gameState.gameMessage
        : '${gameState.getCurrentPlayerName()}のターン';

    final background = isGameOver
        ? Colors.red.shade100
        : (gameState.isInCheck() ? Colors.orange.shade100 : Colors.white);

    final border = isGameOver
        ? Colors.red.shade400
        : (gameState.isInCheck()
            ? Colors.orange.shade400
            : Colors.brown.shade300);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isGameOver ? Colors.red.shade800 : Colors.brown.shade800,
        ),
      ),
    );
  }

  Future<bool?> _showPromotionDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('成りますか？'),
          content: const Text('成る/成らないを選択してください。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('成らない'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('成る'),
            ),
          ],
        );
      },
    );
  }

  void _showBoardThemeSheet(BuildContext context) {
    final service = context.read<BoardThemeService>();
    showModalBottomSheet(
      context: context,
      builder: (context) {
        var settings = service.settings;
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '盤面カスタマイズ',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text('盤の色・質感'),
                  Wrap(
                    spacing: 8,
                    children: BoardStyleType.values.map((style) {
                      return ChoiceChip(
                        label: Text(style.name),
                        selected: settings.boardStyle == style,
                        onSelected: (_) {
                          setState(() {
                            settings = settings.copyWith(boardStyle: style);
                          });
                          service.updateBoardStyle(style);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  const Text('駒デザイン'),
                  Wrap(
                    spacing: 8,
                    children: PieceStyleType.values.map((style) {
                      return ChoiceChip(
                        label: Text(style.name),
                        selected: settings.pieceStyle == style,
                        onSelected: (_) {
                          setState(() {
                            settings = settings.copyWith(pieceStyle: style);
                          });
                          service.updatePieceStyle(style);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('先後の向きを自動調整'),
                    value: settings.autoFlip,
                    onChanged: (value) {
                      setState(() {
                        settings = settings.copyWith(autoFlip: value);
                      });
                      service.updateAutoFlip(value);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showKifDialog(
    BuildContext context,
    ShogiGameState gameState,
  ) async {
    final kif = gameState.exportKif(title: '対局');
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('KIF出力'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: SelectableText(kif),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showKifSaveDialog(context, kif);
              },
              child: const Text('ライブラリ保存'),
            ),
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: kif));
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('コピー'),
            ),
            ElevatedButton(
              onPressed: () {
                final filename =
                    'shogi_${DateTime.now().millisecondsSinceEpoch}.kif';
                downloadKif(filename, kif);
                Navigator.of(context).pop();
              },
              child: const Text('ダウンロード'),
            ),
          ],
        );
      },
    );
  }

  void _showKifSaveDialog(BuildContext context, String kif) {
    final titleController = TextEditingController(text: '対局棋譜');
    final instructorController = TextEditingController(text: '指導者');
    final tagController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('棋譜を保存'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'タイトル'),
              ),
              TextField(
                controller: instructorController,
                decoration: const InputDecoration(labelText: '指導者名'),
              ),
              TextField(
                controller: tagController,
                decoration: const InputDecoration(labelText: 'タグ (カンマ区切り)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim();
                final instructor = instructorController.text.trim();
                if (title.isEmpty || instructor.isEmpty) return;
                final tags = tagController.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
                context.read<KifLibraryService>().addRecord(
                      title: title,
                      instructorName: instructor,
                      date: DateTime.now(),
                      tags: tags,
                      kif: kif,
                    );
                Navigator.of(context).pop();
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showKifImportDialog(
    BuildContext context,
    ShogiGameState gameState,
  ) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    await showDialog<void>(
      context: context,
      builder: (context) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (focusNode.canRequestFocus) {
            focusNode.requestFocus();
          }
        });
        return AlertDialog(
          title: const Text('KIF入力'),
          content: SizedBox(
            width: double.maxFinite,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              maxLines: 12,
              minLines: 8,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              enableInteractiveSelection: true,
              decoration: const InputDecoration(
                hintText: 'ここにKIFを貼り付けてください',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final kif = controller.text.trim();
                if (kif.isEmpty) return;
                final ok = gameState.importKif(kif);
                if (ok) {
                  _selectedDropPieceType = null;
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('KIFの読み込みに失敗しました')),
                  );
                }
              },
              child: const Text('読み込み'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMoveHints(
    BuildContext context,
    ShogiGameState state,
  ) async {
    const maxHints = 60;
    final allMoves = _collectHintMoves(state);
    final displayMoves =
        allMoves.length > maxHints ? allMoves.sublist(0, maxHints) : allMoves;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '合法手のヒント',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text('全${allMoves.length}手 / 表示${displayMoves.length}手'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 360,
                  child: ListView.separated(
                    itemCount: displayMoves.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final hint = displayMoves[index];
                      return ListTile(
                        dense: true,
                        title: Text(hint.label),
                        trailing: hint.tag == null
                            ? null
                            : Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  hint.tag!,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<_HintMove> _collectHintMoves(ShogiGameState state) {
    final moves = <_HintMove>[];
    final isBlack = state.isBlackTurn;

    final legalMoves =
        LegalMoveValidator.getAllLegalMoves(state.board, isBlack);
    for (final move in legalMoves) {
      final piece = state.board.getPiece(move.from.row, move.from.col);
      final name = _pieceDisplay(piece);
      final from = _formatPosition(move.from.row, move.from.col);
      final to = _formatPosition(move.to.row, move.to.col);
      moves.add(_HintMove(
        '$name $from → $to',
        move.canPromote ? '成可' : null,
      ));
    }

    const dropOrder = [
      PieceType.pawn,
      PieceType.lance,
      PieceType.knight,
      PieceType.silver,
      PieceType.gold,
      PieceType.bishop,
      PieceType.rook,
    ];

    for (final type in dropOrder) {
      if (state.capturedPieces.getCount(type, isBlack) <= 0) continue;
      for (int row = 0; row < 9; row++) {
        for (int col = 0; col < 9; col++) {
          if (DropMoveValidator.canDropPiece(
            state.board,
            row,
            col,
            type,
            isBlack,
            state.capturedPieces,
          )) {
            final to = _formatPosition(row, col);
            moves.add(_HintMove('打:${_pieceName(type)} $to', null));
          }
        }
      }
    }

    return moves;
  }

  String _formatPosition(int row, int col) {
    const cols = ['9', '8', '7', '6', '5', '4', '3', '2', '1'];
    const rows = ['一', '二', '三', '四', '五', '六', '七', '八', '九'];
    return '${cols[col]}${rows[row]}';
  }

  String _pieceDisplay(Piece piece) {
    return piece.toDisplayString().replaceAll('▲', '');
  }

  String _pieceName(PieceType type) {
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

  Widget _buildKifControls(ShogiGameState gameState) {
    final canPrev = gameState.currentPly > 0;
    final canNext = gameState.currentPly < gameState.totalPly;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: canPrev ? () => gameState.goToPly(0) : null,
            icon: const Icon(Icons.first_page),
            tooltip: '最初へ',
          ),
          IconButton(
            onPressed: canPrev ? gameState.stepBack : null,
            icon: const Icon(Icons.chevron_left),
            tooltip: '1手戻す',
          ),
          Text('${gameState.currentPly}/${gameState.totalPly}'),
          IconButton(
            onPressed: canNext ? gameState.stepForward : null,
            icon: const Icon(Icons.chevron_right),
            tooltip: '1手進む',
          ),
          IconButton(
            onPressed:
                canNext ? () => gameState.goToPly(gameState.totalPly) : null,
            icon: const Icon(Icons.last_page),
            tooltip: '最後へ',
          ),
        ],
      ),
    );
  }
}

class _HintMove {
  final String label;
  final String? tag;

  const _HintMove(this.label, this.tag);
}
