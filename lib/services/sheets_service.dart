import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis/sheets/v4.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:health_track/config/env.dart';
import 'package:health_track/models/health_record.dart';

const _scopes = [SheetsApi.spreadsheetsScope];

class SheetsService {
  SheetsApi? _sheetsApi;

  Future<SheetsApi> _getApi() async {
    if (_sheetsApi != null) return _sheetsApi!;

    final jsonString =
        await rootBundle.loadString('assets/credentials/service_account.json');
    final credentials = ServiceAccountCredentials.fromJson(
      json.decode(jsonString) as Map<String, dynamic>,
    );

    final client = await clientViaServiceAccount(credentials, _scopes);
    _sheetsApi = SheetsApi(client);
    return _sheetsApi!;
  }

  // Reads all records from Sheet1 starting at row 3 (rows 1-2 are headers).
  Future<List<HealthRecord>> fetchRecords() async {
    final api = await _getApi();
    final range = '${Env.sheetName}!A3:H';
    final response = await api.spreadsheets.values.get(
      Env.spreadsheetId,
      range,
    );

    final rows = response.values ?? [];
    // Data starts at sheet row 3 → 0-based API index 2
    const firstRowIndex = 2;
    final records = rows
        .asMap()
        .entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => HealthRecord.fromSheetRow(
              e.value,
              rowIndex: firstRowIndex + e.key,
            ))
        .toList();
    return records; // Oldest first, newest at bottom
  }

  // Deletes a row by its 0-based index in the spreadsheet.
  Future<void> deleteRecord(int rowIndex) async {
    final api = await _getApi();

    // Get the sheetId (numeric) for Sheet1
    final spreadsheet = await api.spreadsheets.get(Env.spreadsheetId);
    final sheetId = spreadsheet.sheets
        ?.firstWhere(
          (s) => s.properties?.title == Env.sheetName,
          orElse: () => spreadsheet.sheets!.first,
        )
        .properties
        ?.sheetId;

    await api.spreadsheets.batchUpdate(
      BatchUpdateSpreadsheetRequest(
        requests: [
          Request(
            deleteDimension: DeleteDimensionRequest(
              range: DimensionRange(
                sheetId: sheetId,
                dimension: 'ROWS',
                startIndex: rowIndex,
                endIndex: rowIndex + 1,
              ),
            ),
          ),
        ],
      ),
      Env.spreadsheetId,
    );
  }

  // Appends a new record as the next row after existing data.
  Future<void> appendRecord(HealthRecord record) async {
    final api = await _getApi();
    final range = '${Env.sheetName}!A:H';

    await api.spreadsheets.values.append(
      ValueRange(values: [record.toSheetRow()]),
      Env.spreadsheetId,
      range,
      valueInputOption: 'USER_ENTERED',
      insertDataOption: 'INSERT_ROWS',
    );
  }
}
