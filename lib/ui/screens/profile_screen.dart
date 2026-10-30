import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

import '../../data/models/user_profile.dart';
import '../../state/app_state.dart';

/// Chooses who is practising, so each person keeps a separate history.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _name = TextEditingController();
  late Future<List<UserProfile>> _profiles;
  String? _error;

  @override
  void initState() {
    super.initState();
    _profiles = context.read<AppState>().users.all();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Hãy nhập tên của bạn.');
      return;
    }
    final app = context.read<AppState>();
    try {
      await app.signIn(await app.users.create(name));
    } on DatabaseException {
      setState(
        () => _error = 'Tên "$name" đã có. Hãy chọn tên đó ở danh sách.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 32),
            Text('Ai đang luyện nói hôm nay?', style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Mỗi người có chuỗi ngày, điểm số và lịch sử luyện tập riêng.',
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _create(),
              decoration: InputDecoration(
                labelText: 'Tên của bạn',
                errorText: _error,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _create, child: const Text('Tạo hồ sơ')),
            const SizedBox(height: 24),
            FutureBuilder<List<UserProfile>>(
              future: _profiles,
              builder: (context, snapshot) {
                final profiles = snapshot.data ?? const <UserProfile>[];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (profiles.isNotEmpty)
                      Text('Hồ sơ đã có', style: textTheme.titleMedium),
                    for (final profile in profiles)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          child: Text(profile.name.characters.first),
                        ),
                        title: Text(profile.name),
                        onTap: () => context.read<AppState>().signIn(profile),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
