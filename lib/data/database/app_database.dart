import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens the local SQLite database. See docs/DATABASE.md for the schema design.
class AppDatabase {
  static const int schemaVersion = 1;

  static Future<Database> open() async {
    final path = p.join(await getDatabasesPath(), 'speak_daily.db');
    return openDatabase(
      path,
      version: schemaVersion,
      onConfigure: configure,
      onCreate: (db, _) => createSchema(db),
    );
  }

  /// SQLite leaves foreign keys off unless enabled on every connection.
  static Future<void> configure(Database db) =>
      db.execute('PRAGMA foreign_keys = ON');

  static Future<void> createSchema(Database db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        daily_goal_minutes INTEGER NOT NULL DEFAULT 10,
        reminder_enabled INTEGER NOT NULL DEFAULT 1,
        reminder_hour INTEGER NOT NULL DEFAULT 20,
        reminder_minute INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE practice_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        exercise_id TEXT NOT NULL,
        local_date TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL DEFAULT 0,
        started_at TEXT NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE pronunciation_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id INTEGER NOT NULL
          REFERENCES practice_sessions(id) ON DELETE CASCADE,
        expected_text TEXT NOT NULL,
        recognized_text TEXT NOT NULL,
        score INTEGER NOT NULL,
        phoneme_accuracy REAL NOT NULL,
        confidence REAL,
        created_at TEXT NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE phoneme_errors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attempt_id INTEGER NOT NULL
          REFERENCES pronunciation_attempts(id) ON DELETE CASCADE,
        word TEXT NOT NULL,
        expected_phoneme TEXT NOT NULL,
        actual_phoneme TEXT
      )
    ''');
    batch.execute(
      'CREATE INDEX idx_sessions_user_date '
      'ON practice_sessions(user_id, local_date)',
    );
    batch.execute(
      'CREATE INDEX idx_attempts_session ON pronunciation_attempts(session_id)',
    );
    batch.execute(
      'CREATE INDEX idx_errors_attempt ON phoneme_errors(attempt_id)',
    );
    await batch.commit();
  }
}
