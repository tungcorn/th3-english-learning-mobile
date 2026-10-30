import 'package:english_pronunciation/data/database/app_database.dart';
import 'package:english_pronunciation/data/repositories/practice_repository.dart';
import 'package:english_pronunciation/data/repositories/progress_repository.dart';
import 'package:english_pronunciation/data/repositories/user_repository.dart';
import 'package:english_pronunciation/domain/phoneme/pronunciation_scorer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../domain/phoneme_test_support.dart';

void main() {
  sqfliteFfiInit();
  late Database db;
  late UserRepository users;
  late PracticeRepository practice;
  late ProgressRepository progress;
  final scorer = PronunciationScorer(testDictionary());
  final now = DateTime(2026, 3, 10, 20);

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: AppDatabase.schemaVersion,
        singleInstance: false,
        onConfigure: AppDatabase.configure,
        onCreate: (db, _) => AppDatabase.createSchema(db),
      ),
    );
    users = UserRepository(db);
    practice = PracticeRepository(db);
    progress = ProgressRepository(db);
  });

  tearDown(() => db.close());

  Future<void> practise(
    int userId,
    DateTime at, {
    int seconds = 60,
    String heard = 'I sink',
  }) async {
    final session = await practice.startSession(
      userId: userId,
      exerciseId: 'ex',
      now: at,
    );
    await practice.updateDuration(session, seconds);
    await practice.saveAttempt(
      session,
      scorer.score(expectedText: 'I think', recognizedText: heard),
      now: at,
    );
  }

  test('new profile gets default goal and reminder', () async {
    final user = await users.create('  Lan ');
    expect(user.name, 'Lan');
    expect(user.dailyGoalMinutes, 10);
    expect(user.reminderEnabled, isTrue);
    expect(user.reminderHour, 20);
  });

  test('duplicate names are rejected', () async {
    await users.create('Lan');
    expect(() => users.create('Lan'), throwsA(isA<DatabaseException>()));
  });

  test('settings update only the given fields', () async {
    final user = await users.create('Lan');
    final updated = await users.updateSettings(user.id, dailyGoalMinutes: 25);
    expect(updated.dailyGoalMinutes, 25);
    expect(updated.reminderHour, 20);
    final off = await users.updateSettings(user.id, reminderEnabled: false);
    expect(off.reminderEnabled, isFalse);
  });

  test('summary aggregates time, streak and score per user', () async {
    final lan = await users.create('Lan');
    final minh = await users.create('Minh');
    await practise(lan.id, now.subtract(const Duration(days: 1)), seconds: 120);
    await practise(lan.id, now, seconds: 90);
    await practise(lan.id, now, seconds: 30, heard: 'I think');
    await practise(minh.id, now, seconds: 999);

    final summary = await progress.summary(lan.id, now: now);
    expect(summary.streak.current, 2);
    expect(summary.todaySeconds, 120);
    expect(summary.totalSeconds, 240);
    expect(summary.attemptCount, 3);
    expect(summary.lastDays, hasLength(7));
    expect(summary.lastDays.last.seconds, 120);
    expect(summary.lastDays[5].seconds, 120);
    expect(summary.lastDays.first.averageScore, isNull);
  });

  test('errors are stored per phoneme and ranked as weak sounds', () async {
    final user = await users.create('Lan');
    await practise(user.id, now);
    await practise(user.id, now);

    final weak = await progress.weakPhonemes(user.id);
    expect(weak.single.phoneme, 'TH');
    expect(weak.single.errorCount, 2);
    final row = (await db.query('phoneme_errors')).first;
    expect(row['word'], 'think');
    expect(row['actual_phoneme'], 'S');
  });

  test('a clean attempt records no phoneme errors', () async {
    final user = await users.create('Lan');
    await practise(user.id, now, heard: 'I think');
    expect(await db.query('phoneme_errors'), isEmpty);
  });

  test('deleting a profile cascades to all its history', () async {
    final user = await users.create('Lan');
    await practise(user.id, now);
    await users.delete(user.id);
    for (final table in [
      'practice_sessions',
      'pronunciation_attempts',
      'phoneme_errors',
    ]) {
      expect(await db.query(table), isEmpty, reason: table);
    }
  });

  test('history returns the newest attempt first', () async {
    final user = await users.create('Lan');
    await practise(user.id, now.subtract(const Duration(days: 2)));
    await practise(user.id, now, heard: 'I think');
    final history = await practice.history(user.id, limit: 1);
    expect(history.single.score, 100);
  });
}
