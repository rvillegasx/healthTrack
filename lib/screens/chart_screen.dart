import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_track/models/health_record.dart';
import 'package:health_track/providers/records_provider.dart';
import 'package:intl/intl.dart';

class ChartScreen extends ConsumerWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Glucose Chart')),
      body: recordsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (records) {
          final withGlucose = records
              .where((r) => r.glucoseDouble != null)
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          if (withGlucose.isEmpty) {
            return const Center(child: Text('No glucose records to display.'));
          }

          return _GlucoseChart(records: withGlucose);
        },
      ),
    );
  }
}

enum _ChartRange { ten, twenty, all }

class _GlucoseChart extends StatefulWidget {
  final List<HealthRecord> records;
  const _GlucoseChart({required this.records});

  @override
  State<_GlucoseChart> createState() => _GlucoseChartState();
}

class _GlucoseChartState extends State<_GlucoseChart> {
  _ChartRange _range = _ChartRange.ten;

  static bool _isBeforeBreakfast(HealthRecord r) {
    final t = r.measurementTime.trim().toLowerCase();
    return t == 'before breakfast' ||
        t.contains('ayunas') ||
        t.contains('desayunar');
  }

  static bool _isAfterMeal(HealthRecord r) {
    final t = r.measurementTime.trim().toLowerCase();
    return t == 'after lunch' ||
        t == 'after breakfast' ||
        t == 'after dinner' ||
        t.startsWith('after') ||
        t.contains('después') ||
        t.contains('despues') ||
        t.contains('post');
  }

