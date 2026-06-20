# CPI App

A Flutter mobile application for CPI (Consumer Price Index) data collection and management.

## Prerequisites

Before running this project, ensure you have the following installed on your system:

### 1. Flutter SDK

Install the Flutter SDK by following the official guide for your operating system:

- [Flutter Installation Guide](https://docs.flutter.dev/get-started/install)

Make sure to also complete the platform-specific setup (Android Studio, Xcode, etc.) as described in the guide.

### 2. Android Studio / Xcode

- **Android**: Install [Android Studio](https://developer.android.com/studio) with the Android SDK and an Android emulator or connect a physical device with USB debugging enabled.
- **iOS** (macOS only): Install [Xcode](https://developer.apple.com/xcode/) from the Mac App Store with the iOS Simulator.

### 3. FVM (Flutter Version Management)

This project uses **FVM** to manage the Flutter SDK version. FVM ensures all developers use the same Flutter version (`3.0.0`) as configured in the project.

Install FVM globally:

```bash
dart pub global activate fvm
```

Then install Flutter version `3.0.0` (the version this project requires):

```bash
fvm install 3.0.0
```

Set it as the active version for this project:

```bash
fvm use 3.0.0
```

> **Important**: Use `fvm flutter` instead of `flutter` for all Flutter commands to ensure the correct SDK version is used.

## Configuration

### API Base URL

Before running or building the application, you **must** update the API base URL to point to your running API instance.

Open `lib/models/globals.dart` and edit the `apiBaseUrl` variable:

```dart
static const apiBaseUrl = 'http://<YOUR_API_HOST>:<PORT>';
```

Replace `<YOUR_API_HOST>:<PORT>` with the address of the server running the CPI API (e.g., `http://192.168.1.100:5000` for a device on the local network, or a production URL).

> **Note**: When running on a physical device or emulator, `127.0.0.1` will not work as it refers to the device itself, not your development machine. Use your machine's local network IP address instead. For Android emulators specifically, `10.0.2.2` maps to the host machine's `127.0.0.1`.

## Running the Project

### 1. Install Dependencies

```bash
fvm flutter pub get
```

### 2. Run on a Connected Device or Emulator

```bash
fvm flutter run
```

To list available devices:

```bash
fvm flutter devices
```

To run on a specific device:

```bash
fvm flutter run -d <device_id>
```

## Building the Application

### Android APK

```bash
fvm flutter build apk --release
```

The built APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

### Android App Bundle

```bash
fvm flutter build appbundle --release
```

### iOS (macOS only)

```bash
fvm flutter build ios --release
```

## Troubleshooting

- Run `fvm flutter doctor` to diagnose environment issues.
- Ensure your API server is running and accessible from the device/emulator before launching the app.
- If you encounter dependency issues, try `fvm flutter pub get` again or delete the `pubspec.lock` file and re-fetch.
