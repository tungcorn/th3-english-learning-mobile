import 'phoneme_aligner.dart';
import 'phoneme_dictionary.dart';

/// Scoring outcome of one reference word.
class WordResult {
  const WordResult({
    required this.word,
    required this.recognizedWord,
    required this.phonemes,
  });

  final String word;

  /// Null when the speech engine heard nothing for this word.
  final String? recognizedWord;
  final List<AlignedPhoneme> phonemes;

  int get score => (alignmentAccuracy(phonemes) * 100).round();

  bool get isCorrect =>
      phonemes.every((p) => p.status == PhonemeStatus.correct);
}

class PronunciationResult {
  const PronunciationResult({
    required this.expectedText,
    required this.recognizedText,
    required this.words,
    required this.extraWords,
    required this.phonemeAccuracy,
    required this.confidence,
    required this.score,
  });

  final String expectedText;
  final String recognizedText;
  final List<WordResult> words;

  /// Words the speaker added that are not part of the reference text.
  final List<String> extraWords;

  /// Phoneme match in 0..1, before the confidence adjustment.
  final double phonemeAccuracy;

  /// Engine confidence in 0..1, or null when the platform does not report it.
  final double? confidence;

  /// Final score, 0..100.
  final int score;

  Iterable<AlignedPhoneme> get issues => words
      .expand((w) => w.phonemes)
      .where((p) => p.status != PhonemeStatus.correct);
}

/// Compares what the speech engine heard with the reference text at phoneme
/// level. Words are aligned first, so a skipped word cannot shift the phonemes
/// of the words after it.
class PronunciationScorer {
  const PronunciationScorer(this.dictionary);

  final PhonemeDictionary dictionary;

  static const double _wordWeight = 0.4;
  static const double _confidenceWeight = 0.15;
  static const double _wordGapScore = -0.5;

  PronunciationResult score({
    required String expectedText,
    required String recognizedText,
    double? confidence,
  }) {
    final expected = normalizeWords(expectedText);
    final recognized = normalizeWords(recognizedText);
    final pairs = _alignWords(expected, recognized);

    final words = <WordResult>[];
    final extraWords = <String>[];
    final columns = <AlignedPhoneme>[];
    for (final (expectedWord, recognizedWord) in pairs) {
      if (expectedWord == null) {
        extraWords.add(recognizedWord!);
        columns.addAll(
          dictionary
              .lookup(recognizedWord)
              .first
              .map((p) => AlignedPhoneme(actual: p, similarity: 0)),
        );
        continue;
      }
      final phonemes = recognizedWord == null
          ? dictionary
                .lookup(expectedWord)
                .first
                .map((p) => AlignedPhoneme(expected: p, similarity: 0))
                .toList()
          : _bestAlignment(expectedWord, recognizedWord);
      words.add(
        WordResult(
          word: expectedWord,
          recognizedWord: recognizedWord,
          phonemes: phonemes,
        ),
      );
      columns.addAll(phonemes);
    }

    final accuracy = alignmentAccuracy(columns);
    final wordAccuracy = words.isEmpty
        ? 0.0
        : words.where((w) => w.isCorrect).length / words.length;
    return PronunciationResult(
      expectedText: expectedText,
      recognizedText: recognizedText,
      words: words,
      extraWords: extraWords,
      phonemeAccuracy: accuracy,
      confidence: _usableConfidence(confidence),
      score: _finalScore(accuracy, wordAccuracy, _usableConfidence(confidence)),
    );
  }

  /// Android reports -1 or 0 when it has no confidence value.
  double? _usableConfidence(double? value) =>
      value != null && value > 0 && value <= 1 ? value : null;

  /// Most sounds of a misread word are still right, so phoneme accuracy alone
  /// is too generous; the share of fully correct words balances it.
  int _finalScore(double accuracy, double wordAccuracy, double? confidence) {
    if (accuracy == 0) return 0;
    final match = accuracy * (1 - _wordWeight) + wordAccuracy * _wordWeight;
    final blended = confidence == null
        ? match
        : match * (1 - _confidenceWeight) + confidence * _confidenceWeight;
    return (blended * 100).round();
  }

  /// Picks the dictionary variants that give [recognized] the best match, so
  /// either accepted pronunciation of a word such as "the" scores full marks.
  List<AlignedPhoneme> _bestAlignment(String expected, String recognized) {
    List<AlignedPhoneme>? best;
    var bestAccuracy = -1.0;
    for (final reference in dictionary.lookup(expected)) {
      for (final heard in dictionary.lookup(recognized)) {
        final alignment = alignPhonemes(reference, heard);
        final accuracy = alignmentAccuracy(alignment);
        if (accuracy > bestAccuracy) {
          bestAccuracy = accuracy;
          best = alignment;
        }
      }
    }
    return best!;
  }

  double _wordSimilarity(String expected, String recognized) =>
      expected == recognized
      ? 1
      : alignmentAccuracy(_bestAlignment(expected, recognized));

  /// Global alignment over words; a null side marks a skipped or added word.
  List<(String?, String?)> _alignWords(
    List<String> expected,
    List<String> recognized,
  ) {
    final rows = expected.length + 1;
    final cols = recognized.length + 1;
    final scores = List.generate(rows, (_) => List<double>.filled(cols, 0));
    final similarity = List.generate(
      expected.length,
      (i) => List.generate(
        recognized.length,
        (j) => _wordSimilarity(expected[i], recognized[j]),
      ),
    );
    for (var i = 1; i < rows; i++) {
      scores[i][0] = i * _wordGapScore;
    }
    for (var j = 1; j < cols; j++) {
      scores[0][j] = j * _wordGapScore;
    }
    for (var i = 1; i < rows; i++) {
      for (var j = 1; j < cols; j++) {
        final diagonal =
            scores[i - 1][j - 1] + 2 * similarity[i - 1][j - 1] - 1;
        final up = scores[i - 1][j] + _wordGapScore;
        final left = scores[i][j - 1] + _wordGapScore;
        scores[i][j] = [diagonal, up, left].reduce((a, b) => a > b ? a : b);
      }
    }

    final pairs = <(String?, String?)>[];
    var i = expected.length;
    var j = recognized.length;
    while (i > 0 || j > 0) {
      if (i > 0 &&
          j > 0 &&
          scores[i][j] ==
              scores[i - 1][j - 1] + 2 * similarity[i - 1][j - 1] - 1) {
        pairs.add((expected[i - 1], recognized[j - 1]));
        i--;
        j--;
      } else if (i > 0 && scores[i][j] == scores[i - 1][j] + _wordGapScore) {
        pairs.add((expected[i - 1], null));
        i--;
      } else {
        pairs.add((null, recognized[j - 1]));
        j--;
      }
    }
    return pairs.reversed.toList();
  }
}
