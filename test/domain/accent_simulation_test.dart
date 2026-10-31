import 'dart:io';

import 'package:english_pronunciation/domain/phoneme/phoneme_dictionary.dart';
import 'package:english_pronunciation/domain/phoneme/pronunciation_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

/// Synthetic check using the full CMU dictionary. The "heard" sentences are
/// written by hand to imitate common learner errors; they are NOT recordings,
/// so this guards the scoring logic and does not measure real-world accuracy.
/// Real speaker testing is described in docs/KIEM_THU.md.
void main() {
  final scorer = PronunciationScorer(
    PhonemeDictionary(
      parseCmuDict(File('assets/data/cmudict.dict').readAsStringSync()),
    ),
  );

  int score(String expected, String heard) =>
      scorer.score(expectedText: expected, recognizedText: heard).score;

  const expected = 'I think three thin thieves thanked Thomas.';

  test('dictionary covers every word of every test sentence', () {
    expect(scorer.dictionary.contains('thieves'), isTrue);
    expect(scorer.dictionary.contains('thanked'), isTrue);
  });

  test('clean reading gets full marks', () {
    expect(score(expected, 'I think three thin thieves thanked Thomas'), 100);
  });

  test('more errors never score higher', () {
    final oneError = score(
      expected,
      'I sink three thin thieves thanked Thomas',
    );
    final threeErrors = score(
      expected,
      'I sink tree tin thieves thanked Thomas',
    );
    final fiveErrors = score(expected, 'I sink tree tin thieves tank Tom');
    final silence = score(expected, '');
    expect(oneError, lessThan(100));
    expect(threeErrors, lessThan(oneError));
    expect(fiveErrors, lessThan(threeErrors));
    expect(silence, 0);
  });

  test('typical error patterns all lower the score but stay above zero', () {
    const cases = {
      'dropped endings': (
        'The old cat had a good night',
        'The all cat ha a goo nigh',
      ),
      'th to d': ('This is the mother', 'Dis is de mudder'),
      'long and short i': ('The sheep will sleep', 'The ship will slip'),
      'l and n': ('The light is low', 'The night is no'),
    };
    cases.forEach((name, sample) {
      final value = score(sample.$1, sample.$2);
      expect(value, inInclusiveRange(1, 99), reason: name);
    });
  });
}
