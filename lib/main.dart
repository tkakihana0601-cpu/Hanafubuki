import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/instructor_list_screen.dart';
import 'screens/match_lobby_screen.dart';
import 'screens/my_page_screen.dart';
import 'screens/launch_screen.dart';
import 'services/auth_service.dart';
import 'services/app_navigation_state.dart';
import 'services/payment_service.dart';
import 'services/reservation_service.dart';
import 'services/instructor_service.dart';
import 'services/notification_service.dart';
import 'services/favorite_instructor_service.dart';
import 'services/kif_library_service.dart';
import 'services/board_theme_service.dart';
import 'services/match_log_service.dart';
import 'services/fair_play_service.dart';
import 'models/piece.dart';

class Move {
  final String from;
  final String to;
  final String piece;
  final DateTime timestamp;
  final bool isBlack;
  final bool isCheck;

  Move({
    required this.from,
    required this.to,
    required this.piece,
    required this.timestamp,
    required this.isBlack,
    required this.isCheck,
  });

  Map<String, dynamic> toJson() => {
        'from': from,
        'to': to,
        'piece': piece,
        'timestamp': timestamp.toIso8601String(),
        'isBlack': isBlack,
        'isCheck': isCheck,
      };

  factory Move.fromJson(Map<String, dynamic> json) => Move(
        from: json['from'],
        to: json['to'],
        piece: json['piece'],
        timestamp: DateTime.parse(json['timestamp']),
        isBlack: json['isBlack'] ?? false,
        isCheck: json['isCheck'] ?? false,
      );
}

class Board {
  late List<List<Piece>> squares;

  Board() {
    squares = List.generate(9, (i) => List.generate(9, (j) => Piece.empty));
    _initializeBoard();
  }

  Board.empty() {
    squares = List.generate(9, (i) => List.generate(9, (j) => Piece.empty));
  }

  Board.copy(Board other) {
    squares = List.generate(
      9,
      (i) => List.generate(
        9,
        (j) => other.squares[i][j],
      ),
    );
  }

