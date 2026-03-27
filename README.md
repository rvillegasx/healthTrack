# HealthTrack

Personal iOS app for tracking glucose and blood pressure via Google Sheets.
Not published to the App Store — installed directly via Xcode.

## Features

- View all health records from Google Sheets (oldest to newest, auto-scrolls to latest)
- Add new records (blood pressure, heart rate, glucose, measurement time, notes)
- Delete records with swipe-left → confirmation dialog
- Glucose chart with normal range reference lines (70–100 mg/dL)
- Face ID / passcode lock screen

---

## Prerequisites

- macOS with Xcode installed
- Flutter SDK (>= 3.41.5)
- iPhone connected via USB (for direct install) or use Simulator
- Google Cloud account with a Service Account

---

## First-Time Setup

### 1. Clone the repo

```bash
git clone <your-repo-url>
cd healthTrack
```

### 2. Create your `.env` file

Copy the example and fill in your Spreadsheet ID:

```bash
cp .env.example .env
```

Edit `.env`:
```
SPREADSHEET_ID=10B0OjvLVZeg9epDL3G1AexGAxx7sfLU6lMJaDLafP3A
SHEET_NAME=Sheet1
```

> The `.env` file is gitignored. Never commit it.

### 3. Set up Google Cloud Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project (or use an existing one)
3. Enable the **Google Sheets API**:
   - APIs & Services > Library > search "Google Sheets API" > Enable
4. Create a Service Account:
   - APIs & Services > Credentials > Create Credentials > Service Account
   - Name it (e.g., `healthtrack-sheets`)
   - Skip optional role/user steps
5. Generate a JSON key:
   - Click on the service account > Keys tab > Add Key > Create new key > JSON
   - Download the `.json` file
6. Place the JSON file at:
   ```
   assets/credentials/service_account.json
   ```
   > This file is gitignored. Never commit it.
7. **Share your Google Spreadsheet** with the service account email:
   - Open the service account JSON — find `"client_email"`
   - Open your Google Spreadsheet > Share > paste that email > Editor access

### 4. Install Flutter dependencies

```bash
flutter pub get
```

---

## Running the App

### Debug mode (development)

Conecta el iPhone por USB y corre:

```bash
# Ver dispositivos disponibles
flutter devices

# Correr en debug en tu iPhone (obtén el DEVICE_ID del comando anterior)
flutter run -d <DEVICE_ID>
```

El modo debug incluye hot reload (`r`), hot restart (`R`), y el banner de debug en la esquina.
Los logs de la app se imprimen en la terminal en tiempo real.

Para ver solo los logs del dispositivo sin correr desde Flutter:

```bash
flutter logs -d <DEVICE_ID>
```

#### Alternativa — Xcode

1. Abre el proyecto:
   ```bash
   open ios/Runner.xcworkspace
   ```
2. Selecciona tu iPhone como target (barra superior)
3. Configura firma:
   - Click en **Runner** en el navegador del proyecto
   - Tab **Signing & Capabilities**
   - Activa **Automatically manage signing**
   - Selecciona tu **Team** (tu Apple ID — cuenta gratuita funciona)
   - Cambia **Bundle Identifier** a algo único, ej. `com.tunombre.healthtrack`
4. Presiona **Run** (▶)

> En la primera instalación debes confiar en el certificado desde el iPhone:
> Ajustes > General > VPN y gestión de dispositivos > tu Apple ID > Confiar

---

### Release (deploy a iPhone sin cable)

El build de release elimina el banner de debug, está optimizado y se puede usar sin tener la Mac conectada.

```bash
# 1. Compilar el build de release
flutter build ios --release

# 2. Instalar directamente en el iPhone conectado por USB
flutter install -d <DEVICE_ID>
```

O desde Xcode después del build:

```bash
open ios/Runner.xcworkspace
```

Selecciona tu iPhone como target y presiona **Run** (▶). Xcode instala el `.app` compilado en release.

> El certificado de desarrollador gratuito expira cada 7 días. Cuando la app deje de abrir,
> repite el paso 2 (`flutter build ios --release && flutter install -d <DEVICE_ID>`).

---

## Project Structure

```
lib/
├── main.dart                   # App entry point, loads .env
├── config/
│   └── env.dart                # Reads environment variables
├── models/
│   └── health_record.dart      # Data model + sheet row serialization
├── services/
│   ├── sheets_service.dart     # Google Sheets API (read + append + delete)
│   └── auth_service.dart       # Face ID / biometric authentication
├── providers/
│   └── records_provider.dart   # Riverpod state management
├── screens/
│   ├── lock_screen.dart        # Face ID gate
│   ├── home_screen.dart        # Bottom tab navigator
│   ├── records_screen.dart     # Records list
│   ├── add_record_screen.dart  # Add new record form
│   └── chart_screen.dart       # Glucose line chart
└── widgets/
    └── record_card.dart        # Individual record display (with swipe-to-delete)
assets/
└── credentials/
    └── service_account.json    # GITIGNORED — place manually
.env                            # GITIGNORED — place manually
.env.example                    # Template (committed to repo)
```

---

## Spreadsheet Format

Sheet: `Sheet1` | Data starts at row 3 (rows 1–2 are headers)

| Col | Field | Example |
|-----|-------|---------|
| A | Date | 2026/03/19 |
| B | Time | 08:30 |
| C | Systolic (mmHg) | 120 |
| D | Diastolic (mmHg) | 80 |
| E | Heart Rate (bpm) | 72 |
| F | Glucose Level (mg/dL) | 95 |
| G | Measurement Time | Before Breakfast |
| H | Notes | (optional) |

---

## Security Notes

- `service_account.json` and `.env` are in `.gitignore` — never commit them
- Face ID / passcode required to open the app
- The Service Account only has access to the specific spreadsheet you share with it
- No user data is stored locally beyond what's in Google Sheets
