import 'package:flutter_test/flutter_test.dart';
import 'package:health_track/models/health_record.dart';

void main() {
  test('HealthRecord toSheetRow produces correct column order', () {
    final record = HealthRecord(
      date: DateTime(2026, 3, 19, 8, 30),
      systolic: '120',
      diastolic: '80',
      heartRate: '72',
      glucoseLevel: '95',
      measurementTime: 'Before Breakfast',
      notes: 'Test note',
    );

    final row = record.toSheetRow();
    expect(row[0], '03/19/2026');
    expect(row[1], '08:30');
    expect(row[2], '120');
    expect(row[3], '80');
    expect(row[4], '72');
    expect(row[5], '95');
    expect(row[6], 'Before Breakfast');
    expect(row[7], 'Test note');
  });
}
