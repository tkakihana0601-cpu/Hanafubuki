import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/piece.dart';
import '../main.dart';
import '../services/match_view_model.dart';
import '../services/shogi_game_state.dart';
import '../services/shogi_game_validator.dart';
import '../services/legal_move_validator.dart';
import '../services/drop_move_validator.dart';
import '../services/auth_service.dart';
import '../services/call_service.dart';
import '../services/board_theme_service.dart';
import '../services/match_log_service.dart';
import '../services/fair_play_service.dart';
import '../models/call_session.dart';
import '../models/match_log.dart';
import 'board_widget.dart';

class MatchScreen extends StatefulWidget {
  final MatchViewModel viewModel;
  final bool isSentePlayer;
  final bool enableLocalMoves;

  const MatchScreen({
    super.key,
    required this.viewModel,
    this.isSentePlayer = true,
    this.enableLocalMoves = false,
  });

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  static final Map<String, List<_ChatMessage>> _chatStore = {};
  static final Map<String, Set<String>> _spectatorStore = {};
  static final Map<String, String> _callRoomStore = {};

  Timer? _timer;
  int _senteSeconds = 10 * 60;
  int _goteSeconds = 10 * 60;
  bool _timerPaused = false;
  bool _isSpectating = true;
  late final ShogiGameState _localState;
  bool _hasShownResult = false;
  PieceType? _selectedDropPieceType;
  final CallService _callService = CallService();
  CallSession? _callSession;
  bool _isInCall = false;
  bool _isJoiningCall = false;
  bool _micEnabled = true;
  bool _speakerEnabled = true;
  bool _analysisMode = false;
  bool _instructorOnlyMode = false;
  late final ShogiGameState _analysisState;
  MatchLogService? _matchLogService;
  bool _logInitialized = false;
  int _loggedLocalMoves = 0;
  int _loggedRemoteMoves = 0;
  DateTime? _lastSenteMoveTime;
  DateTime? _lastGoteMoveTime;
  bool _suppressLocalLog = false;

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  late final List<_ChatMessage> _messages;
  late List<String> _spectators;

  MatchViewModel get viewModel => widget.viewModel;

  ShogiGameState get _activeLocalState => _localState;

