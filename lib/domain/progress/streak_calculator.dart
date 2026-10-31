class StreakInfo {
  const StreakInfo({required this.current, required this.longest});

  final int current;
  final int longest;
}

/// `yyyy-MM-dd` key of a device-local day.
String localDateKey(DateTime time) {
  final month = time.month.toString().padLeft(2, '0');
  final day = time.day.toString().padLeft(2, '0');
  return '${time.year.toString().padLeft(4, '0')}-$month-$day';
}

/// Dates are compared in UTC so a daylight-saving change cannot break a run.
DateTime _dayOf(DateTime time) => DateTime.utc(time.year, time.month, time.day);

/// Computes streaks from practised days given as [localDateKey] values.
///
/// A streak stays alive until the end of the next day: not having practised yet
/// today does not reset it, but missing a full day does.
StreakInfo calculateStreak(Iterable<String> practisedDays, DateTime now) {
  final days = practisedDays.map(DateTime.parse).map(_dayOf).toSet().toList()
    ..sort();
  if (days.isEmpty) return const StreakInfo(current: 0, longest: 0);

  var longest = 1;
  var run = 1;
  for (var i = 1; i < days.length; i++) {
    run = days[i].difference(days[i - 1]).inDays == 1 ? run + 1 : 1;
    if (run > longest) longest = run;
  }

  final gapToToday = _dayOf(now).difference(days.last).inDays;
  return StreakInfo(current: gapToToday <= 1 ? run : 0, longest: longest);
}
