import 'package:english_pronunciation/domain/exercises/exercise_catalog.dart';
import 'package:english_pronunciation/domain/feedback/feedback_engine.dart';
import 'package:english_pronunciation/domain/feedback/phoneme_tips.dart';
import 'package:english_pronunciation/domain/phoneme/arpabet.dart';
import 'package:english_pronunciation/domain/phoneme/pronunciation_scorer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'phoneme_test_support.dart';

void main() {
  final scorer = PronunciationScorer(testDictionary());

  PronunciationFeedback feedback(String expected, String heard) =>
      buildFeedback(
        scorer.score(expectedText: expected, recognizedText: heard),
      );

  test('headline thresholds', () {
    expect(headlineForScore(90), startsWith('Xuất sắc'));
    expect(headlineForScore(89), startsWith('Tốt'));
    expect(headlineForScore(74), startsWith('Khá'));
    expect(headlineForScore(49), startsWith('Cần'));
  });

  test('perfect attempt has no issues or recommendations', () {
    final result = feedback('good cat', 'good cat');
    expect(result.issues, isEmpty);
    expect(result.recommendations, isEmpty);
  });

  test('substitution names the sound, word and a matching exercise', () {
    final result = feedback('I think', 'I sink');
    final issue = result.issues.single;
    expect(issue.phoneme, 'TH');
    expect(issue.heardAs, 'S');
    expect(issue.words, ['think']);
    expect(issue.summary, 'Âm /θ/ nghe giống /s/');
    expect(issue.tip, isNotEmpty);
    expect(result.recommendations.first.id, 'th-voiceless');
  });

  test('dropped ending is reported as a missing sound', () {
    final issue = feedback('best', 'bet').issues.single;
    expect(issue.phoneme, 'S');
    expect(issue.heardAs, isNull);
    expect(issue.summary, 'Thiếu âm /s/');
  });

  test('skipped words do not produce sound-level advice', () {
    expect(feedback('good cat', 'good').issues, isEmpty);
  });

  test('every phoneme has a tip and an exercise', () {
    final trained = exerciseCatalog.expand((e) => e.focus).toSet();
    for (final phoneme in arpabetToIpa.keys) {
      expect(phonemeTips[phoneme], isNotNull, reason: 'tip for $phoneme');
      expect(trained, contains(phoneme), reason: 'exercise for $phoneme');
    }
  });

  test('recommendations respect priority, exclusions and limit', () {
    final picks = recommendExercises(
      ['TH', 'S'],
      excludeIds: {'th-voiced'},
      limit: 2,
    );
    expect(picks.map((e) => e.id), ['th-voiceless', 'final-s-z']);
  });

  test('exercise ids are unique', () {
    final ids = exerciseCatalog.map((e) => e.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });
}