  void _initializeBoard() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        squares[i][j] = Piece.empty;
      }
    }

    // 後手（上側）の駒を配置
    squares[0][0] = const Piece(type: PieceType.lance, isBlack: false);
    squares[0][1] = const Piece(type: PieceType.knight, isBlack: false);
    squares[0][2] = const Piece(type: PieceType.silver, isBlack: false);
    squares[0][3] = const Piece(type: PieceType.gold, isBlack: false);
    squares[0][4] = const Piece(type: PieceType.king, isBlack: false);
    squares[0][5] = const Piece(type: PieceType.gold, isBlack: false);
    squares[0][6] = const Piece(type: PieceType.silver, isBlack: false);
    squares[0][7] = const Piece(type: PieceType.knight, isBlack: false);
    squares[0][8] = const Piece(type: PieceType.lance, isBlack: false);

    squares[1][1] = const Piece(type: PieceType.rook, isBlack: false);
    squares[1][7] = const Piece(type: PieceType.bishop, isBlack: false);

    for (int j = 0; j < 9; j++) {
      squares[2][j] = const Piece(type: PieceType.pawn, isBlack: false);
    }

    // 先手（下側）の駒を配置
    squares[8][0] = const Piece(type: PieceType.lance, isBlack: true);
    squares[8][1] = const Piece(type: PieceType.knight, isBlack: true);
    squares[8][2] = const Piece(type: PieceType.silver, isBlack: true);
    squares[8][3] = const Piece(type: PieceType.gold, isBlack: true);
    squares[8][4] = const Piece(type: PieceType.king, isBlack: true);
    squares[8][5] = const Piece(type: PieceType.gold, isBlack: true);
    squares[8][6] = const Piece(type: PieceType.silver, isBlack: true);
    squares[8][7] = const Piece(type: PieceType.knight, isBlack: true);
    squares[8][8] = const Piece(type: PieceType.lance, isBlack: true);

    squares[7][1] = const Piece(type: PieceType.bishop, isBlack: true);
    squares[7][7] = const Piece(type: PieceType.rook, isBlack: true);

    for (int j = 0; j < 9; j++) {
      squares[6][j] = const Piece(type: PieceType.pawn, isBlack: true);
    }
  }

  bool movePiece(int fromRow, int fromCol, int toRow, int toCol) {
    if (!_isValidPosition(fromRow, fromCol) ||
        !_isValidPosition(toRow, toCol)) {
      return false;
    }

    final piece = squares[fromRow][fromCol];
    if (piece.type == PieceType.empty) return false;

    squares[toRow][toCol] = piece;
    squares[fromRow][fromCol] = Piece.empty;
    return true;
  }

  Board copyWith() => Board.copy(this);

  bool _isValidPosition(int row, int col) {
    return row >= 0 && row < 9 && col >= 0 && col < 9;
  }

  Piece getPiece(int row, int col) {
    if (!_isValidPosition(row, col)) return Piece.empty;
    return squares[row][col];
  }

  void applyMove(Move move) {
    final toPos = _parsePosition(move.to);
    if (toPos == null) return;

    if (move.from == '打') {
      final type = _pieceTypeFromDisplay(move.piece);
      if (type == PieceType.empty) return;
      squares[toPos.$1][toPos.$2] = Piece(type: type, isBlack: move.isBlack);
      return;
    }

    final fromPos = _parsePosition(move.from);
    if (fromPos == null) return;
    final movingPiece = squares[fromPos.$1][fromPos.$2];
    if (movingPiece.type == PieceType.empty) {
      final type = _pieceTypeFromDisplay(move.piece);
      if (type == PieceType.empty) return;
      squares[fromPos.$1][fromPos.$2] =
          Piece(type: type, isBlack: move.isBlack);
    }
    squares[toPos.$1][toPos.$2] = squares[fromPos.$1][fromPos.$2];
    squares[fromPos.$1][fromPos.$2] = Piece.empty;
  }

  (int, int)? _parsePosition(String position) {
    if (position.length < 2) return null;
    final colChar = position[0];
    final rowChar = position[1];
    const cols = ['9', '8', '7', '6', '5', '4', '3', '2', '1'];
    const rows = ['一', '二', '三', '四', '五', '六', '七', '八', '九'];
    final col = cols.indexOf(colChar);
    final row = rows.indexOf(rowChar);
    if (col == -1 || row == -1) return null;
    return (row, col);
  }

  PieceType _pieceTypeFromDisplay(String display) {
    final cleaned = display.replaceAll('▲', '');
    return switch (cleaned) {
      '歩' => PieceType.pawn,
      '香' => PieceType.lance,
      '桂' => PieceType.knight,
      '銀' => PieceType.silver,
      '金' => PieceType.gold,
      '角' => PieceType.bishop,
      '飛' => PieceType.rook,
      '玉' => PieceType.king,
      '王' => PieceType.king,
      'と' => PieceType.promotedPawn,
      '成香' => PieceType.promotedLance,
      '成桂' => PieceType.promotedKnight,
      '成銀' => PieceType.promotedSilver,
      '馬' => PieceType.horse,
      '龍' => PieceType.dragon,
      '竜' => PieceType.dragon,
      '成' => PieceType.promotedSilver,
      _ => PieceType.empty,
    };
  }
}

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => AppNavigationState()),
        ChangeNotifierProvider(create: (_) => PaymentService()),
        ChangeNotifierProvider(create: (_) => ReservationService()),
        ChangeNotifierProvider(create: (_) => InstructorService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
        ChangeNotifierProvider(create: (_) => FavoriteInstructorService()),
        ChangeNotifierProvider(create: (_) => KifLibraryService()),
        ChangeNotifierProvider(create: (_) => BoardThemeService()),
        ChangeNotifierProvider(create: (_) => MatchLogService()),
        ChangeNotifierProvider(create: (_) => FairPlayService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '87（はちなな）将棋',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      routes: {
        '/splash': (_) => const LaunchScreen(),
        '/home': (_) => const MainAppScreen(),
        '/auth': (_) => const AuthScreen(),
      },
      home: const LaunchScreen(),
    );
  }
}

class MainAppScreen extends StatelessWidget {
  const MainAppScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<AppNavigationState>(
      builder: (context, navigationState, _) {
        return Scaffold(
          body: _buildBody(navigationState.currentIndex),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: navigationState.currentIndex,
            onTap: (index) {
              navigationState.setIndex(index);
            },
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.deepPurple,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'ホーム',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today),
                label: '予約',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.games),
                label: '対局',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'マイページ',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const InstructorListScreen();
      case 2:
        return const MatchLobbyScreen();
      case 3:
        return const MyPageScreen();
      default:
        return const HomeScreen();
    }
  }
}
