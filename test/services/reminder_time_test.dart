import 'package:english_pronunciation/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz_data.initializeTimeZones();
  final hanoi = tz.getLocation('Asia/Ho_Chi_Minh');

  tz.TZDateTime at(int day, int hour, int minute) =>
      tz.TZDateTime(hanoi, 2026, 3, day, hour, minute);

  test('uses today when the time is still ahead', () {
    expect(nextReminderTime(at(10, 19, 0), 20, 0), at(10, 20, 0));
  });

  test('moves to tomorrow when the time has passed', () {
    expect(nextReminderTime(at(10, 21, 0), 20, 0), at(11, 20, 0));
  });

  test('moves to tomorrow at exactly the reminder time', () {
    expect(nextReminderTime(at(10, 20, 0), 20, 0), at(11, 20, 0));
  });

  test('skipToday defers even when the time is ahead', () {
    expect(
      nextReminderTime(at(10, 8, 0), 20, 0, skipToday: true),
      at(11, 20, 0),
    );
  });

  test('rolls over the end of the month', () {
    expect(
      nextReminderTime(at(31, 22, 0), 7, 30),
      tz.TZDateTime(hanoi, 2026, 4, 1, 7, 30),
    );
  });
}
