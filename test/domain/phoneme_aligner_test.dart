import 'package:english_pronunciation/domain/phoneme/arpabet.dart';
import 'package:english_pronunciation/domain/phoneme/phoneme_aligner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('phonemeSimilarity', () {
    test('ranks identical above confusable above unrelated', () {
      expect(phonemeSimilarity('TH', 'TH'), 1);
      expect(phonemeSimilarity('TH', 'S'), 0.6);
      expect(phonemeSimilarity('M', 'K'), 0.3);
      expect(phonemeSimilarity('IY', 'K'), 0);
    });

    test('is symmetric', () {
      expect(phonemeSimilarity('S', 'TH'), phonemeSimilarity('TH', 'S'));
    });
  });

  group('alignPhonemes', () {
    test('identical sequences are fully correct', () {
      final result = alignPhonemes(['K', 'AE', 'T'], ['K', 'AE', 'T']);
      expect(result.map((c) => c.status), everyElement(PhonemeStatus.correct));
      expect(alignmentAccuracy(result), 1);
    });

    test('dropped final consonant is reported as missing', () {
      final result = alignPhonemes(['B', 'EH', 'S', 'T'], ['B', 'EH', 'S']);
      expect(result.last.expected, 'T');
      expect(result.last.status, PhonemeStatus.missing);
      expect(alignmentAccuracy(result), 0.75);
    });

    test('confusable substitution is a near miss worth 0.6', () {
      final result = alignPhonemes(['TH', 'IH', 'N'], ['T', 'IH', 'N']);
      expect(result.first.status, PhonemeStatus.near);
      expect(result.first.actual, 'T');
      expect(alignmentAccuracy(result), closeTo(2.6 / 3, 1e-9));
    });

    test('extra sound costs half of a missing one', () {
      final result = alignPhonemes(['K', 'AE', 'T'], ['K', 'AE', 'T', 'S']);
      expect(result.last.status, PhonemeStatus.extra);
      expect(alignmentAccuracy(result), closeTo(3 / 3.5, 1e-9));
    });

    test('empty input has zero accuracy', () {
      expect(alignmentAccuracy(alignPhonemes([], [])), 0);
      expect(alignmentAccuracy(alignPhonemes(['K'], [])), 0);
    });
  });
}
