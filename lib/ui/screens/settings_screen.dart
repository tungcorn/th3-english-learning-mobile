import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../domain/evaluation/attempt_csv.dart';
import '../../state/app_state.dart';

const List<int> _goalChoices = [5, 10, 15, 20, 30];

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pickTime(BuildContext context, AppState app) async {
    final user = app.user!;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: user.reminderHour,
        minute: user.reminderMinute,
      ),
    );
    if (picked != null) {
      await app.updateSettings(
        reminderHour: picked.hour,
        reminderMinute: picked.minute,
      );
    }
  }

  Future<void> _copyLog(BuildContext context, AppState app) async {
    final messenger = ScaffoldMessenger.of(context);
    final user = app.user!;
    final attempts = await app.practice.history(user.id);
    await Clipboard.setData(
      ClipboardData(text: attemptsToCsv(user.name, attempts)),
    );
    messenger.showSnackBar(
      SnackBar(content: Text('Đã sao chép ${attempts.length} lần đọc.')),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppState app) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xóa hồ sơ ${app.user!.name}?'),
        content: const Text(
          'Toàn bộ lịch sử luyện tập và điểm số của hồ sơ này sẽ bị xóa vĩnh viễn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Giữ lại'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa hồ sơ'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await app.deleteCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user;
    if (user == null) return const SizedBox.shrink();
    final textTheme = Theme.of(context).textTheme;
    final time = TimeOfDay(
      hour: user.reminderHour,
      minute: user.reminderMinute,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Mục tiêu mỗi ngày', style: textTheme.titleMedium),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              children: [
                for (final minutes in _goalChoices)
                  ChoiceChip(
                    label: Text('$minutes phút'),
                    selected: user.dailyGoalMinutes == minutes,
                    onSelected: (_) =>
                        app.updateSettings(dailyGoalMinutes: minutes),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Nhắc luyện tập mỗi ngày'),
            value: user.reminderEnabled,
            onChanged: (enabled) =>
                app.updateSettings(reminderEnabled: enabled),
          ),
          ListTile(
            enabled: user.reminderEnabled,
            title: const Text('Giờ nhắc'),
            trailing: Text(time.format(context), style: textTheme.titleMedium),
            onTap: () => _pickTime(context, app),
          ),
          const Divider(),
          ListTile(
            title: const Text('Sao chép nhật ký kiểm thử'),
            subtitle: const Text('Dạng CSV, dùng để đánh giá độ chính xác'),
            onTap: () => _copyLog(context, app),
          ),
          ListTile(
            title: const Text('Đổi hồ sơ'),
            subtitle: Text('Đang dùng: ${user.name}'),
            onTap: app.signOut,
          ),
          ListTile(
            title: Text(
              'Xóa hồ sơ này',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmDelete(context, app),
          ),
        ],
      ),
    );
  }
}
