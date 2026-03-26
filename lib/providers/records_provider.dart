import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_track/models/health_record.dart';
import 'package:health_track/services/health_kit_service.dart';
import 'package:health_track/services/sheets_service.dart';

final sheetsServiceProvider = Provider<SheetsService>((_) => SheetsService());
final healthKitServiceProvider = Provider<HealthKitService>((_) => HealthKitService());

final selectedTabProvider = StateProvider<int>((_) => 0);

final recordsProvider =
    AsyncNotifierProvider<RecordsNotifier, List<HealthRecord>>(
  RecordsNotifier.new,
);

class RecordsNotifier extends AsyncNotifier<List<HealthRecord>> {
  @override
  Future<List<HealthRecord>> build() => _fetch();

  Future<List<HealthRecord>> _fetch() {
    final service = ref.read(sheetsServiceProvider);
    return service.fetchRecords();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<HealthKitStatus> addRecord(HealthRecord record) async {
    final sheetsService = ref.read(sheetsServiceProvider);
    await sheetsService.appendRecord(record);

    final hkService = ref.read(healthKitServiceProvider);
    final hkStatus = await hkService.writeRecord(record);

    await refresh();
    return hkStatus;
  }

  Future<void> deleteRecord(HealthRecord record) async {
    if (record.rowIndex == null) return;
    final service = ref.read(sheetsServiceProvider);
    await service.deleteRecord(record.rowIndex!);
    await refresh();
  }
}
