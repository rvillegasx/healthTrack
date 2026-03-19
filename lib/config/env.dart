import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get spreadsheetId =>
      dotenv.env['SPREADSHEET_ID'] ?? (throw Exception('SPREADSHEET_ID not set in .env'));

  static String get sheetName => dotenv.env['SHEET_NAME'] ?? 'Sheet1';
}
