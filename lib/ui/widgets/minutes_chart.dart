import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/repositories/progress_repository.dart';

const List<String> _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

/// Minutes practised per day, with the daily goal as a reference line.
class MinutesChart extends StatelessWidget {
  const MinutesChart({
    super.key,
    required this.days,
    required this.goalMinutes,
  });

  final List<DailyStat> days;
  final int goalMinutes;

  String _describe() => days
      .map((d) => '${_weekdays[d.date.weekday - 1]} ${d.seconds ~/ 60} phút')
      .join(', ');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final peak = days
        .map((d) => d.seconds / 60)
        .fold<double>(goalMinutes.toDouble(), (a, b) => a > b ? a : b);

    return Semantics(
      label:
          'Số phút luyện tập 7 ngày qua: ${_describe()}. '
          'Mục tiêu $goalMinutes phút mỗi ngày.',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: peak * 1.2,
            minY: 0,
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              leftTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      _weekdays[days[value.toInt()].date.weekday - 1],
                      style: textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
            ),
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: goalMinutes.toDouble(),
                  color: scheme.outline,
                  strokeWidth: 1,
                  dashArray: const [4, 4],
                ),
              ],
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => scheme.inverseSurface,
                getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                  '${rod.toY.round()} phút',
                  TextStyle(color: scheme.onInverseSurface),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < days.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: days[i].seconds / 60,
                      width: 16,
                      color: scheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
