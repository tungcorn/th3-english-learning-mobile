import 'package:flutter/material.dart';

import '../../domain/exercises/exercise_catalog.dart';
import '../../domain/feedback/feedback_engine.dart';
import '../../domain/phoneme/pronunciation_scorer.dart';
import 'phoneme_strip.dart';

/// Score, per-sound markup, articulation tips and suggested exercises.
class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.result,
    required this.feedback,
    required this.onOpenExercise,
  });

  final PronunciationResult result;
  final PronunciationFeedback feedback;
  final ValueChanged<Exercise> onOpenExercise;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${result.score} điểm', style: textTheme.displaySmall),
        const SizedBox(height: 4),
        Text(feedback.headline, style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text('Máy nghe được: "${result.recognizedText}"'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final word in result.words) PhonemeStrip(result: word),
          ],
        ),
        if (result.extraWords.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Từ nói thừa: ${result.extraWords.join(', ')}'),
        ],
        if (feedback.issues.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Âm cần chỉnh', style: textTheme.titleLarge),
          for (final issue in feedback.issues)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(issue.summary, style: textTheme.titleMedium),
                  Text(
                    'Trong từ: ${issue.words.join(', ')}',
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(issue.tip),
                ],
              ),
            ),
        ],
        if (feedback.recommendations.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Bài tập nên làm tiếp', style: textTheme.titleLarge),
          for (final exercise in feedback.recommendations)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(exercise.title),
              subtitle: Text(exercise.text),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onOpenExercise(exercise),
            ),
        ],
      ],
    );
  }
}
