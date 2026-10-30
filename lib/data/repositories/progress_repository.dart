import 'package:sqflite/sqflite.dart';

import '../../domain/progress/streak_calculator.dart';

class DailyStat {
  const DailyStat({
    required this.date,
    required this.seconds,
    required this.averageScore,
  });

  final DateTime date;
  final int seconds;

  /// Null on days without a scored attempt.
  final double? averageScore;
}

class WeakPhoneme {
  const WeakPhoneme(this.phoneme, this.errorCount);

  final String phoneme;
  final int errorCount;
}

class ProgressSummary {
  const ProgressSummary({
    required this.streak,
    required this.todaySeconds,
    required this.totalSeconds,
    required this.attemptCount,
    required this.averageScore,
    required this.lastDays,
    required this.weakPhonemes,
  });

  final StreakInfo streak;
  final int todaySeconds;
  final int totalSeconds;
  final int attemptCount;
  final double? averageScore;

  /// Oldest first, including days without practice.
  final List<DailyStat> lastDays;
  final List<WeakPhoneme> weakPhonemes;
}

class ProgressRepository {
  const ProgressRepository(this._db);

  final Database _db;

  Future<ProgressSummary> summary(
    int userId, {
    DateTime? now,
    int days = 7,
  }) async {
    final today = now ?? DateTime.now();
    final seconds = await _secondsByDay(userId);
    final scores = await _scoreByDay(userId);
    final totals = (await _db.rawQuery(
      '''
      SELECT COUNT(*) AS attempts, AVG(a.score) AS average
      FROM pronunciation_attempts a
      JOIN practice_sessions s ON s.id = a.session_id
      WHERE s.user_id = ?
      ''',
      [userId],
    )).first;

    return ProgressSummary(
      streak: calculateStreak(seconds.keys, today),
      todaySeconds: seconds[localDateKey(today)] ?? 0,
      totalSeconds: seconds.values.fold(0, (sum, value) => sum + value),
      attemptCount: totals['attempts'] as int,
      averageScore: (totals['average'] as num?)?.toDouble(),
      lastDays: [
        for (var offset = days - 1; offset >= 0; offset--)
          _statFor(
            DateTime(today.year, today.month, today.day - offset),
            seconds,
            scores,
          ),
      ],
      weakPhonemes: await weakPhonemes(userId),
    );
  }

  /// Sounds with the most errors across the user's latest 30 attempts, so old
  /// mistakes fade once the learner has improved.
  Future<List<WeakPhoneme>> weakPhonemes(int userId, {int limit = 5}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT e.expected_phoneme AS phoneme, COUNT(*) AS total
      FROM phoneme_errors e
      WHERE e.attempt_id IN (
        SELECT a.id FROM pronunciation_attempts a
        JOIN practice_sessions s ON s.id = a.session_id
        WHERE s.user_id = ?
        ORDER BY a.id DESC LIMIT 30
      )
      GROUP BY e.expected_phoneme
      ORDER BY total DESC, phoneme
      LIMIT ?
      ''',
      [userId, limit],
    );
    return rows
        .map((r) => WeakPhoneme(r['phoneme'] as String, r['total'] as int))
        .toList();
  }

  DailyStat _statFor(
    DateTime date,
    Map<String, int> seconds,
    Map<String, double> scores,
  ) {
    final key = localDateKey(date);
    return DailyStat(
      date: date,
      seconds: seconds[key] ?? 0,
      averageScore: scores[key],
    );
  }

  Future<Map<String, int>> _secondsByDay(int userId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT local_date, SUM(duration_seconds) AS total
      FROM practice_sessions WHERE user_id = ? GROUP BY local_date
      ''',
      [userId],
    );
    return {
      for (final row in rows) row['local_date'] as String: row['total'] as int,
    };
  }

  Future<Map<String, double>> _scoreByDay(int userId) async {
    final rows = await _db.rawQuery(
      '''
      SELECT s.local_date, AVG(a.score) AS average
      FROM pronunciation_attempts a
      JOIN practice_sessions s ON s.id = a.session_id
      WHERE s.user_id = ? GROUP BY s.local_date
      ''',
      [userId],
    );
    return {
      for (final row in rows)
        row['local_date'] as String: (row['average'] as num).toDouble(),
    };
  }
}
