import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/exercises/exercise_catalog.dart';
import '../../domain/feedback/phoneme_tips.dart';
import '../../domain/phoneme/arpabet.dart';
import '../../state/app_state.dart';
import '../theme.dart';
import 'practice_screen.dart';

/// Picks a sentence for a weak sound, or rotates through the catalog by date.
Exercise exerciseOfTheDay(List<String> weakPhonemes, DateTime now) {
  final suggested = recommendExercises(weakPhonemes, limit: 1);
  if (suggested.isNotEmpty) return suggested.first;
  final day = DateTime.utc(
    now.year,
    now.month,
    now.day,
  ).difference(DateTime.utc(now.year)).inDays;
  return exerciseCatalog[day % exerciseCatalog.length];
}

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user;
    final summary = app.summary;
    if (user == null || summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final textTheme = Theme.of(context).textTheme;
    final weak = summary.weakPhonemes.map((w) => w.phoneme).toList();
    final exercise = exerciseOfTheDay(weak, DateTime.now());
    final goalSeconds = user.dailyGoalMinutes * 60;
    final minutes = summary.todaySeconds ~/ 60;
    final streak = summary.streak.current;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Chào ${user.name}', style: textTheme.titleMedium),
          const SizedBox(height: 16),
          Text('Câu của hôm nay', style: textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(exercise.text, style: textTheme.headlineMedium),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.mic),
            label: const Text('Đọc câu này'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PracticeScreen(exercise: exercise),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: marigold,
                size: 32,
              ),
              const SizedBox(width: 8),
              Text(
                streak == 0 ? 'Bắt đầu chuỗi mới' : 'Chuỗi $streak ngày',
                style: textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            app.goalMetToday
                ? 'Đã đạt mục tiêu hôm nay: $minutes phút'
                : 'Hôm nay: $minutes/${user.dailyGoalMinutes} phút',
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: (summary.todaySeconds / goalSeconds).clamp(0, 1).toDouble(),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            semanticsLabel: 'Tiến độ mục tiêu hôm nay',
          ),
          if (summary.weakPhonemes.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text('Âm nên luyện', style: textTheme.titleLarge),
            for (final sound in summary.weakPhonemes.take(2))
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '/${toIpa(sound.phoneme)}/',
                      style: textTheme.titleMedium,
                    ),
                    Text(phonemeTips[sound.phoneme] ?? ''),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
