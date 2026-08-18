# HealthTrack

Personal iOS app for tracking glucose and blood pressure via Google Sheets.
Not published to the App Store — installed directly via Xcode.

## Features

- View all health records from Google Sheets (oldest to newest, auto-scrolls to latest)
- Add new records (blood pressure, heart rate, glucose, measurement time, notes)
- Writes records to Apple Health (HealthKit) automatically on save
- Swipe-left actions: **Health** (manually re-push a record to Apple Health) and **Delete** (→ confirmation dialog)
- **Dual-curve Glucose Chart:**
  - Curve 1: **Antes de desayunar / Fasting** (Blue curve)
  - Curve 2: **Después de comer / Postprandial** (Orange curve)
  - Synchronized date timeline on the X-axis (`MM/dd`)
  - Clinical target reference lines: **70–100 mg/dL** (Ayunas) and **< 140 mg/dL** (Postprandial)
  - Independent average metrics (Avg Ayunas vs Avg Post) and range selector (`10d`, `20d`, `All`)
- Face ID / passcode lock screen

---

## Prerequisites

- macOS with Xcode installed
- Flutter SDK (>= 3.41.5)
- iPhone connected via USB (for direct install) or iOS Simulator
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

### Debug mode (Simulator o Dispositivo de Desarrollo)

#### En Simulador iOS:
```bash
# Abrir el simulador y listar dispositivos
open -a Simulator
flutter devices

# Correr en el simulador
flutter run -d <SIMULATOR_ID>
```

#### En iPhone físico por USB:
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

## Gestión de Permisos en iPhone (HealthKit y Face ID)

### ¿Qué sucede con los permisos al actualizar o reinstalar la app?

| Situación | ¿Se pierden los permisos? | Acción requerida |
| :--- | :--- | :--- |
| **Actualización normal / Nueva versión** (sobreescribir con mismo Bundle ID) | **NO** | iOS preserva automáticamente todos los permisos concedidos. |
| **Reinstalación limpia** (borrar la app y reinstalar) | **SÍ** | Otorgar permisos en el primer inicio o activarlos en Ajustes. |
| **Renovación de certificado gratuito (7 días)** | **NO** (si no borras la app antes) | Solo compilar y reinstalar con `flutter install`. |

### Dónde verificar y reactivar los permisos en el iPhone

#### 1. Apple Health (HealthKit) — Glucosa, Presión Arterial y Pulso
> **Importante:** En iOS los permisos de HealthKit se conceden por tipo de dato y fallan **en silencio** (la función `requestAuthorization` retorna `true` aunque el interruptor esté apagado). Si alguna métrica no se guarda en Apple Health, verifica que todos los interruptores estén encendidos:

- **Ruta desde Ajustes (Settings):**
  1. Ve a **Ajustes (Settings)** en el iPhone.
  2. Entra a **Salud (Health)** ▸ **Acceso a datos y dispositivos (Data Access & Devices)**.
  3. Selecciona **HealthTrack**.
  4. Activa todos los interruptores de escritura:
     - **Glucosa en sangre** (*Blood Glucose*)
     - **Presión arterial sistólica** (*Blood Pressure Systolic*)
     - **Presión arterial diastólica** (*Blood Pressure Diastolic*)
     - **Frecuencia cardíaca** (*Heart Rate*)
- **Ruta alternativa (Desde la app Salud):**
  1. Abre la app **Salud**.
  2. Toca tu **foto de perfil** (esquina superior derecha).
  3. Ve a **Apps** ▸ **HealthTrack** y activa todas las categorías.

> Puedes usar la acción de deslizar a la izquierda (**Health**) en cualquier registro para reintentar la sincronización manual con Apple Health.

#### 2. Face ID / Desbloqueo Biométrico
- Si la app no pide Face ID o fue denegado inicialmente:
  1. Ve a **Ajustes (Settings)** en el iPhone.
  2. Busca **HealthTrack** en la lista de aplicaciones instaladas.
  3. Activa el interruptor **Face ID**.
  4. *(Alternativa)*: **Ajustes** ▸ **Face ID y código** ▸ **Otras apps** ▸ Activar **HealthTrack**.

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
│   ├── health_kit_service.dart # Apple Health (HealthKit) writes
│   └── auth_service.dart       # Face ID / biometric authentication
├── providers/
│   └── records_provider.dart   # Riverpod state management
├── screens/
│   ├── lock_screen.dart        # Face ID gate
│   ├── home_screen.dart        # Bottom tab navigator
│   ├── records_screen.dart     # Records list
│   ├── add_record_screen.dart  # Add new record form
│   └── chart_screen.dart       # Dual-curve Glucose line chart
└── widgets/
    └── record_card.dart        # Individual record display (swipe: Health / Delete)
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
