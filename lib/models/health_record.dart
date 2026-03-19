class HealthRecord {
  final DateTime date;
  final String? systolic;
  final String? diastolic;
  final String? heartRate;
  final String? glucoseLevel;
  final String measurementTime;
  final String? notes;
  // 0-based row index in the spreadsheet (used for deletion)
  final int? rowIndex;

  const HealthRecord({
    required this.date,
    this.systolic,
    this.diastolic,
    this.heartRate,
    this.glucoseLevel,
    required this.measurementTime,
    this.notes,
    this.rowIndex,
  });

  double? get glucoseDouble =>
      glucoseLevel != null ? double.tryParse(glucoseLevel!) : null;

  int? get systolicInt => systolic != null ? int.tryParse(systolic!) : null;
  int? get diastolicInt => diastolic != null ? int.tryParse(diastolic!) : null;
  int? get heartRateInt => heartRate != null ? int.tryParse(heartRate!) : null;

  // Builds a row for Google Sheets in the same column order as the spreadsheet:
  // Date | Time | Systolic | Diastolic | Heart Rate | Glucose | Measurement Time | Notes
  List<Object?> toSheetRow() {
    final dateStr =
        '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    return [
      dateStr,
      timeStr,
      systolic ?? '',
      diastolic ?? '',
      heartRate ?? '',
      glucoseLevel ?? '',
      measurementTime,
      notes ?? '',
    ];
  }

  static HealthRecord fromSheetRow(List<Object?> row, {int? rowIndex}) {
    String cell(int i) => i < row.length ? (row[i]?.toString() ?? '') : '';

    // Parse date supporting both "YYYY/MM/DD" (new) and "MM/DD/YYYY" (legacy)
    DateTime parsedDate;
    try {
      final dateParts = cell(0).split('/');
      final timeParts = cell(1).split(':');
      final int year, month, day;
      if (dateParts[0].length == 4) {
        // YYYY/MM/DD
        year = int.parse(dateParts[0]);
        month = int.parse(dateParts[1]);
        day = int.parse(dateParts[2]);
      } else {
        // MM/DD/YYYY (legacy)
        month = int.parse(dateParts[0]);
        day = int.parse(dateParts[1]);
        year = int.parse(dateParts[2]);
      }
      parsedDate = DateTime(
        year, month, day,
        timeParts.isNotEmpty ? int.tryParse(timeParts[0]) ?? 0 : 0,
        timeParts.length > 1 ? int.tryParse(timeParts[1]) ?? 0 : 0,
      );
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return HealthRecord(
      date: parsedDate,
      systolic: cell(2).isEmpty ? null : cell(2),
      diastolic: cell(3).isEmpty ? null : cell(3),
      heartRate: cell(4).isEmpty ? null : cell(4),
      glucoseLevel: cell(5).isEmpty ? null : cell(5),
      measurementTime: cell(6).isEmpty ? 'Before Breakfast' : cell(6),
      notes: cell(7).isEmpty ? null : cell(7),
      rowIndex: rowIndex,
    );
  }
}