  DateTime _normalizeDate(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  Map<DateTime, List<HealthRecord>> _groupRecordsByDay(
    List<HealthRecord> records,
  ) {
    final map = <DateTime, List<HealthRecord>>{};
    for (final r in records) {
      final day = _normalizeDate(r.date);
      map.putIfAbsent(day, () => []).add(r);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final fastingColor = colorScheme.primary;
    final postMealColor = Colors.orange.shade700;

    final grouped = _groupRecordsByDay(widget.records);
    final allDays = grouped.keys.toList()..sort();

    // Determine days to display based on range selector
    final count = _range == _ChartRange.ten
        ? 10
        : (_range == _ChartRange.twenty ? 20 : allDays.length);
    final displayedDays = allDays.length <= count
        ? allDays
        : allDays.sublist(allDays.length - count);

    final fastingSpots = <FlSpot>[];
    final postMealSpots = <FlSpot>[];
    final fastingRecordsMap = <int, HealthRecord>{};
    final postMealRecordsMap = <int, HealthRecord>{};

    for (var i = 0; i < displayedDays.length; i++) {
      final day = displayedDays[i];
      final dayRecords = grouped[day]!;

      final fastingRecord = dayRecords.where(_isBeforeBreakfast).lastOrNull;
      if (fastingRecord != null && fastingRecord.glucoseDouble != null) {
        fastingSpots.add(FlSpot(i.toDouble(), fastingRecord.glucoseDouble!));
        fastingRecordsMap[i] = fastingRecord;
      }

      final postMealRecord = dayRecords.where(_isAfterMeal).lastOrNull;
      if (postMealRecord != null && postMealRecord.glucoseDouble != null) {
        postMealSpots.add(FlSpot(i.toDouble(), postMealRecord.glucoseDouble!));
        postMealRecordsMap[i] = postMealRecord;
      }
    }

    // Fallback if records do not fit either category (e.g. generic readings)
    final fallbackSpots = <FlSpot>[];
    if (fastingSpots.isEmpty && postMealSpots.isEmpty) {
      for (var i = 0; i < displayedDays.length; i++) {
        final day = displayedDays[i];
        final dayRecords = grouped[day]!;
        final record = dayRecords.last;
        if (record.glucoseDouble != null) {
          fallbackSpots.add(FlSpot(i.toDouble(), record.glucoseDouble!));
          fastingRecordsMap[i] = record;
        }
      }
    }

    final allYValues = [
      ...fastingSpots.map((s) => s.y),
      ...postMealSpots.map((s) => s.y),
      ...fallbackSpots.map((s) => s.y),
    ];

    final double minY;
    final double maxY;
    if (allYValues.isNotEmpty) {
      final minVal = allYValues.reduce((a, b) => a < b ? a : b);
      final maxVal = allYValues.reduce((a, b) => a > b ? a : b);
      minY = minVal < 70 ? (((minVal - 15) / 20).floor() * 20.0).clamp(40.0, 60.0) : 60.0;
      final calculatedMax = ((maxVal + 15) / 20).ceil() * 20.0;
      maxY = calculatedMax < 160.0 ? 160.0 : calculatedMax;
    } else {
      minY = 60.0;
      maxY = 160.0;
    }

    final lineBars = <LineChartBarData>[];

    if (fastingSpots.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: fastingSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          color: fastingColor,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 3.5,
              color: fastingColor,
              strokeColor: colorScheme.surface,
              strokeWidth: 1.5,
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    if (postMealSpots.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: postMealSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          color: postMealColor,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 3.5,
              color: postMealColor,
              strokeColor: colorScheme.surface,
              strokeWidth: 1.5,
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    if (lineBars.isEmpty && fallbackSpots.isNotEmpty) {
      lineBars.add(
        LineChartBarData(
          spots: fallbackSpots,
          isCurved: true,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          color: fastingColor,
          barWidth: 2.5,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 3.5,
              color: fastingColor,
              strokeColor: colorScheme.surface,
              strokeWidth: 1.5,
            ),
          ),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LegendDot(color: fastingColor),
                      const SizedBox(width: 4),
                      const Text(
                        'Antes desayuno',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LegendDot(color: postMealColor),
                      const SizedBox(width: 4),
                      const Text(
                        'Después comer',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              _RangeSelector(
                selected: _range,
                onChanged: (r) => setState(() => _range = r),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _LegendDash(color: Colors.green.shade400),
              const SizedBox(width: 4),
              const Text('70–100 (Ayunas)', style: TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(width: 12),
              _LegendDash(color: Colors.orange.shade300),
              const SizedBox(width: 4),
              const Text('<140 (Post)', style: TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    strokeWidth: 0.5,
                  ),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border(
                    bottom: BorderSide(color: colorScheme.outline),
                    left: BorderSide(color: colorScheme.outline),
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: (displayedDays.length / 5).ceilToDouble().clamp(1, 999),
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= displayedDays.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('MM/dd').format(displayedDays[idx]),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 70,
                      color: Colors.green.shade400.withValues(alpha: 0.7),
                      strokeWidth: 1,
                      dashArray: [6, 4],
                    ),
                    HorizontalLine(
                      y: 100,
                      color: Colors.green.shade400.withValues(alpha: 0.7),
                      strokeWidth: 1,
                      dashArray: [6, 4],
                    ),
                    HorizontalLine(
                      y: 140,
                      color: Colors.orange.shade300.withValues(alpha: 0.7),
                      strokeWidth: 1,
                      dashArray: [4, 6],
                    ),
                  ],
                ),
                lineBarsData: lineBars,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final dayIndex = s.x.toInt();
                        final isFastingBar = lineBars.length > 1 && s.barIndex == 0;
                        final record = isFastingBar
                            ? fastingRecordsMap[dayIndex]
                            : (postMealRecordsMap[dayIndex] ?? fastingRecordsMap[dayIndex]);

                        final label = record?.measurementTime ??
                            (isFastingBar ? 'Antes de desayunar' : 'Después de comer');
                        final timeStr = record != null
                            ? DateFormat('MM/dd HH:mm').format(record.date)
                            : '';

                        return LineTooltipItem(
                          '${s.y.toStringAsFixed(1)} mg/dL\n$label\n$timeStr',
                          TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: s.barIndex == 0 && fastingSpots.isNotEmpty
                                ? fastingColor
                                : postMealColor,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${displayedDays.length} días',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Wrap(
                spacing: 12,
                children: [
                  if (fastingSpots.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LegendDot(color: fastingColor, size: 8),
                        const SizedBox(width: 4),
                        Text(
                          'Prom. Ayunas: ${(fastingSpots.map((s) => s.y).reduce((a, b) => a + b) / fastingSpots.length).toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (postMealSpots.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _LegendDot(color: postMealColor, size: 8),
                        const SizedBox(width: 4),
                        Text(
                          'Prom. Post: ${(postMealSpots.map((s) => s.y).reduce((a, b) => a + b) / postMealSpots.length).toStringAsFixed(1)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final _ChartRange selected;
  final ValueChanged<_ChartRange> onChanged;

  const _RangeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RangeButton(
          label: '10d',
          active: selected == _ChartRange.ten,
          onTap: () => onChanged(_ChartRange.ten),
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 4),
        _RangeButton(
          label: '20d',
          active: selected == _ChartRange.twenty,
          onTap: () => onChanged(_ChartRange.twenty),
          colorScheme: colorScheme,
        ),
        const SizedBox(width: 4),
        _RangeButton(
          label: 'All',
          active: selected == _ChartRange.all,
          onTap: () => onChanged(_ChartRange.all),
          colorScheme: colorScheme,
        ),
      ],
    );
  }
}

class _RangeButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _RangeButton({
    required this.label,
    required this.active,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? colorScheme.primary : colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final double size;
  const _LegendDot({required this.color, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _LegendDash extends StatelessWidget {
  final Color color;
  const _LegendDash({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 2.5,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}
