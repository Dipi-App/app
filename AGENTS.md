# AGENTS.md — Dipi (دیپی)

Offline Persian (RTL) Flutter app for Android. Workers log workdays and payments.
See `README.md` for the product overview and `docs/RELEASE.md` for releasing.

## Environment notes (this machine)

`pub.dev` is not reachable here (`403`). Use the mirror for every pub command:

```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
```

`dart` on `PATH` may point at a standalone SDK (`/usr/lib/dart`). Use the Flutter
SDK's Dart instead:

```bash
export PATH="/home/mostafa/flutter/bin:$PATH"
```

The Android SDK's NDK `28.2.13676358` (Flutter's default) is **not** installed and
cannot be downloaded here. `android/gradle.properties` pins `dipiNdkVersion` to an
installed revision and `android/build.gradle.kts` applies it to plugin modules too.
Empty `dipiNdkVersion` to fall back to Flutter's default.

## Commands

```bash
export PATH="/home/mostafa/flutter/bin:$PATH"
export PUB_HOSTED_URL=https://pub.flutter-io.cn

flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift codegen
dart run flutter_launcher_icons                            # app icon
dart run flutter_native_splash:create                      # splash screen
flutter analyze                                            # must stay clean
flutter test
flutter build apk --debug
```

## Layout

```
lib/
  app.dart                     MaterialApp: locale fa, RTL, themes, AppGate
  main.dart                    ProviderScope + runApp
  core/
    constants/app_info.dart    name, tagline, version, backup file names
    providers/                 database + DAO providers
    theme/                     light/dark ColorScheme, employer palette, brand_colors
    utils/                     persian_digits, jalali_utils, money, time_utils
  data/db/                     drift tables, database, generated code, DAOs
  domain/enums.dart            WageType, PaymentType, ThemeChoice, SettlementState
  features/<feature>/
    domain/ presentation/ state/
  presentation/                home shell, app gate
  shared/                      widgets + motion helper + branding (DipiMark)
assets/
  fonts/                       Vazirmatn (bundled, no network)
  branding/                    D-mark logo, app icon + splash sources
  lottie/                      empty-state animation (self-authored)
```

`lib/data/db/app_database.g.dart` is generated — regenerate with build_runner,
never edit by hand. `flutter_launcher_icons` and `flutter_native_splash` output
(mipmaps, drawables, styles) is generated too.

## Invariants

- Persian only, full RTL, Persian digits everywhere in the UI.
- Dates are stored as **Gregorian ISO text** (`YYYY-MM-DD`); converted to Jalali
  only in the UI.
- Money is stored as **integer Rial** (canonical unit). Display/entry uses the
  selected unit: `toman` (= 10 rial) or `rial`. Never use `double` for money.
- No network calls except the Google Drive backup (`drive.appdata` scope).
- Business logic (balance, stats) lives in pure Dart classes, not widgets.

## Application id

Edit `android/gradle.properties` → `dipiAppId` (single place). The Kotlin
namespace stays `com.yourname.dipi` so no source file has to move.

## Step status

1. Project setup, theme, RTL, font, drift schema, navigation — done.
2. Employers + Calendar + WorkEntry CRUD — done.
3. Payments + balance + settlement view — done.
4. Stats and charts — done.
5. Local JSON backup/import, export txt/md/docx — done.
6. Google Drive backup — done (needs the Google Cloud setup below).
7. Animation polish, app lock, tests — done.

## Google Drive backup

The Drive client is written; it stays disabled until you create an OAuth client.
Do this once, by hand, in https://console.cloud.google.com:

1. Create (or pick) a project.
2. APIs & Services → Library → enable **Google Drive API**.
3. APIs & Services → OAuth consent screen: type *External*, fill the form, add
   the scope `.../auth/drive.appdata` only, and add your own Google account under
   *Test users* (Testing mode is enough for personal use).
4. APIs & Services → Credentials → create **two** OAuth client ids:
   * **Android** — package name = `dipiAppId` from `android/gradle.properties`,
     plus the SHA-1 of your signing key.
   * **Web application** — no redirect URI needed.
5. Get the debug SHA-1:

   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore \
     -alias androiddebugkey -storepass android -keypass android
   ```

6. Build the app with the **Web** client id (never the Android one):

   ```bash
   flutter build apk --dart-define=DIPI_GOOGLE_SERVER_CLIENT_ID=XXXX.apps.googleusercontent.com
   ```

Without the define, `AppInfo.googleBackupConfigured` is false and the Drive
section shows the setup guide instead of a sign-in button. Nothing else in the
app needs the network.

The Drive code talks to the Drive REST API (`drive/v3/files` with
`spaces=appDataFolder` / `uploadType=media`) over the OAuth token from
`google_sign_in` — no `googleapis` dependency needed.

## App lock

* PIN is never stored: `sha256('dipi:v1:<salt>:<pin>')` lives in `app_settings`
  together with a random 16-byte salt and the PIN length.
* The lock screen accepts 4–8 digits, auto-submits at the stored length, shakes
  on a wrong PIN and offers biometrics when the device has an enrolled one.
* `AppGate` locks again when the app goes to `paused`/`hidden`.
* Auto Drive backup runs once per app start when the toggle is on and the last
  backup is over a day old — it is best-effort and swallows its errors.

## Testing notes

Widget tests that mount `DipiApp` must unmount it inside the test body and pump
one extra frame, otherwise drift's zero-duration cleanup timer trips
`!timersPending`:

```dart
await tester.pumpWidget(const SizedBox.shrink());
await tester.pump(const Duration(milliseconds: 1));
```

Money is stored in Rial; Toman is display/entry only (`CurrencyUnit.rialFactor`).
