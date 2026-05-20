# Flutter setup

## Requirements

- Flutter installed locally
- Android SDK and emulator or Android device

## Commands

```powershell
cd mobile
F:\apps\android\flutter\bin\flutter.bat pub get
F:\apps\android\flutter\bin\flutter.bat run
```

## Android package name

- Package name: `com.dhebe.aileadagent`
- App label: `Dhebe AI Lead Agent`

## API configuration

The app uses this base URL by default:

```text
https://dhebe.com/api
```

If you later move the API, update:

- [app_constants.dart](/f:/apps/android/dhebe-ai-lead-agent/mobile/lib/core/constants/app_constants.dart)

Change:

```dart
static const String apiBaseUrl = 'https://dhebe.com/api';
```

## Build release APK

```powershell
cd mobile
F:\apps\android\flutter\bin\flutter.bat build apk --release
```

## Notes

- This MVP stores the auth token with `flutter_secure_storage`.
- The app talks only to the PHP REST API.
- The app never connects directly to MySQL.
- WhatsApp remains manual: copy or open draft only.
