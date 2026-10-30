import 'package:sqflite/sqflite.dart';

import '../models/user_profile.dart';

class UserRepository {
  const UserRepository(this._db);

  final Database _db;

  Future<List<UserProfile>> all() async {
    final rows = await _db.query('users', orderBy: 'name COLLATE NOCASE');
    return rows.map(UserProfile.fromRow).toList();
  }

  Future<UserProfile?> byId(int id) async {
    final rows = await _db.query('users', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : UserProfile.fromRow(rows.first);
  }

  /// Throws [DatabaseException] when the name is already taken.
  Future<UserProfile> create(String name, {DateTime? now}) async {
    final id = await _db.insert('users', {
      'name': name.trim(),
      'created_at': (now ?? DateTime.now()).toIso8601String(),
    });
    return (await byId(id))!;
  }

  Future<UserProfile> updateSettings(
    int id, {
    int? dailyGoalMinutes,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) async {
    await _db.update(
      'users',
      {
        'daily_goal_minutes': ?dailyGoalMinutes,
        if (reminderEnabled != null)
          'reminder_enabled': reminderEnabled ? 1 : 0,
        'reminder_hour': ?reminderHour,
        'reminder_minute': ?reminderMinute,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
    return (await byId(id))!;
  }

  /// Removes the profile and, through cascading keys, all of its history.
  Future<void> delete(int id) =>
      _db.delete('users', where: 'id = ?', whereArgs: [id]);
}
