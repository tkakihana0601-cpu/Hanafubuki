import 'package:flutter/foundation.dart';
import '../models/fair_play.dart';
import '../models/match_log.dart';

class FairPlayService extends ChangeNotifier {
  final List<FairPlayReport> _reports = [];

  List<FairPlayReport> get reports => List.unmodifiable(_reports);

  FairPlayReport addReport({
    required String matchId,
    required String reporterId,
    required String reason,
    required String detail,
  }) {
    final report = FairPlayReport(
      id: 'report_${DateTime.now().millisecondsSinceEpoch}',
      matchId: matchId,
      reporterId: reporterId,
      reason: reason,
      detail: detail,
      createdAt: DateTime.now(),
    );
    _reports.insert(0, report);
    notifyListeners();
    return report;
  }

  FairPlayAnalysisResult analyze(MatchLog log) {
    if (log.moves.isEmpty) {
      return const FairPlayAnalysisResult(
        aiSuspicionScore: 0,
        timeAnomalyScore: 0,
        flags: [],
      );
    }

    final timeSpentList = log.moves
        .where((m) => m.timeSpent != null)
        .map((m) => m.timeSpent!.inSeconds)
        .toList();

    final avgTime = timeSpentList.isEmpty
        ? 0
        : timeSpentList.reduce((a, b) => a + b) / timeSpentList.length;
    final fastMoves = timeSpentList.where((t) => t <= 3).length;
    final fastRatio =
        timeSpentList.isEmpty ? 0 : fastMoves / timeSpentList.length;

    final checkMoves = log.moves.where((m) => m.isCheck).length;
    final checkRatio = checkMoves / log.moves.length;

    final aiSuspicionScore = (fastRatio * 0.6 + checkRatio * 0.4) * 100;

    double timeAnomalyScore = 0;
    if (timeSpentList.length >= 5) {
      final mean = avgTime;
      final variance = timeSpentList
              .map((t) => (t - mean) * (t - mean))
              .reduce((a, b) => a + b) /
          timeSpentList.length;
      final stdDev = variance.sqrt();
      final uniformityScore = stdDev == 0 ? 1 : (1 / stdDev).clamp(0.0, 1.0);
      timeAnomalyScore = (uniformityScore * 100).clamp(0, 100).toDouble();
    }

    final flags = <String>[];
    if (aiSuspicionScore >= 65 && checkRatio >= 0.3) {
      flags.add('AI使用の疑い');
    }
    if (timeAnomalyScore >= 70 && avgTime <= 5) {
      flags.add('不自然な時間配分');
    }

    return FairPlayAnalysisResult(
      aiSuspicionScore: aiSuspicionScore,
      timeAnomalyScore: timeAnomalyScore,
      flags: flags,
    );
  }
}

extension on double {
  double sqrt() => MathHelper.sqrt(this);
}

class MathHelper {
  static double sqrt(double value) {
    double x = value;
    double y = 1;
    const e = 0.00001;
    while ((x - y).abs() > e) {
      x = (x + y) / 2;
      y = value / x;
    }
    return x;
  }
}
