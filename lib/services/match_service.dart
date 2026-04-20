import 'package:graphql_flutter/graphql_flutter.dart';
import '../main.dart';

class MatchService {
  final GraphQLClient client;

  MatchService(this.client);

  static const String sendMoveMutation = r'''
    mutation SendMove($matchId: ID!, $move: MoveInput!) {
      sendMove(matchId: $matchId, move: $move) {
        from
        to
        piece
        timestamp
      }
    }
  ''';

  static const String onMoveSubscription = r'''
    subscription OnMove($matchId: ID!) {
      onMove(matchId: $matchId) {
        from
        to
        piece
        timestamp
      }
    }
  ''';

  Stream<Move> subscribeMoves(String matchId) {
    final options = SubscriptionOptions(
      document: gql(onMoveSubscription),
      variables: {'matchId': matchId},
    );

    return client.subscribe(options).map((result) {
      final data = result.data?['onMove'];
      return Move.fromJson(Map<String, dynamic>.from(data));
    });
  }

  Future<void> sendMove(String matchId, Move move) async {
    final options = MutationOptions(
      document: gql(sendMoveMutation),
      variables: {
        'matchId': matchId,
        'move': {
          'from': move.from,
          'to': move.to,
          'piece': move.piece,
          'timestamp': move.timestamp.toIso8601String(),
        },
      },
    );
    final result = await client.mutate(options);
    if (result.hasException) {
      throw result.exception!;
    }
  }
}
