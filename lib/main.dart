import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database/app_database.dart';
import 'domain/phoneme/phoneme_dictionary.dart';
import 'services/notification_service.dart';
import 'services/speech_service.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notifications = NotificationService();
  try {
    await notifications.initialize();
  } catch (error) {
    debugPrint('Notifications unavailable: $error');
  }

  final app = AppState(
    database: await AppDatabase.open(),
    dictionary: await PhonemeDictionary.loadFromAssets(),
    preferences: await SharedPreferences.getInstance(),
    notifications: notifications,
    speech: SpeechService(),
  );
  await app.restoreLastUser();

  runApp(
    ChangeNotifierProvider.value(value: app, child: const SpeakDailyApp()),
  );
}
