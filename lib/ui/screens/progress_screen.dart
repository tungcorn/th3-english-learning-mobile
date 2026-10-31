import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/practice_repository.dart';
import '../../domain/phoneme/arpabet.dart';
import '../../state/app_state.dart';
import '../widgets/minutes_chart.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  String _formatTotal(int seconds) {
    final minutes = seconds ~/ 60;
    return minutes < 60
        ? '$minutes phút'
        : '${minutes ~/ 60} giờ ${minutes % 60} phút';
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user;
    final summary = app.summary;
    if (user == null || summary == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final textTheme = Theme.of(context).textTheme;
    final average = summary.averageScore;

    return Scaffold(
      appBar: AppBar(title: const Text('Tiến độ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatLine('Chuỗi hiện tại', '${summary.streak.current} ngày'),
          _StatLine('Chuỗi dài nhất', '${summary.streak.longest} ngày'),
          _StatLine('Tổng thời gian học', _formatTotal(summary.totalSeconds)),
          _StatLine('Số lần đọc', '${summary.attemptCount}'),
          _StatLine(
            'Điểm trung bình',
            average == null ? 'Chưa có' : '${average.round()} điểm',
          ),
          const SizedBox(height: 24),
          Text('Số phút luyện 7 ngày qua', style: textTheme.titleLarge),
          const SizedBox(height: 16),
          MinutesChart(
            days: summary.lastDays,
            goalMinutes: user.dailyGoalMinutes,
          ),
          const SizedBox(height: 8),
          Text(
            'Đường nét đứt là mục tiêu ${user.dailyGoalMinutes} phút mỗi ngày.',
            style: textTheme.bodySmall,
          ),
          if (summary.weakPhonemes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Âm hay sai gần đây', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            for (final sound in summary.weakPhonemes)
              _StatLine('/${toIpa(sound.phoneme)}/', '${sound.errorCount} lỗi'),
          ],
          const SizedBox(height: 24),
          Text('Lần đọc gần đây', style: textTheme.titleLarge),
          FutureBuilder<List<AttemptRecord>>(
            future: app.practice.history(user.id, limit: 10),
            builder: (context, snapshot) {
              final attempts = snapshot.data ?? const <AttemptRecord>[];
              if (snapshot.connectionState == ConnectionState.done &&
                  attempts.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Đọc câu đầu tiên để xem kết quả ở đây.'),
                );
              }
              final format = DateFormat('dd/MM HH:mm');
              return Column(
                children: [
                  for (final attempt in attempts)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(attempt.expectedText),
                      subtitle: Text(format.format(attempt.createdAt)),
                      trailing: Text(
                        '${attempt.score}',
                        style: textTheme.titleLarge,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
