import 'package:english_pronunciation/data/repositories/practice_repository.dart';
import 'package:english_pronunciation/data/repositories/progress_repository.dart';
import 'package:english_pronunciation/domain/evaluation/attempt_csv.dart';
import 'package:english_pronunciation/domain/feedback/feedback_engine.dart';
import 'package:english_pronunciation/domain/phoneme/pronunciation_scorer.dart';
import 'package:english_pronunciation/ui/screens/today_screen.dart';
import 'package:english_pronunciation/ui/widgets/minutes_chart.dart';
import 'package:english_pronunciation/ui/widgets/result_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../domain/phoneme_test_support.dart';

void main() {
  final scorer = PronunciationScorer(testDictionary());

  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  Future<void> pumpResult(WidgetTester tester, String heard) {
    final result = scorer.score(expectedText: 'I think', recognizedText: heard);
    return tester.pumpWidget(
      host(
        ResultPanel(
          result: result,
          feedback: buildFeedback(result),
          onOpenExercise: (_) {},
        ),
      ),
    );
  }

  testWidgets('shows score, heard sound and articulation tip', (tester) async {
    await pumpResult(tester, 'I sink');
    expect(find.textContaining('điểm'), findsOneWidget);
    expect(find.text('Nghe thành "sink"'), findsOneWidget);
    expect(find.text('Âm /θ/ nghe giống /s/'), findsOneWidget);
    expect(find.text('θ'), findsOneWidget);
    expect(find.text('Bài tập nên làm tiếp'), findsOneWidget);
  });

  testWidgets('perfect reading shows no correction sections', (tester) async {
    await pumpResult(tester, 'I think');
    expect(find.text('100 điểm'), findsOneWidget);
    expect(find.text('Âm cần chỉnh'), findsNothing);
    expect(find.text('Bài tập nên làm tiếp'), findsNothing);
  });

  testWidgets('chart renders with a week without practice', (tester) async {
    final days = [
      for (var i = 0; i < 7; i++)
        DailyStat(
          date: DateTime(2026, 3, 2 + i),
          seconds: 0,
          averageScore: null,
        ),
    ];
    await tester.pumpWidget(host(MinutesChart(days: days, goalMinutes: 10)));
    expect(find.text('T2'), findsOneWidget);
    expect(find.text('CN'), findsOneWidget);
  });

  test('CSV escapes quotes in free text', () {
    final csv = attemptsToCsv('Lan', [
      AttemptRecord(
        exerciseId: 'ex',
        expectedText: 'say "hi"',
        recognizedText: 'say hi',
        score: 80,
        createdAt: DateTime(2026, 3, 1),
      ),
    ]);
    expect(csv.split('\n').last, contains('"say ""hi"""'));
    expect(csv.split('\n').last, endsWith(',80'));
  });

  test('exercise of the day follows weak sounds, otherwise the date', () {
    expect(exerciseOfTheDay(['DH'], DateTime(2026, 3, 1)).id, 'th-voiced');
    expect(exerciseOfTheDay([], DateTime(2026, 1, 1)).id, 'greet-1');
  });
}
