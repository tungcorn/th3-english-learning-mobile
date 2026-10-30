import 'package:sqflite/sqflite.dart';

import '../../domain/phoneme/phoneme_aligner.dart';
import '../../domain/phoneme/pronunciation_scorer.dart';
import '../../domain/progress/streak_calculator.dart';

class AttemptRecord {
  const AttemptRecord({
    required this.exerciseId,
    required this.expectedText,
    required this.recognizedText,
    required this.score,
    required this.createdAt,
  });

  final String exerciseId;
  final String expectedText;
  final String recognizedText;
  final int score;
  final DateTime createdAt;
}

class PracticeRepository {
  const PracticeRepository(this._db);

  final Database _db;

  Future<int> startSession({
    required int userId,
    required String exerciseId,
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();
    return _db.insert('practice_sessions', {
      'user_id': userId,
      'exercise_id': exerciseId,
      'local_date': localDateKey(time),
      'started_at': time.toIso8601String(),
    });
  }

  Future<void> updateDuration(int sessionId, int seconds) => _db.update(
    'practice_sessions',
    {'duration_seconds': seconds},
    where: 'id = ?',
    whereArgs: [sessionId],
  );

  /// Stores an attempt and each mispronounced sound in a single transaction.
  Future<int> saveAttempt(
    int sessionId,
    PronunciationResult result, {
    DateTime? now,
  }) {
    return _db.transaction((txn) async {
      final attemptId = await txn.insert('pronunciation_attempts', {
        'session_id': sessionId,
        'expected_text': result.expectedText,
        'recognized_text': result.recognizedText,
        'score': result.score,
        'phoneme_accuracy': result.phonemeAccuracy,
        'confidence': result.confidence,
        'created_at': (now ?? DateTime.now()).toIso8601String(),
      });
      for (final word in result.words) {
        for (final column in word.phonemes) {
          if (column.status == PhonemeStatus.correct ||
              column.expected == null) {
            continue;
          }
          await txn.insert('phoneme_errors', {
            'attempt_id': attemptId,
            'word': word.word,
            'expected_phoneme': column.expected,
            'actual_phoneme': column.actual,
          });
        }
      }
      return attemptId;
    });
  }

  Future<List<AttemptRecord>> history(int userId, {int? limit}) async {
    final rows = await _db.rawQuery(
      '''
      SELECT s.exercise_id, a.expected_text, a.recognized_text, a.score,
             a.created_at
      FROM pronunciation_attempts a
      JOIN practice_sessions s ON s.id = a.session_id
      WHERE s.user_id = ?
      ORDER BY a.created_at DESC, a.id DESC
      ${limit == null ? '' : 'LIMIT $limit'}
      ''',
      [userId],
    );
    return rows
        .map(
          (row) => AttemptRecord(
            exerciseId: row['exercise_id'] as String,
            expectedText: row['expected_text'] as String,
            recognizedText: row['recognized_text'] as String,
            score: row['score'] as int,
            createdAt: DateTime.parse(row['created_at'] as String),
          ),
        )
        .toList();
  }
}
