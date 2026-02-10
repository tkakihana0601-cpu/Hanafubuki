class FairPlayReport {
  final String id;
  final String matchId;
  final String reporterId;
  final String reason;
  final String detail;
  final DateTime createdAt;

  const FairPlayReport({
    required this.id,
    required this.matchId,
    required this.reporterId,
    required this.reason,
    required this.detail,
    required this.createdAt,
  });
}

class FairPlayAnalysisResult {
  final double aiSuspicionScore;
  final double timeAnomalyScore;
  final List<String> flags;

  const FairPlayAnalysisResult({
    required this.aiSuspicionScore,
    required this.timeAnomalyScore,
    required this.flags,
  });

  bool get hasAlert => flags.isNotEmpty;
}
