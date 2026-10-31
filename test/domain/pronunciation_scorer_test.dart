import 'package:english_pronunciation/domain/phoneme/grapheme_to_phoneme.dart';
import 'package:english_pronunciation/domain/phoneme/phoneme_aligner.dart';
import 'package:english_pronunciation/domain/phoneme/phoneme_dictionary.dart';
import 'package:english_pronunciation/domain/phoneme/pronunciation_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'phoneme_test_support.dart';

void main() {
  final scorer = PronunciationScorer(testDictionary());

  PronunciationResult run(
    String expected,
    String heard, {
    double? confidence,
  }) => scorer.score(
    expectedText: expected,
    recognizedText: heard,
    confidence: confidence,
  );

  group('normalizeWords', () {
    test('removes punctuation and spells small numbers', () {
      expect(normalizeWords('This is, my 4 CATS!'), [
        'this',
        'is',
        'my',
        'four',
        'cats',
      ]);
    });

    test('keeps contractions and curly apostrophes', () {
      expect(normalizeWords('I don’t'), ['i', "don't"]);
    });
  });

  test('parseCmuDict strips stress, variant markers and comments', () {
    final entries = parseCmuDict('the DH AH0\nthe(2) DH AH1\nx K S # note\n');
    expect(entries['the'], [
      ['DH', 'AH'],
      ['DH', 'AH'],
    ]);
    expect(entries['x'], [
      ['K', 'S'],
    ]);
  });

  test('graphemeToPhoneme covers digraphs for unknown words', () {
    expect(graphemeToPhoneme('shan'), ['SH', 'AE', 'N']);
  });

  group('score', () {
    test('perfect repetition scores 100', () {
      final result = run('This is my best', 'this is my best');
      expect(result.score, 100);
      expect(result.issues, isEmpty);
    });

    test('accepts any dictionary variant of a word', () {
      expect(run('the', 'the').score, 100);
    });

    test('silence scores zero and marks every word missing', () {
      final result = run('good milk', '');
      expect(result.score, 0);
      expect(result.words.every((w) => w.recognizedWord == null), isTrue);
    });

    test('th to s confusion is located in the right word', () {
      final result = run('I think', 'I sink');
      final word = result.words.last;
      expect(word.word, 'think');
      expect(word.phonemes.first.expected, 'TH');
      expect(word.phonemes.first.actual, 'S');
      expect(word.phonemes.first.status, PhonemeStatus.near);
      expect(word.isCorrect, isFalse);
    });

    test('a skipped word does not shift later words', () {
      final result = run('my very good cat', 'my good cat');
      expect(result.words[1].recognizedWord, isNull);
      expect(result.words[2].isCorrect, isTrue);
      expect(result.words[3].isCorrect, isTrue);
    });

    test('added words are reported and lower the score', () {
      final result = run('good cat', 'very good cat');
      expect(result.extraWords, ['very']);
      expect(result.score, lessThan(100));
    });

    test('confidence moves the score by at most its weight', () {
      expect(run('good cat', 'good cat', confidence: 0.5).score, 93);
    });

    test('unusable confidence from the platform is ignored', () {
      final result = run('good cat', 'good cat', confidence: -1);
      expect(result.confidence, isNull);
      expect(result.score, 100);
    });

    test('misread words weigh on the score, not only their sounds', () {
      // Sounds: (2 + 0.6 + 3) / 6 = 0.933; words: 1 of 2 correct.
      expect(run('my think', 'my sink').score, 76);
    });

    test('severity orders scores: exact > near miss > unrelated', () {
      final exact = run('think', 'think').score;
      final near = run('think', 'sink').score;
      final unrelated = run('think', 'milk').score;
      expect(exact, greaterThan(near));
      expect(near, greaterThan(unrelated));
    });
  });
}