  @override
  void initState() {
    super.initState();
    _localState = ShogiGameState();
    _analysisState = ShogiGameState();
    if (!widget.enableLocalMoves) {
      viewModel.init();
    }
    _initChat();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timerPaused) return;
      final isSenteTurn = widget.enableLocalMoves
          ? (_localState.isBlackTurn)
          : viewModel.moves.length.isEven;
      if (widget.enableLocalMoves && _localState.isGameOver()) {
        _timerPaused = true;
        _showGameResultDialog();
        return;
      }
      setState(() {
        if (isSenteTurn && _senteSeconds > 0) {
          _senteSeconds--;
        } else if (!isSenteTurn && _goteSeconds > 0) {
          _goteSeconds--;
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_logInitialized) return;
    _matchLogService = context.read<MatchLogService>();
    final currentUserId = _getCurrentUserId();
    _matchLogService?.ensureLog(
      matchId: viewModel.matchId,
      startedAt: DateTime.now(),
      senteUserId: widget.isSentePlayer ? currentUserId : null,
      goteUserId: widget.isSentePlayer ? null : currentUserId,
    );
    viewModel.addListener(_handleRemoteMovesChanged);
    _localState.addListener(_handleLocalMovesChanged);
    _logInitialized = true;
    _handleRemoteMovesChanged();
    _handleLocalMovesChanged();
  }

  void _initChat() {
    final matchId = widget.viewModel.matchId;
    _messages = _chatStore.putIfAbsent(matchId, () => []);
    final spectators = _spectatorStore.putIfAbsent(matchId, () => <String>{});
    final currentName = _getCurrentUserName();
    spectators.add(currentName);
    _spectators = spectators.toList();
  }

  String _getCurrentUserName() {
    final user = context.read<AuthService>().currentUser;
    if (user != null && user.name.isNotEmpty) {
      return user.name;
    }
    return widget.isSentePlayer ? '先手' : '後手';
  }

  String _getCurrentUserId() {
    final user = context.read<AuthService>().currentUser;
    return user?.id ?? (widget.isSentePlayer ? 'user_sente' : 'user_gote');
  }

  bool _isInstructor() {
    final user = context.read<AuthService>().currentUser;
    return user?.isInstructor ?? false;
  }

  bool _canOperateAnalysis() {
    return !_instructorOnlyMode || _isInstructor();
  }

  bool _isPlayerTurn(ShogiGameState state) {
    return state.isBlackTurn == widget.isSentePlayer;
  }

  @override
  void dispose() {
    _timer?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    viewModel.removeListener(_handleRemoteMovesChanged);
    _localState.removeListener(_handleLocalMovesChanged);
    _localState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('マッチ'),
          backgroundColor: Colors.brown.shade700,
          actions: [
            IconButton(
              onPressed: () => _showFairPlayDialog(context),
              icon: const Icon(Icons.shield),
              tooltip: 'フェアプレイ分析',
            ),
            IconButton(
              onPressed: () => _showReportDialog(context),
              icon: const Icon(Icons.report),
              tooltip: '通報',
            ),
            IconButton(
              onPressed: () => _showBoardThemeSheet(context),
              icon: const Icon(Icons.palette),
              tooltip: '盤面カスタマイズ',
            ),
            IconButton(
              onPressed: () => _showMoveHints(
                context,
                _analysisMode ? _analysisState : _activeLocalState,
              ),
              icon: const Icon(Icons.lightbulb),
              tooltip: 'ヒント',
            ),
            IconButton(
              onPressed: _showCallSheet,
              icon: Icon(_isInCall ? Icons.call_end : Icons.call),
              tooltip: _isInCall ? '通話を終了' : '通話を開始',
            ),
            if (widget.enableLocalMoves)
              IconButton(
                onPressed: () => _showKifImportDialog(
                  context,
                  _localState,
                ),
                icon: const Icon(Icons.upload_file),
                tooltip: 'KIF入力',
              ),
            IconButton(
              onPressed: () {
                setState(() => _timerPaused = !_timerPaused);
                _showSnackBar(context, _timerPaused ? 'タイマー停止' : 'タイマー再開');
              },
              icon: Icon(_timerPaused ? Icons.play_arrow : Icons.pause),
            ),
            IconButton(
              onPressed: () {
                _showSnackBar(context, '再接続しました');
              },
              icon: const Icon(Icons.sync),
            ),
          ],
        ),
        body: AnimatedBuilder(
          animation: Listenable.merge([
            viewModel,
            if (widget.enableLocalMoves) _localState,
            _analysisState,
          ]),
          builder: (context, _) {
            final localState = _activeLocalState;
            final analysisState = _analysisMode ? _analysisState : null;
            final themeService = context.watch<BoardThemeService>();
            final themeData = themeService.themeData;
            final autoFlip = themeService.settings.autoFlip;
            final isPlayerBlack = widget.isSentePlayer;
            final isBlackTurn =
                analysisState?.isBlackTurn ?? localState.isBlackTurn;
            final isPlayerTurn = isBlackTurn == isPlayerBlack;
            final flipBoard = autoFlip ? !isPlayerBlack : false;
            final topPieces = isPlayerBlack
                ? _activeLocalState.capturedPieces.whiteCapturedPieces
                : _activeLocalState.capturedPieces.blackCapturedPieces;
            final bottomPieces = isPlayerBlack
                ? _activeLocalState.capturedPieces.blackCapturedPieces
                : _activeLocalState.capturedPieces.whiteCapturedPieces;
            const capturedRowHeight = 52.0;
            return Column(
              children: [
                _buildMatchHeader(context),
                _buildAnalysisControls(context, _analysisState),
                if (analysisState == null)
                  SizedBox(
                    height: capturedRowHeight,
                    child: _buildCapturedRow(
                      label: isPlayerBlack ? '後手の持ち駒' : '先手の持ち駒',
                      pieces: topPieces,
                      isSelectable: false,
                      themeData: themeData,
                      flipBoard: flipBoard,
                      ownerIsBlack: !isPlayerBlack,
                    ),
                  ),
                Expanded(
                  flex: 6,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: BoardWidget(
                        board: analysisState?.board ?? localState.board,
                        selectedRow: analysisState?.selectedRow ??
                            localState.selectedRow,
                        selectedCol: analysisState?.selectedCol ??
                            localState.selectedCol,
                        possibleMoves: analysisState?.possibleMoves ??
                            localState.possibleMoves,
                        onMovePiece: analysisState != null
                            ? (_canOperateAnalysis()
                                ? (row, col, _, __) async {
                                    await _handleAnalysisBoardTap(
                                      analysisState,
                                      row,
                                      col,
                                    );
                                  }
                                : null)
                            : (row, col, _, __) async {
                                await _handleLocalBoardTap(
                                  context,
                                  localState,
                                  row,
                                  col,
                                );
                              },
                        flipBoard: flipBoard,
                        themeData: themeData,
                      ),
                    ),
                  ),
                ),
                if (analysisState == null)
                  SizedBox(
                    height: capturedRowHeight,
                    child: _buildCapturedRow(
                      label: isPlayerBlack ? '先手の持ち駒' : '後手の持ち駒',
                      pieces: bottomPieces,
                      isSelectable: isPlayerTurn,
                      themeData: themeData,
                      flipBoard: flipBoard,
                      ownerIsBlack: isPlayerBlack,
                    ),
                  ),
                _buildActionRow(context),
                const TabBar(
                  labelColor: Colors.brown,
                  tabs: [
                    Tab(text: '手数'),
                    Tab(text: 'チャット'),
                    Tab(text: '観戦'),
                  ],
                ),
                Expanded(
                  flex: 4,
                  child: TabBarView(
                    children: [
                      _buildMoveList(),
                      _buildChatTab(),
                      _buildSpectatorTab(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMatchHeader(BuildContext context) {
    final localState = _activeLocalState;
    final turnText = localState.isBlackTurn ? '先手' : '後手';
    final moveCount = localState.moveCount;
    final log = context.watch<MatchLogService>().getLog(viewModel.matchId);
    final analysis =
        log == null ? null : context.read<FairPlayService>().analyze(log);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.brown.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'マッチID: ${viewModel.matchId}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
          if (_callSession != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  _isInCall ? Icons.call : Icons.call_missed,
                  size: 14,
                  color: _isInCall ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '通話ID: ${_callSession!.meetingId}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPlayerChip(label: '先手', isActive: turnText == '先手'),
              const SizedBox(width: 8),
              _buildPlayerChip(label: '後手', isActive: turnText == '後手'),
              const SizedBox(width: 8),
              Chip(
                label: Text('あなた: ${widget.isSentePlayer ? '先手' : '後手'}'),
                backgroundColor: Colors.brown.shade100,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '手数: $moveCount',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildTimerChip('先手', _senteSeconds),
              const SizedBox(width: 8),
              _buildTimerChip('後手', _goteSeconds),
              const Spacer(),
              FilterChip(
                label: const Text('観戦モード'),
                selected: _isSpectating,
                onSelected: (value) {
                  setState(() => _isSpectating = value);
                },
              ),
            ],
          ),
          if (analysis != null && analysis.hasAlert) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                'フェアプレイ警告: ${analysis.flags.join(' / ')}',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
          if (_isInCall) ...[
            const SizedBox(height: 8),
            _buildCallControls(),
          ],
        ],
      ),
    );
  }

  void _showGameResultDialog() {
    if (_hasShownResult || !mounted) return;
    _hasShownResult = true;

    final message = _activeLocalState.gameMessage;
    if (message.isEmpty) return;

    final result = message.contains('先手勝利')
        ? 'sente'
        : message.contains('後手勝利')
            ? 'gote'
            : message.contains('引き分け')
                ? 'draw'
                : 'unknown';
    _matchLogService?.setResult(
      viewModel.matchId,
      MatchResult(result: result, message: message),
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('対局結果'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _handleLocalMovesChanged() {
    if (!_logInitialized) return;
    if (_suppressLocalLog) {
      _loggedLocalMoves = _localState.moveHistory.length;
      return;
    }
    final moves = _localState.moveHistory;
    if (moves.length <= _loggedLocalMoves) return;
    for (int i = _loggedLocalMoves; i < moves.length; i++) {
      final move = moves[i];
      _logMove(move);
    }
    _loggedLocalMoves = moves.length;
  }

  void _handleRemoteMovesChanged() {
    if (!_logInitialized) return;
    final moves = viewModel.moves;
    if (moves.length <= _loggedRemoteMoves) return;
    for (int i = _loggedRemoteMoves; i < moves.length; i++) {
      final move = moves[i];
      if (!widget.enableLocalMoves) {
        if (_localState.moveHistory.length > i &&
            _isSameMove(_localState.moveHistory[i], move)) {
          // すでにローカルで反映済み
        } else {
          _suppressLocalLog = true;
          _localState.applyExternalMove(move);
          _suppressLocalLog = false;
        }
      }
      _logMove(move);
    }
    _loggedRemoteMoves = moves.length;
  }

  bool _isSameMove(Move a, Move b) {
    return a.from == b.from &&
        a.to == b.to &&
        a.piece == b.piece &&
        a.isBlack == b.isBlack;
  }

  void _logMove(dynamic move) {
    final isBlack = move.isBlack as bool;
    final timestamp = move.timestamp as DateTime;
    final lastTime = isBlack ? _lastSenteMoveTime : _lastGoteMoveTime;
    final spent = lastTime == null ? null : timestamp.difference(lastTime);
    if (isBlack) {
      _lastSenteMoveTime = timestamp;
    } else {
      _lastGoteMoveTime = timestamp;
    }
    _matchLogService?.addMove(
      viewModel.matchId,
      MatchMoveLog(
        from: move.from as String,
        to: move.to as String,
        piece: move.piece as String,
        isBlack: isBlack,
        isCheck: move.isCheck as bool,
        timestamp: timestamp,
        timeSpent: spent,
      ),
    );
  }

  Widget _buildCapturedRow({
    required String label,
    required Map<PieceType, int> pieces,
    required bool isSelectable,
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
      color: Colors.brown.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Future<void> _handleLocalBoardTap(
    BuildContext context,
    ShogiGameState localState,
    int row,
    int col,
  ) async {
    if (!widget.enableLocalMoves && !_isPlayerTurn(localState)) {
      _showSnackBar(context, '相手の手番です');
      return;
    }
    if (_selectedDropPieceType != null) {
      final dropped = localState.dropPiece(_selectedDropPieceType!, row, col);
      if (mounted && dropped) {
        setState(() => _selectedDropPieceType = null);
      }
      if (dropped) {
        _sendMoveIfNeeded(localState);
      }
      return;
    }

    final selectedRow = localState.selectedRow;
    final selectedCol = localState.selectedCol;

    if (selectedRow != null && selectedCol != null) {
      final isPossibleMove =
          localState.possibleMoves.any((p) => p.row == row && p.col == col);

      if (isPossibleMove) {
        final mustPromote = ShogiGameValidator.isMustPromote(
          localState.board,
          selectedRow,
          selectedCol,
          row,
          localState.isBlackTurn,
        );

        final canPromote = ShogiGameValidator.canPromote(
          localState.board,
          selectedRow,
          selectedCol,
          row,
          localState.isBlackTurn,
        );

        if (mustPromote) {
          localState.movePiece(selectedRow, selectedCol, row, col,
              shouldPromote: true);
          _sendMoveIfNeeded(localState);
          return;
        }

        if (canPromote) {
          final shouldPromote = await _showPromotionDialog(context);
          localState.movePiece(selectedRow, selectedCol, row, col,
              shouldPromote: shouldPromote ?? false);
          _sendMoveIfNeeded(localState);
          return;
        }
      }
    }

    localState.selectPiece(row, col);
  }

  void _sendMoveIfNeeded(ShogiGameState localState) {
    if (widget.enableLocalMoves) return;
    if (localState.moveHistory.isEmpty) return;
    final move = localState.moveHistory.last;
    viewModel.sendMove(move);
  }

  Future<void> _handleAnalysisBoardTap(
    ShogiGameState analysisState,
    int row,
    int col,
  ) async {
    analysisState.selectPiece(row, col);
  }

  Widget _buildAnalysisControls(
    BuildContext context,
    ShogiGameState analysisState,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.brown.shade50,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('検討モード'),
                  subtitle: const Text('実局に影響しない検討盤面'),
                  value: _analysisMode,
                  onChanged: (value) {
                    setState(() {
                      _analysisMode = value;
                      _selectedDropPieceType = null;
                      if (_analysisMode) {
                        _analysisState.loadFromBoard(_activeLocalState.board);
                        _analysisState.setAnalysisMode(true);
                      } else {
                        _analysisState.setAnalysisMode(false);
                      }
                    });
                  },
                ),
              ),
              if (_isInstructor())
                Switch(
                  value: _instructorOnlyMode,
                  onChanged: (value) {
                    setState(() => _instructorOnlyMode = value);
                  },
                ),
            ],
          ),
          if (_isInstructor())
            Text(
              _instructorOnlyMode ? '指導者のみ操作' : '全員操作可能',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          const SizedBox(height: 6),
          if (_analysisMode)
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    final line = analysisState.saveVariation();
                    _showSnackBar(context, '${line.name} を保存しました');
                  },
                  icon: const Icon(Icons.bookmark_add),
                  label: const Text('変化保存'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _showVariationSheet(context, analysisState),
                  icon: const Icon(Icons.list_alt),
                  label: const Text('変化一覧'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    analysisState.loadFromBoard(_activeLocalState.board);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('本局へ戻す'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showVariationSheet(
    BuildContext context,
    ShogiGameState analysisState,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '保存した変化',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (analysisState.variations.isEmpty)
                const Text('保存された変化はありません')
              else
                ...analysisState.variations.map((v) {
                  return ListTile(
                    title: Text(v.name),
                    subtitle: Text('手数: ${v.moves.length}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        analysisState.deleteVariation(v.id);
                        Navigator.of(context).pop();
                      },
                    ),
                    onTap: () {
                      analysisState.loadVariation(v.id);
                      Navigator.of(context).pop();
                    },
                  );
                }).toList(),
            ],
          ),
        );
      },
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

  Widget _buildTimerChip(String label, int seconds) {
    return Chip(
      label: Text('$label ${_formatTimer(seconds)}'),
      backgroundColor: Colors.brown.shade100,
      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPlayerChip({required String label, required bool isActive}) {
    return Chip(
      label: Text(label),
      backgroundColor: isActive ? Colors.orange.shade200 : Colors.grey.shade200,
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: isActive ? Colors.brown.shade700 : Colors.grey.shade700,
      ),
    );
  }

  Widget _buildCallControls() {
    return Row(
      children: [
        FilterChip(
          label: const Text('マイク'),
          selected: _micEnabled,
          onSelected: (value) {
            setState(() => _micEnabled = value);
          },
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: const Text('スピーカー'),
          selected: _speakerEnabled,
          onSelected: (value) {
            setState(() => _speakerEnabled = value);
          },
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: _leaveCall,
          icon: const Icon(Icons.call_end, color: Colors.red),
          label: const Text(
            '通話終了',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _showSnackBar(context, '引き分けを提案しました');
              },
              icon: const Icon(Icons.handshake),
              label: const Text('引き分け'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () {
                _handleResign(context);
              },
              icon: const Icon(Icons.flag),
              label: const Text('投了'),
            ),
          ),
        ],
      ),
    );
  }

  void _handleResign(BuildContext context) {
    _showSnackBar(context, '投了しました');
    if (!widget.enableLocalMoves) return;

    _timerPaused = true;
    if (_hasShownResult) return;
    _hasShownResult = true;

    final winnerIsBlack = !widget.isSentePlayer;
    final message = winnerIsBlack ? '先手勝利・後手敗北' : '後手勝利・先手敗北';

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('対局結果'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMoveList() {
    final localState = _activeLocalState;
    final moves = localState.moveHistory;
    if (moves.isEmpty) {
      return const Center(
        child: Text('まだ指し手がありません'),
      );
    }

    return Column(
      children: [
        if (localState.hasKif) _buildKifControls(localState),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: moves.length,
            separatorBuilder: (_, __) => const Divider(height: 16),
            itemBuilder: (context, index) {
              final m = moves[index];
              final turn = index.isEven ? '先手' : '後手';
              final isActive =
                  localState.hasKif && localState.currentPly == index + 1;
              return InkWell(
                onTap: localState.hasKif
                    ? () => localState.goToPly(index + 1)
                    : null,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.brown.shade200,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$turn: ${m.piece}',
                            style: TextStyle(
                              fontWeight: isActive
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${m.from} → ${m.to}'),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _chatScrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final msg = _messages[index];
              return Align(
                alignment:
                    msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: msg.isMine
                        ? Colors.brown.shade200
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: msg.isMine
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        msg.sender,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(msg.message),
                      const SizedBox(height: 4),
                      Text(
                        _formatChatTime(msg.time),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      hintText: 'メッセージを入力',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpectatorTab() {
    if (_spectators.isEmpty) {
      return const Center(child: Text('観戦者はいません'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _spectators.length,
      separatorBuilder: (_, __) => const Divider(height: 12),
      itemBuilder: (context, index) {
        final name = _spectators[index];
        return Row(
          children: [
            const CircleAvatar(
              radius: 16,
              child: Icon(Icons.person, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name)),
            if (_isSpectating && index == 0)
              Chip(
                label: const Text('あなた'),
                backgroundColor: Colors.blue.shade100,
              ),
          ],
        );
      },
    );
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    final sender = _getCurrentUserName();
    final senderId = _getCurrentUserId();
    final timestamp = DateTime.now();
    setState(() {
      _messages.add(
        _ChatMessage(
          sender: sender,
          message: text,
          time: timestamp,
          isMine: true,
        ),
      );
      final spectators = _spectatorStore[widget.viewModel.matchId];
      if (spectators != null && !spectators.contains(sender)) {
        spectators.add(sender);
        _spectators = spectators.toList();
      }
      _chatController.clear();
    });
    _matchLogService?.addChat(
      viewModel.matchId,
      ChatLogEntry(
        senderId: senderId,
        senderName: sender,
        message: text,
        timestamp: timestamp,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.jumpTo(
          _chatScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  Future<void> _showCallSheet() async {
    if (_isInCall) {
      _leaveCall();
      return;
    }

    final storedMeetingId = _callRoomStore[viewModel.matchId];
    final controller = TextEditingController(text: storedMeetingId ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '対局通話',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '通話ID（未入力なら新規作成）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isJoiningCall
                          ? null
                          : () async {
                              Navigator.of(context).pop();
                              await _createCall();
                            },
                      child: const Text('新規作成'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isJoiningCall
                          ? null
                          : () async {
                              final meetingId = controller.text.trim();
                              Navigator.of(context).pop();
                              await _joinCall(meetingId);
                            },
                      child: _isJoiningCall
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('参加'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _createCall() async {
    if (_isJoiningCall) return;
    setState(() => _isJoiningCall = true);
    try {
      final session = await _callService.createMeeting(
          viewModel.matchId, _getCurrentUserId());
      if (session == null || !mounted) return;
      setState(() {
        _callSession = session;
        _isInCall = true;
        _callRoomStore[viewModel.matchId] = session.meetingId;
      });
      _matchLogService?.addCall(
        viewModel.matchId,
        CallLogEntry(
          meetingId: session.meetingId,
          userId: _getCurrentUserId(),
          event: 'create',
          timestamp: DateTime.now(),
        ),
      );
      _showSnackBar(context, '通話を開始しました');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(context, '通話の開始に失敗しました');
    } finally {
      if (mounted) {
        setState(() => _isJoiningCall = false);
      }
    }
  }

  Future<void> _joinCall(String meetingId) async {
    if (_isJoiningCall) return;
    if (meetingId.isEmpty) {
      _showSnackBar(context, '通話IDを入力してください');
      return;
    }
    setState(() => _isJoiningCall = true);
    try {
      final session =
          await _callService.joinMeeting(meetingId, _getCurrentUserId());
      if (session == null || !mounted) return;
      setState(() {
        _callSession = session;
        _isInCall = true;
        _callRoomStore[viewModel.matchId] = session.meetingId;
      });
      _matchLogService?.addCall(
        viewModel.matchId,
        CallLogEntry(
          meetingId: session.meetingId,
          userId: _getCurrentUserId(),
          event: 'join',
          timestamp: DateTime.now(),
        ),
      );
      _showSnackBar(context, '通話に参加しました');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(context, '通話への参加に失敗しました');
    } finally {
      if (mounted) {
        setState(() => _isJoiningCall = false);
      }
    }
  }

  void _leaveCall() {
    if (_callSession != null) {
      _matchLogService?.addCall(
        viewModel.matchId,
        CallLogEntry(
          meetingId: _callSession!.meetingId,
          userId: _getCurrentUserId(),
          event: 'leave',
          timestamp: DateTime.now(),
        ),
      );
    }
    setState(() {
      _isInCall = false;
      _callSession = null;
      _micEnabled = true;
      _speakerEnabled = true;
    });
    _showSnackBar(context, '通話を終了しました');
  }

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatChatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _showFairPlayDialog(BuildContext context) {
    final log = context.read<MatchLogService>().getLog(viewModel.matchId);
    if (log == null) {
      _showSnackBar(context, '対局ログがありません');
      return;
    }
    final analysis = context.read<FairPlayService>().analyze(log);
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('フェアプレイ分析'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'AI使用疑いスコア: ${analysis.aiSuspicionScore.toStringAsFixed(1)}'),
              const SizedBox(height: 4),
              Text(
                  '時間配分異常スコア: ${analysis.timeAnomalyScore.toStringAsFixed(1)}'),
              const SizedBox(height: 8),
              if (analysis.flags.isEmpty)
                const Text('警告は検出されませんでした')
              else
                Text('警告: ${analysis.flags.join(' / ')}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }

  void _showReportDialog(BuildContext context) {
    const reasons = ['不正の疑い', '迷惑行為', '不適切な発言', 'その他'];
    String selectedReason = reasons.first;
    final detailController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('通報'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                items: reasons
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) selectedReason = value;
                },
                decoration: const InputDecoration(labelText: '理由'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: detailController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: '詳細',
                  border: OutlineInputBorder(),
                ),
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
                final report = context.read<FairPlayService>().addReport(
                      matchId: viewModel.matchId,
                      reporterId: _getCurrentUserId(),
                      reason: selectedReason,
                      detail: detailController.text.trim(),
                    );
                _matchLogService?.addReport(viewModel.matchId, report.id);
                Navigator.of(context).pop();
                _showSnackBar(context, '通報を送信しました');
              },
              child: const Text('送信'),
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildKifControls(ShogiGameState gameState) {
    final canPrev = gameState.currentPly > 0;
    final canNext = gameState.currentPly < gameState.totalPly;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  _timerPaused = true;
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
}

class _ChatMessage {
  final String sender;
  final String message;
  final DateTime time;
  final bool isMine;

  const _ChatMessage({
    required this.sender,
    required this.message,
    required this.time,
    required this.isMine,
  });
}

class _HintMove {
  final String label;
  final String? tag;

  const _HintMove(this.label, this.tag);
}
