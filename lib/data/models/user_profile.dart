class UserProfile {
  const UserProfile({
    required this.id,
    required this.name,
    required this.dailyGoalMinutes,
    required this.reminderEnabled,
    required this.reminderHour,
    required this.reminderMinute,
  });

  factory UserProfile.fromRow(Map<String, Object?> row) => UserProfile(
    id: row['id'] as int,
    name: row['name'] as String,
    dailyGoalMinutes: row['daily_goal_minutes'] as int,
    reminderEnabled: row['reminder_enabled'] == 1,
    reminderHour: row['reminder_hour'] as int,
    reminderMinute: row['reminder_minute'] as int,
  );

  final int id;
  final String name;
  final int dailyGoalMinutes;
  final bool reminderEnabled;
  final int reminderHour;
  final int reminderMinute;
}
