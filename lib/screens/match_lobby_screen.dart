import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../main.dart';
import '../services/match_service.dart';
import '../services/match_view_model.dart';
import 'match_screen.dart';

class MatchLobbyScreen extends StatefulWidget {
  const MatchLobbyScreen({super.key});

  @override
  State<MatchLobbyScreen> createState() => _MatchLobbyScreenState();
}

class _MatchLobbyScreenState extends State<MatchLobbyScreen> {
  final Map<String, _RoomEntry> _rooms = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('マッチ'),
        elevation: 0,
        backgroundColor: Colors.deepPurple,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '対局',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'フリー対局',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('その場で対局を開始します'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _openFreeMatch(context),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('フリーで対局する'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ルーム対局',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text('ルームを作成・参加して対局します'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _createRoom(context),
                              icon: const Icon(Icons.meeting_room),
                              label: const Text('ルーム作成'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _joinRoom(context),
                              icon: const Icon(Icons.input),
                              label: const Text('ルーム参加'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_rooms.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '作成済みルーム',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ..._rooms.values.map((room) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'ルームID: ${room.roomId}  (${room.senteTaken ? '先手' : ''}${room.goteTaken ? '後手' : ''})',
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () => _joinRoomById(
                                    context,
                                    room.roomId,
                                  ),
                                  child: const Text('参加'),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openFreeMatch(BuildContext context) {
    final isSentePlayer = Random().nextBool();
    final viewModel =
        _createLocalViewModel('free_${DateTime.now().millisecondsSinceEpoch}');
    final label = isSentePlayer ? '先手' : '後手';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('あなたは$labelです')),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchScreen(
          viewModel: viewModel,
          isSentePlayer: isSentePlayer,
          enableLocalMoves: true,
        ),
      ),
    );
  }

  Future<void> _createRoom(BuildContext context) async {
    final roomId = _generateRoomId();
    final viewModel = _createLocalViewModel('room_$roomId');
    setState(() {
      _rooms[roomId] = _RoomEntry(
        roomId: roomId,
        viewModel: viewModel,
        senteTaken: true,
        goteTaken: false,
      );
    });

    _showRoomCreatedDialog(context, roomId, isSentePlayer: true);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchScreen(
          viewModel: viewModel,
          isSentePlayer: true,
          enableLocalMoves: true,
        ),
      ),
    );
  }

  Future<void> _joinRoom(BuildContext context) async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ルーム参加'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'ルームID',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final id = controller.text.trim().toUpperCase();
                if (id.isEmpty) return;
                Navigator.of(context).pop();
                _joinRoomById(context, id);
              },
              child: const Text('参加'),
            ),
          ],
        );
      },
    );
  }

  void _joinRoomById(BuildContext context, String roomId) {
    final room = _rooms[roomId];
    if (room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ルームが見つかりません')),
      );
      return;
    }

    if (room.goteTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ルームは満員です')),
      );
      return;
    }

    setState(() {
      room.goteTaken = true;
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MatchScreen(
          viewModel: room.viewModel,
          isSentePlayer: false,
          enableLocalMoves: true,
        ),
      ),
    );
  }

  void _showRoomCreatedDialog(
    BuildContext context,
    String roomId, {
    required bool isSentePlayer,
  }) {
    final label = isSentePlayer ? '先手' : '後手';
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ルーム作成完了'),
          content: Text('ルームID: $roomId\nあなたは$labelです。'),
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

  MatchViewModel _createLocalViewModel(String matchId) {
    final client = GraphQLClient(
      link: HttpLink('http://localhost'),
      cache: GraphQLCache(),
    );
    return MatchViewModel(
      matchService: MatchService(client),
      matchId: matchId,
      board: Board(),
    );
  }

  String _generateRoomId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }
}

class _RoomEntry {
  final String roomId;
  final MatchViewModel viewModel;
  bool senteTaken;
  bool goteTaken;

  _RoomEntry({
    required this.roomId,
    required this.viewModel,
    required this.senteTaken,
    required this.goteTaken,
  });
}
