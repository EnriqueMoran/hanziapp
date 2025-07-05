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

## Running with Docker

You can build and run the app in a container using the provided `Dockerfile`.

```bash
# Build the Docker image
docker build -t hanziapp .

# Run the app exposing port 8080
docker run -p 8080:8080 hanziapp
```

The app will be available on [http://localhost:8080](http://localhost:8080).
