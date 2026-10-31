import '../../data/repositories/practice_repository.dart';

String _escape(String value) => '"${value.replaceAll('"', '""')}"';

/// Formats attempts as CSV so testers can compare scores against a human rating.
String attemptsToCsv(String speaker, List<AttemptRecord> attempts) {
  final lines = ['speaker,exercise,time,expected,recognized,score'];
  for (final attempt in attempts) {
    lines.add(
      [
        _escape(speaker),
        _escape(attempt.exerciseId),
        attempt.createdAt.toIso8601String(),
        _escape(attempt.expectedText),
        _escape(attempt.recognizedText),
        attempt.score,
      ].join(','),
    );
  }
  return lines.join('\n');
}
