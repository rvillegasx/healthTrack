import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:health_track/models/health_record.dart';

enum HealthKitStatus { success, failed, noData }

class HealthKitService {
  static final _health = Health();

  static const _writeTypes = [
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_GLUCOSE,
  ];

  Future<bool> _requestPermissions() async {
    try {
      final permissions = _writeTypes.map((_) => HealthDataAccess.WRITE).toList();
      return await _health.requestAuthorization(
        _writeTypes,
        permissions: permissions,
      );
    } catch (e) {
      debugPrint('[HealthKit] requestAuthorization threw: $e');
      return false;
    }
  }

  /// Writes all non-null health values in [record] to Apple Health.
  /// Never throws — failures are reflected in the returned [HealthKitStatus].
  Future<HealthKitStatus> writeRecord(HealthRecord record) async {
    final hasBP = record.systolicInt != null && record.diastolicInt != null;
    final hasHR = record.heartRateInt != null;
    final hasGlucose = record.glucoseDouble != null;

    if (!hasBP && !hasHR && !hasGlucose) return HealthKitStatus.noData;

    try {
      final granted = await _requestPermissions();
      debugPrint('[HealthKit] requestAuthorization granted=$granted');
      if (!granted) return HealthKitStatus.failed;

      final timestamp = record.date;
      var allSucceeded = true;

      if (hasBP) {
        final bpOk = await _health.writeBloodPressure(
          systolic: record.systolicInt!,
          diastolic: record.diastolicInt!,
          startTime: timestamp,
        );
        debugPrint('[HealthKit] writeBloodPressure '
            '${record.systolicInt}/${record.diastolicInt} -> $bpOk');
        if (!bpOk) allSucceeded = false;
      }

      if (hasHR) {
        final hrOk = await _health.writeHealthData(
          value: record.heartRateInt!.toDouble(),
          type: HealthDataType.HEART_RATE,
          startTime: timestamp,
          unit: HealthDataUnit.BEATS_PER_MINUTE,
        );
        debugPrint('[HealthKit] writeHeartRate ${record.heartRateInt} -> $hrOk');
        if (!hrOk) allSucceeded = false;
      }

      if (hasGlucose) {
        final glucoseOk = await _health.writeHealthData(
          value: record.glucoseDouble!,
          type: HealthDataType.BLOOD_GLUCOSE,
          startTime: timestamp,
          unit: HealthDataUnit.MILLIGRAM_PER_DECILITER,
        );
        debugPrint('[HealthKit] writeGlucose ${record.glucoseDouble} -> $glucoseOk');
        if (!glucoseOk) allSucceeded = false;
      }

      return allSucceeded ? HealthKitStatus.success : HealthKitStatus.failed;
    } catch (e, st) {
      debugPrint('[HealthKit] writeRecord threw: $e\n$st');
      return HealthKitStatus.failed;
    }
  }
}
