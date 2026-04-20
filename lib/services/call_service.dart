import '../models/call_session.dart';

class CallService {
  static final Map<String, CallSession> _meetings = {};

  Future<CallSession?> createMeeting(
    String matchId,
    String userId,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      final callSession = CallSession(
        meetingId: 'meeting_${DateTime.now().millisecondsSinceEpoch}',
        attendeeId: 'attendee_$userId',
        joinToken: 'token_${DateTime.now().millisecondsSinceEpoch}',
      );
      _meetings[callSession.meetingId] = callSession;
      return callSession;
    } catch (e) {
      rethrow;
    }
  }

  Future<CallSession?> joinMeeting(
    String meetingId,
    String userId,
  ) async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      if (_meetings.containsKey(meetingId)) {
        return _meetings[meetingId]!.copyWith(
          attendeeId: 'attendee_$userId',
          joinToken: 'token_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      final callSession = CallSession(
        meetingId: meetingId,
        attendeeId: 'attendee_$userId',
        joinToken: 'token_${DateTime.now().millisecondsSinceEpoch}',
      );
      _meetings[meetingId] = callSession;
      return callSession;
    } catch (e) {
      rethrow;
    }
  }
}
