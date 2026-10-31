import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// First moment at or after [from] when the wall clock shows [hour]:[minute],
/// skipping today when [skipToday] is set.
tz.TZDateTime nextReminderTime(
  tz.TZDateTime from,
  int hour,
  int minute, {
  bool skipToday = false,
}) {
  var next = tz.TZDateTime(
    from.location,
    from.year,
    from.month,
    from.day,
    hour,
    minute,
  );
  if (skipToday || !next.isAfter(from)) {
    next = tz.TZDateTime(
      from.location,
      from.year,
      from.month,
      from.day + 1,
      hour,
      minute,
    );
  }
  return next;
}

/// Schedules the daily practice reminder as a repeating local notification.
class NotificationService {
  static const int _reminderId = 1;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  /// Asks the OS for permission; returns false if the user refused.
  Future<bool> requestPermission() async {
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await android?.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    return await ios?.requestPermissions(alert: true, sound: true) ?? false;
  }

  /// Repeats daily. With [skipToday] the first reminder fires tomorrow, which
  /// is how learners who already met today's goal avoid a needless nudge.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    bool skipToday = false,
  }) async {
    await _plugin.cancel(id: _reminderId);
    await _plugin.zonedSchedule(
      id: _reminderId,
      title: 'Đến giờ luyện phát âm rồi!',
      body: 'Dành vài phút hôm nay để giữ chuỗi ngày luyện tập của bạn.',
      scheduledDate: nextReminderTime(
        tz.TZDateTime.now(tz.local),
        hour,
        minute,
        skipToday: skipToday,
      ),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Nhắc nhở hằng ngày',
          channelDescription: 'Nhắc bạn luyện phát âm mỗi ngày',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder() => _plugin.cancel(id: _reminderId);
}
