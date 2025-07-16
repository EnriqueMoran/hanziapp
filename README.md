# HanziApp

A Flutter application to review Chinese characters (hanzi). The home screen exposes buttons that navigate to placeholder screens for managing and practicing character groups and batches.

## Getting Started

1. [Install Flutter](https://docs.flutter.dev/get-started/install) on your machine.
2. From this repository root run:
   ```bash
   flutter pub get
   flutter run -d chrome   # or choose your connected device
   ```

The app targets mobile and web platforms.

## Environment Setup

Make sure the Flutter SDK is available in your `PATH` before trying to run the
app. One way to obtain Flutter is:

```bash
git clone https://github.com/flutter/flutter.git -b stable $HOME/flutter
export PATH="$HOME/flutter/bin:$PATH"
flutter --version
```

With Flutter available run the following commands from the repository root:

```bash
flutter pub get
flutter run -d chrome  # or select another connected device
```

The backend API URL and authentication token used by the Flutter code are
defined in `lib/api/api_config.dart`. Update this file when deploying the backend
to a different host.


## Backend API

A simple Flask service under `backend/` exposes the characters stored in a SQLite database. Build and run it with Docker Compose:

```bash
docker-compose up --build
```

The container stores `hanzi.db` inside a named Docker volume (`hanzi_db`) so
the data persists across restarts.

The database file is not kept in version control. To create it from `data.json`, run:

```bash
./backend/create_db.sh
```

### Backup and restore

Use the helper scripts in `backend/` to export or import all characters as JSON:

```bash
# Export all records to backup.json
docker-compose exec backend python export_data.py backup.json

# Import records from a JSON file
docker-compose exec backend python import_data.py backup.json
```

### Importing legacy data

For character lists in the older JSON format (one object per line with an
`_id` field) use `import_legacy_json.py` to load them:

```bash
docker-compose exec backend python import_legacy_json.py old_data.json
```

The script separates the example sentences from the `other` text and preserves
the original order based on each record's OID.

The service will be available at `http://localhost:5000` and is protected by a
simple token based authentication. Requests must include the `X-API-Token`
header using the same value configured in `docker-compose.yml` via
`API_TOKEN`.

## Android Build

An `android/` folder is now included so the project can be compiled for
Android devices. After fetching the dependencies you can build the APK with:

```bash
flutter build apk --release
```

The app relies on Google's ML Kit Digital Ink Recognition via the
`google_mlkit_digital_ink_recognition` package to process handwritten
characters.
