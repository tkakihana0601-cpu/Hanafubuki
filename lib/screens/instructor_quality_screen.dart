import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/instructor_service.dart';
import '../services/reservation_service.dart';
import '../models/instructor.dart';
import '../models/review.dart';

class InstructorQualityScreen extends StatelessWidget {
  const InstructorQualityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final instructors = context.watch<InstructorService>().instructors;
    final reservations = context.watch<ReservationService>().reservations;

    final rows = instructors.map((instructor) {
      final instructorReservations =
          reservations.where((r) => r.instructorId == instructor.id).toList();
      final sessionCount = instructorReservations.length;
      final userCounts = <String, int>{};
      for (final r in instructorReservations) {
        userCounts[r.userId] = (userCounts[r.userId] ?? 0) + 1;
      }
      final repeatUsers = userCounts.values.where((c) => c >= 2).length;
      final repeatRate =
          userCounts.isEmpty ? 0.0 : repeatUsers / userCounts.length.toDouble();

      final reviews = instructorReservations
          .map((r) =>
              context.read<ReservationService>().getReviewForReservation(r.id))
          .whereType<Review>()
          .toList();
      final avgRating = reviews.isEmpty
          ? 0.0
          : reviews.map((r) => r.rating).reduce((a, b) => a + b) /
              reviews.length;

      final score =
          (avgRating * 0.6) + (repeatRate * 5 * 0.3) + (sessionCount * 0.1);

      return _QualityRow(
        instructor: instructor,
        sessionCount: sessionCount,
        avgRating: avgRating,
        repeatRate: repeatRate,
        score: score,
      );
    }).toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      appBar: AppBar(
        title: const Text('指導者品質ダッシュボード'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.deepPurple.shade100,
                        child: Text('${index + 1}'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          row.instructor.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Text(
                        'Score ${row.score.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.deepPurple.shade600,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _metric('指導回数', '${row.sessionCount}回'),
                  _metric(
                      '満足度',
                      row.avgRating == 0
                          ? '未評価'
                          : '★${row.avgRating.toStringAsFixed(1)}'),
                  _metric(
                      'リピート率', '${(row.repeatRate * 100).toStringAsFixed(0)}%'),
                  _metric('勝率', '未計測'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(label)),
          Text(value),
        ],
      ),
    );
  }
}

class _QualityRow {
  final Instructor instructor;
  final int sessionCount;
  final double avgRating;
  final double repeatRate;
  final double score;

  _QualityRow({
    required this.instructor,
    required this.sessionCount,
    required this.avgRating,
    required this.repeatRate,
    required this.score,
  });
}
