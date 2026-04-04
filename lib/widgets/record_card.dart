import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:health_track/models/health_record.dart';
import 'package:intl/intl.dart';

class RecordCard extends StatelessWidget {
  final HealthRecord record;
  final VoidCallback? onDelete;
  const RecordCard({super.key, required this.record, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Slidable(
      key: ValueKey(record.rowIndex),
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.22,
        children: [
          SlidableAction(
            onPressed: (_) => onDelete?.call(),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete',
            borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
          ),
        ],
      ),
      child: Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & measurement time
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  DateFormat('EEE, MMM d, yyyy  HH:mm').format(record.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Chip(
                  label: Text(record.measurementTime),
                  padding: EdgeInsets.zero,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 6),
                  side: BorderSide.none,
                  backgroundColor: colorScheme.secondaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Metrics row
            Row(
              children: [
                if (record.systolicInt != null && record.diastolicInt != null)
                  _Metric(
                    icon: Icons.favorite_border,
                    label: 'BP',
                    value:
                        '${record.systolicInt}/${record.diastolicInt}',
                    unit: 'mmHg',
                    color: Colors.red.shade400,
                  ),
                if (record.heartRateInt != null) ...[
                  const SizedBox(width: 16),
                  _Metric(
                    icon: Icons.monitor_heart_outlined,
                    label: 'HR',
                    value: '${record.heartRateInt}',
                    unit: 'bpm',
                    color: Colors.orange.shade400,
                  ),
                ],
                if (record.glucoseDouble != null) ...[
                  const SizedBox(width: 16),
                  _Metric(
                    icon: Icons.water_drop_outlined,
                    label: 'Glucose',
                    value: record.glucoseLevel!,
                    unit: 'mg/dL',
                    color: colorScheme.primary,
                  ),
                ],
              ],
            ),
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                record.notes!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colorScheme.outline),
              ),
            ],
          ],
        ),
      ),
    ));
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              TextSpan(
                text: ' $unit',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
