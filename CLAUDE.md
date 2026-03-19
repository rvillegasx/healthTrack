# CLAUDE.md

Guidance for Claude Code when working with this repository.

## Project

Personal iOS Flutter app — glucose and blood pressure tracking via Google Sheets.
Not on the App Store. Installed directly via Xcode.

## Commands

```bash
flutter pub get          # Install dependencies
flutter run              # Run on connected device / simulator
flutter build ios        # Release build
flutter analyze          # Lint
flutter test             # Tests
```

Open Xcode: `open ios/Runner.xcworkspace`

## Architecture

- **State**: Riverpod (`flutter_riverpod`) — providers in `lib/providers/`
- **Google Sheets**: Service Account auth via `googleapis` + `googleapis_auth`
- **Auth**: Face ID via `local_auth`
- **Charts**: `fl_chart`
- **Env**: `flutter_dotenv` loads `.env` bundled as asset

## Key Files

| File | Purpose |
|------|---------|
| `lib/main.dart` | Entry point, loads .env, wraps with ProviderScope |
| `lib/config/env.dart` | Reads SPREADSHEET_ID / SHEET_NAME from .env |
| `lib/models/health_record.dart` | Data model + sheet row serialization |
| `lib/services/sheets_service.dart` | Reads/appends/deletes Google Sheets rows |
| `lib/services/auth_service.dart` | Face ID wrapper |
| `lib/providers/records_provider.dart` | AsyncNotifier for records list |
| `assets/credentials/service_account.json` | GITIGNORED — place manually |
| `.env` | GITIGNORED — copy from `.env.example` |

## Secrets (never commit)

- `.env` — contains SPREADSHEET_ID
- `assets/credentials/service_account.json` — Google Service Account key

Both are in `.gitignore`. Use `.env.example` as the template.

## Spreadsheet

- Sheet: `Sheet1` | Data from row 3 (rows 1–2 are headers)
- Columns: Date | Time | Systolic | Diastolic | Heart Rate | Glucose | Measurement Time | Notes

## Conventions

- All fields in `HealthRecord` are nullable except `date` and `measurementTime`
- Records are displayed oldest-first, newest at bottom; list auto-scrolls to last item on load
- Date format written to sheet: `YYYY/MM/DD`, time: `HH:MM`
- Parser supports both `YYYY/MM/DD` (new) and `MM/DD/YYYY` (legacy records)
- `HealthRecord.rowIndex` (0-based) is set at fetch time and used for deletion via `batchUpdate`
- After saving a new record, app navigates automatically to Records tab (`selectedTabProvider`)
- Delete requires swipe-left → red button → confirmation dialog
- UI language: English
