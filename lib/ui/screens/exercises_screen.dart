import 'package:flutter/material.dart';

import '../../domain/exercises/exercise_catalog.dart';
import 'practice_screen.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Bài luyện')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final level in ExerciseLevel.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(level.label, style: textTheme.titleLarge),
            ),
            for (final exercise in exerciseCatalog.where(
              (e) => e.level == level,
            ))
              ListTile(
                title: Text(exercise.title),
                subtitle: Text(exercise.text),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => PracticeScreen(exercise: exercise),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
