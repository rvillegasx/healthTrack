# HealthTrack — Work Plan

Personal iOS app for tracking glucose and blood pressure connected to an existing Google Spreadsheet.

---

## Decisions & Architecture

| Decision | Choice | Reason |
|----------|--------|--------|
| Framework | Flutter | Cross-platform capable, good iOS support, personal preference |
| Google API auth | Service Account (JSON key) | No interactive OAuth flow needed for personal use |
| State management | Riverpod | Simple, testable, no boilerplate |
| Charts | fl_chart | Flexible, well-maintained Flutter charting library |
| Biometric auth | local_auth | Official Flutter plugin for Face ID / Touch ID |
| Env variables | flutter_dotenv | Loads `.env` file bundled as asset; key excluded from git |
| Deployment | Xcode direct install | No App Store required for personal use |
| UI pattern | Bottom tabs | Simple navigation for 3 screens |

---

## Spreadsheet Details

- **ID**: `10B0OjvLVZeg9epDL3G1AexGAxx7sfLU6lMJaDLafP3A`
- **Sheet**: `Sheet1`
- **Headers**: rows 1–2 (reserved)
- **Data starts**: row 3

| Column | Field | Notes |
|--------|-------|-------|
| A | Date | YYYY/MM/DD |
| B | Time | HH:MM |
| C | Systolic (mmHg) | Optional |
| D | Diastolic (mmHg) | Optional |
| E | Heart Rate (bpm) | Optional |
| F | Glucose Level (mg/dL) | Optional |
| G | Measurement Time | Default: "Before Breakfast" |
| H | Notes | Optional |

### Measurement Time Options
- Before Breakfast
- After Breakfast
- Before Lunch
- After Lunch
- Before Dinner
- After Dinner
- Bedtime

---

## Security Model

```
[secrets]                [committed to git]
.env                     .env.example (template, no values)
service_account.json     assets/credentials/.gitkeep (empty placeholder)
```

- Both secret files are in `.gitignore`
- Developer places them manually before each build
- Service Account email must be added as Editor on the Google Spreadsheet
- Face ID / passcode gates app access on device

---

## Phases

### Phase 1 — Setup (DONE)
- [x] Flutter project created (`flutter create . --platforms ios`)
- [x] `.gitignore` updated with credentials and .env exclusions
- [x] `pubspec.yaml` updated with all dependencies
- [x] `assets/credentials/` folder created
- [x] `.env.example` created
- [x] `Info.plist` updated with `NSFaceIDUsageDescription`

### Phase 2 — Core Implementation (DONE)
- [x] `lib/config/env.dart` — reads SPREADSHEET_ID and SHEET_NAME from .env
- [x] `lib/models/health_record.dart` — data model with sheet serialization
- [x] `lib/services/sheets_service.dart` — Google Sheets read + append
- [x] `lib/services/auth_service.dart` — Face ID wrapper
- [x] `lib/providers/records_provider.dart` — Riverpod async state

### Phase 3 — Screens (DONE)
- [x] `lib/screens/lock_screen.dart` — Face ID gate on app open
- [x] `lib/screens/home_screen.dart` — Bottom tab navigator
- [x] `lib/screens/records_screen.dart` — Paginated list, pull-to-refresh
- [x] `lib/screens/add_record_screen.dart` — Form with all fields
- [x] `lib/screens/chart_screen.dart` — Glucose line chart with reference lines
- [x] `lib/widgets/record_card.dart` — Individual record display widget

### Phase 4 — Deploy (DONE)
- [x] Place `service_account.json` in `assets/credentials/`
- [x] Create `.env` with real Spreadsheet ID
- [x] Run `flutter pub get`
- [x] Enable Developer Mode on iPhone
- [x] Configure signing in Xcode (Apple ID, Bundle ID)
- [x] Enable Google Sheets API in Google Cloud Console
- [x] Upgrade Flutter 3.19 → 3.41.5 (required for iOS 26)
- [x] Build & run on device

### Phase 5 — Post-launch Adjustments (DONE)
- [x] Auto-navigate to Records tab after saving a new record
- [x] App icon configured via `flutter_launcher_icons`
- [x] Swipe-to-delete with confirmation dialog (`flutter_slidable`)
- [x] Delete record via Google Sheets `batchUpdate` (DeleteDimensionRequest)
- [x] Date format changed to `YYYY/MM/DD`; parser supports legacy `MM/DD/YYYY`
- [x] Records ordered oldest-first, newest at bottom; auto-scroll to last on load

---

## Dependencies

```yaml
googleapis: ^12.0.0          # Google Sheets API client
googleapis_auth: ^1.4.0      # Service Account authentication
flutter_riverpod: ^2.4.9     # State management
fl_chart: ^0.65.0            # Line charts
local_auth: ^2.1.8           # Face ID / Touch ID
flutter_dotenv: ^5.1.0       # .env file loading
intl: ^0.19.0                # Date formatting
flutter_slidable: ^3.1.1     # Swipe actions on list items
flutter_launcher_icons: ^0.14.3  # App icon generation (dev)
```

---

## Google Cloud Setup Steps

1. Create project at console.cloud.google.com
2. Enable **Google Sheets API**
3. Create **Service Account** (APIs & Services > Credentials)
4. Generate **JSON key** for the service account
5. Place JSON at `assets/credentials/service_account.json`
6. Share the Google Spreadsheet with the `client_email` from the JSON (Editor role)

---

## Future Improvements (not in scope)

- Blood pressure chart
- Export / backup
- Reminders / notifications
- Statistics / averages per period
