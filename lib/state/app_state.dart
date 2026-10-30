import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../data/models/user_profile.dart';
import '../data/repositories/practice_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/user_repository.dart';
import '../domain/phoneme/phoneme_dictionary.dart';
import '../domain/phoneme/pronunciation_scorer.dart';
import '../services/notification_service.dart';
import '../services/speech_service.dart';

/// Shared services plus the signed-in profile and its progress.
class AppState extends ChangeNotifier {
  AppState({
    required Database database,
    required this.dictionary,
    required this._preferences,
    required this.notifications,
    required this.speech,
  }) : users = UserRepository(database),
       practice = PracticeRepository(database),
       progress = ProgressRepository(database),
       scorer = PronunciationScorer(dictionary);

  static const String _lastUserKey = 'last_user_id';

  final UserRepository users;
  final PracticeRepository practice;
  final ProgressRepository progress;
  final PronunciationScorer scorer;
  final NotificationService notifications;
  final SpeechService speech;
  final PhonemeDictionary dictionary;
  final SharedPreferences _preferences;

  UserProfile? user;
  ProgressSummary? summary;

  bool get goalMetToday {
    final profile = user;
    final today = summary;
    return profile != null &&
        today != null &&
        today.todaySeconds >= profile.dailyGoalMinutes * 60;
  }

  Future<void> restoreLastUser() async {
    final id = _preferences.getInt(_lastUserKey);
    final profile = id == null ? null : await users.byId(id);
    if (profile != null) await signIn(profile);
  }

  Future<void> signIn(UserProfile profile) async {
    user = profile;
    await _preferences.setInt(_lastUserKey, profile.id);
    await refresh();
    await syncReminder();
  }

  Future<void> signOut() async {
    user = null;
    summary = null;
    await _preferences.remove(_lastUserKey);
    await _safely(notifications.cancelReminder);
    notifyListeners();
  }

  Future<void> deleteCurrentUser() async {
    final profile = user;
    if (profile == null) return;
    await users.delete(profile.id);
    await signOut();
  }

  /// Reloads statistics; a met goal moves the next reminder to tomorrow.
  Future<void> refresh() async {
    final profile = user;
    if (profile == null) return;
    final wasMet = goalMetToday;
    summary = await progress.summary(profile.id);
    if (goalMetToday != wasMet) await syncReminder();
    notifyListeners();
  }

  Future<void> updateSettings({
    int? dailyGoalMinutes,
    bool? reminderEnabled,
    int? reminderHour,
    int? reminderMinute,
  }) async {
    final profile = user;
    if (profile == null) return;
    user = await users.updateSettings(
      profile.id,
      dailyGoalMinutes: dailyGoalMinutes,
      reminderEnabled: reminderEnabled,
      reminderHour: reminderHour,
      reminderMinute: reminderMinute,
    );
    await syncReminder();
    notifyListeners();
  }

  Future<void> syncReminder() async {
    final profile = user;
    if (profile == null) return;
    await _safely(() async {
      if (!profile.reminderEnabled) {
        await notifications.cancelReminder();
        return;
      }
      await notifications.requestPermission();
      await notifications.scheduleDailyReminder(
        hour: profile.reminderHour,
        minute: profile.reminderMinute,
        skipToday: goalMetToday,
      );
    });
  }

  /// A failed reminder must never block practising, so errors are only logged.
  Future<void> _safely(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      debugPrint('Reminder update failed: $error');
    }
  }
}
