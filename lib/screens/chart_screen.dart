import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_track/providers/records_provider.dart';
import 'package:health_track/models/health_record.dart';
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

  List<HealthRecord> get _filtered {
    if (_range == _ChartRange.all) return widget.records;
    final count = _range == _ChartRange.ten ? 10 : 20;
    if (widget.records.length <= count) return widget.records;
    return widget.records.sublist(widget.records.length - count);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final records = _filtered;

    final spots = records.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.glucoseDouble!);
    }).toList();

    final minY =
        (records.map((r) => r.glucoseDouble!).reduce((a, b) => a < b ? a : b) -
                20)
            .clamp(0.0, 999.0);
    final maxY =
        records.map((r) => r.glucoseDouble!).reduce((a, b) => a > b ? a : b) +
            20;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendDot(color: colorScheme.primary),
                  const SizedBox(width: 4),
                  const Text('Glucose', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 12),
                  _LegendDot(color: Colors.green.shade300),
                  const SizedBox(width: 4),
                  const Text('70–100 mg/dL', style: TextStyle(fontSize: 12)),
                ],
              ),
              _RangeSelector(
                selected: _range,
                onChanged: (r) => setState(() => _range = r),
              ),
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
                    color: colorScheme.outlineVariant,
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
                      interval:
                          (records.length / 5).ceilToDouble().clamp(1, 999),
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= records.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            DateFormat('MM/dd').format(records[idx].date),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 70,
                      color: Colors.green.shade300,
                      strokeWidth: 1,
                      dashArray: [6, 4],
                    ),
                    HorizontalLine(
                      y: 100,
                      color: Colors.green.shade300,
                      strokeWidth: 1,
                      dashArray: [6, 4],
                    ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                        radius: 3.5,
                        color: colorScheme.primary,
                        strokeColor: colorScheme.surface,
                        strokeWidth: 1.5,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.08),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((s) {
                        final record = records[s.spotIndex];
                        return LineTooltipItem(
                          '${s.y.toStringAsFixed(1)} mg/dL\n'
                          '${DateFormat('MM/dd HH:mm').format(record.date)}\n'
                          '${record.measurementTime}',
                          const TextStyle(fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${records.length} readings',
            style: Theme.of(context).textTheme.bodySmall,
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
        _RangeButton(label: '10r', active: selected == _ChartRange.ten, onTap: () => onChanged(_ChartRange.ten), colorScheme: colorScheme),
        const SizedBox(width: 4),
        _RangeButton(label: '20r', active: selected == _ChartRange.twenty, onTap: () => onChanged(_ChartRange.twenty), colorScheme: colorScheme),
        const SizedBox(width: 4),
        _RangeButton(label: 'All', active: selected == _ChartRange.all, onTap: () => onChanged(_ChartRange.all), colorScheme: colorScheme),
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
  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
