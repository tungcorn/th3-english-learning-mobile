import '../exercises/exercise_catalog.dart';
import '../phoneme/arpabet.dart';
import '../phoneme/phoneme_aligner.dart';
import '../phoneme/pronunciation_scorer.dart';
import 'phoneme_tips.dart';

/// One sound to work on, with the words where it went wrong.
class SoundIssue {
  const SoundIssue({
    required this.phoneme,
    required this.heardAs,
    required this.words,
    required this.count,
    required this.tip,
  });

  final String phoneme;

  /// What was heard in place of [phoneme]; null means it was skipped.
  final String? heardAs;
  final List<String> words;
  final int count;
  final String tip;

  String get summary {
    final target = '/${toIpa(phoneme)}/';
    final replaced = heardAs;
    return replaced == null
        ? 'Thiếu âm $target'
        : 'Âm $target nghe giống /${toIpa(replaced)}/';
  }
}

class PronunciationFeedback {
  const PronunciationFeedback({
    required this.headline,
    required this.issues,
    required this.recommendations,
  });

  final String headline;
  final List<SoundIssue> issues;
  final List<Exercise> recommendations;
}

const int _maxIssues = 3;

String headlineForScore(int score) {
  if (score >= 90) return 'Xuất sắc! Phát âm rất rõ ràng.';
  if (score >= 75) return 'Tốt lắm! Chỉ còn vài âm cần chỉnh.';
  if (score >= 50) return 'Khá ổn. Hãy luyện thêm các âm bên dưới.';
  return 'Cần luyện thêm. Hãy nói chậm và rõ từng từ.';
}

PronunciationFeedback buildFeedback(
  PronunciationResult result, {
  String? currentExerciseId,
}) {
  final grouped = <String, _IssueGroup>{};
  for (final word in result.words) {
    // A word that was never heard says nothing about its individual sounds.
    if (word.recognizedWord == null) continue;
    for (final column in word.phonemes) {
      final expected = column.expected;
      if (expected == null || column.status == PhonemeStatus.correct) continue;
      grouped
          .putIfAbsent(expected, () => _IssueGroup(column.actual))
          .add(word.word);
    }
  }

  final ranked = grouped.entries.toList()
    ..sort((a, b) => b.value.count.compareTo(a.value.count));
  final issues = [
    for (final entry in ranked.take(_maxIssues))
      SoundIssue(
        phoneme: entry.key,
        heardAs: entry.value.heardAs,
        words: entry.value.words.toList(),
        count: entry.value.count,
        tip: phonemeTips[entry.key] ?? '',
      ),
  ];

  return PronunciationFeedback(
    headline: headlineForScore(result.score),
    issues: issues,
    recommendations: recommendExercises(
      [for (final issue in issues) issue.phoneme],
      excludeIds: {?currentExerciseId},
    ),
  );
}

class _IssueGroup {
  _IssueGroup(this.heardAs);

  final String? heardAs;
  final Set<String> words = {};
  int count = 0;

  void add(String word) {
    words.add(word);
    count++;
  }
}
