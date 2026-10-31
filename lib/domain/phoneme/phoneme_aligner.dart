import 'arpabet.dart';

enum PhonemeStatus { correct, near, wrong, missing, extra }

/// One column of an alignment. [expected] is null for an inserted sound and
/// [actual] is null for a sound the speaker skipped.
class AlignedPhoneme {
  const AlignedPhoneme({this.expected, this.actual, required this.similarity});

  final String? expected;
  final String? actual;
  final double similarity;

  PhonemeStatus get status {
    if (expected == null) return PhonemeStatus.extra;
    if (actual == null) return PhonemeStatus.missing;
    if (similarity == 1) return PhonemeStatus.correct;
    return similarity >= 0.6 ? PhonemeStatus.near : PhonemeStatus.wrong;
  }
}

const double _gapScore = -0.5;

double _substitutionScore(double similarity) => 2 * similarity - 1;

/// Needleman-Wunsch global alignment weighted by [phonemeSimilarity].
List<AlignedPhoneme> alignPhonemes(List<String> expected, List<String> actual) {
  final rows = expected.length + 1;
  final cols = actual.length + 1;
  final scores = List.generate(rows, (_) => List<double>.filled(cols, 0));
  for (var i = 1; i < rows; i++) {
    scores[i][0] = i * _gapScore;
  }
  for (var j = 1; j < cols; j++) {
    scores[0][j] = j * _gapScore;
  }
  for (var i = 1; i < rows; i++) {
    for (var j = 1; j < cols; j++) {
      final diagonal =
          scores[i - 1][j - 1] +
          _substitutionScore(phonemeSimilarity(expected[i - 1], actual[j - 1]));
      final up = scores[i - 1][j] + _gapScore;
      final left = scores[i][j - 1] + _gapScore;
      scores[i][j] = [diagonal, up, left].reduce((a, b) => a > b ? a : b);
    }
  }

  final aligned = <AlignedPhoneme>[];
  var i = expected.length;
  var j = actual.length;
  while (i > 0 || j > 0) {
    if (i > 0 && j > 0) {
      final similarity = phonemeSimilarity(expected[i - 1], actual[j - 1]);
      if (scores[i][j] ==
          scores[i - 1][j - 1] + _substitutionScore(similarity)) {
        aligned.add(
          AlignedPhoneme(
            expected: expected[i - 1],
            actual: actual[j - 1],
            similarity: similarity,
          ),
        );
        i--;
        j--;
        continue;
      }
    }
    if (i > 0 && scores[i][j] == scores[i - 1][j] + _gapScore) {
      aligned.add(AlignedPhoneme(expected: expected[i - 1], similarity: 0));
      i--;
    } else {
      aligned.add(AlignedPhoneme(actual: actual[j - 1], similarity: 0));
      j--;
    }
  }
  return aligned.reversed.toList();
}

/// Share of [expected] reproduced, in 0..1. Extra sounds count half as much as
/// a missing sound so that a stray syllable costs less than a skipped one.
double alignmentAccuracy(List<AlignedPhoneme> alignment) {
  var earned = 0.0;
  var expectedCount = 0;
  var extraCount = 0;
  for (final column in alignment) {
    if (column.expected == null) {
      extraCount++;
    } else {
      expectedCount++;
      earned += column.similarity;
    }
  }
  final denominator = expectedCount + extraCount * 0.5;
  return denominator == 0 ? 0 : earned / denominator;
}
