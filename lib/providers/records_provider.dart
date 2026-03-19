import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_track/models/health_record.dart';
import 'package:health_track/services/sheets_service.dart';

final sheetsServiceProvider = Provider<SheetsService>((_) => SheetsService());

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

  Future<void> addRecord(HealthRecord record) async {
    final service = ref.read(sheetsServiceProvider);
    await service.appendRecord(record);
    await refresh();
  }

  Future<void> deleteRecord(HealthRecord record) async {
    if (record.rowIndex == null) return;
    final service = ref.read(sheetsServiceProvider);
    await service.deleteRecord(record.rowIndex!);
    await refresh();
  }
}
