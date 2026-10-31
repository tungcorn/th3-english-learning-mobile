import 'package:english_pronunciation/domain/progress/streak_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 3, 10, 21, 30);

  test('no practice gives zero', () {
    final streak = calculateStreak([], today);
    expect(streak.current, 0);
    expect(streak.longest, 0);
  });

  test('counts consecutive days ending today', () {
    final streak = calculateStreak([
      '2026-03-08',
      '2026-03-09',
      '2026-03-10',
    ], today);
    expect(streak.current, 3);
  });

  test('stays alive when the last practice was yesterday', () {
    expect(calculateStreak(['2026-03-08', '2026-03-09'], today).current, 2);
  });

  test('resets after a full missed day but keeps the longest run', () {
    final streak = calculateStreak([
      '2026-03-01',
      '2026-03-02',
      '2026-03-03',
      '2026-03-08',
    ], today);
    expect(streak.current, 0);
    expect(streak.longest, 3);
  });

  test('a new run after a gap starts from one', () {
    final streak = calculateStreak(['2026-03-05', '2026-03-10'], today);
    expect(streak.current, 1);
  });

  test('duplicates and unsorted input do not inflate the count', () {
    final streak = calculateStreak([
      '2026-03-10',
      '2026-03-09',
      '2026-03-10',
      '2026-03-09',
    ], today);
    expect(streak.current, 2);
    expect(streak.longest, 2);
  });

  test('crosses month and leap-year boundaries', () {
    final streak = calculateStreak([
      '2028-02-28',
      '2028-02-29',
      '2028-03-01',
    ], DateTime(2028, 3, 1));
    expect(streak.current, 3);
  });

  test('localDateKey pads month and day', () {
    expect(localDateKey(DateTime(2026, 3, 5, 23, 59)), '2026-03-05');
  });
}
