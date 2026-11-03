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
  main.dart                    ProviderScope + runApp + auto-backup scheduler
  core/
    constants/app_info.dart    name, tagline, version, backup file names
    providers/                 database + DAO providers
    theme/                     light/dark ColorScheme, employer palette, brand_colors
    utils/                     persian_digits, jalali_utils, money, time_utils
  data/db/                     drift tables, database, generated code, DAOs
  domain/enums.dart            WageType, PaymentType, ThemeChoice, SettlementState
  features/<feature>/
    domain/ presentation/ state/
  features/app_update/         GitHub release check (opens download in browser)
  features/backup/             JSON backup/restore, auto backup, local backup
  presentation/                home shell, app gate
  shared/                      widgets + motion helper + branding (DipiMark)
packages/
  dipi_documents/              local plugin: MediaStore writes to Documents/dipi
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
- No network calls except the GitHub release check in `features/app_update`
  (which only opens the download page in the browser — no auto-install, no
  `REQUEST_INSTALL_PACKAGES`).
- Business logic (balance, stats) lives in pure Dart classes, not widgets.
- Backup files are plain JSON; the automatic file shape is
  `{ schemaVersion, appVersion, createdAt, data }` (see `BackupDocument`).

## Release signing

Release builds are **never** signed with the debug key: without a keystore the
build fails (`android/app/build.gradle.kts`). Signing comes from `DIPI_*`
environment variables (CI) or `android/key.properties` (local, git-ignored).
Releases are tag-triggered; see `docs/RELEASE.md` and `docs/INSTALL.fa.md`.

## Application id

Edit `android/gradle.properties` → `dipiAppId` (single place). The Kotlin
namespace stays `com.yourname.dipi` so no source file has to move.

## Step status

1. Project setup, theme, RTL, font, drift schema, navigation — done.
2. Employers + Calendar + WorkEntry CRUD — done.
3. Payments + balance + settlement view — done.
4. Stats and charts — done.
5. Local JSON backup/import, export txt/md/docx — done.
6. Automatic local backup (12h, Documents/dipi) — done.
7. In-app update check (GitHub releases) — opens the APK link in the browser; no
   auto-install, no extra permissions. Releases are tag-triggered (`vX.Y.Z`).
8. Animation polish, app lock, tests — done.

## Backup

- **Manual**: JSON export/import from Settings → پشتیبان‌گیری, plus
  txt/md/docx export from the export screen.
- **Automatic**: a `workmanager` periodic task runs every 12 hours and also on
  app start when the last backup is over 12 hours old
  (`features/backup/data/auto_backup_scheduler.dart`). It writes
  `Documents/dipi/dipi_backup_YYYYMMDD_HHmm.json` through the local
  `dipi_documents` plugin (Android `MediaStore`, no permission, API 29+),
  keeps the last 10 files, and records the time in `app_settings.lastBackupAt`.
- Nothing changed since the last written backup ⇒ no file is created. The check
  is a SHA-256 over `schemaVersion`+`appVersion`, the rows sorted by id and the
  settings (`BackupDocument.contentFingerprint`,
  `features/backup/domain/backup_fingerprint.dart`), stored in `key_values` as
  `lastBackupFingerprint`. Export timestamps and the app-written keys
  (`lastBackupAt`, `lastBackupFingerprint`, `lastBackupReminderAt`,
  `lastUpdateCheckAt`, `backupRecoveryOffered`) are excluded — without that, the
  daily update check alone would make every run look like new data. A skipped
  run leaves `lastBackupAt` untouched, so it keeps meaning "last real
  snapshot". The manual "پشتیبان‌گیری الان" button uses the same rule and says
  so in Persian.
- Files are written to a temp file first and published with MediaStore
  `IS_PENDING`, so a half-written file is never visible.
- The 10-file cap counts only backups this install owns. Uninstall clears the
  MediaStore `owner_package_name`, and `prune()` cannot delete rows it does not
  recognise as its own, so orphan files from earlier installs stay on disk
  (seen during QA as 17 orphan rows next to 2 owned). Reinstall recovery reads
  the newest non-empty snapshot regardless of how many orphans accumulated.
- **Reinstall recovery** (`features/backup/data/backup_recovery.dart`, offered
  once by `AppGate` when onboarding is done and the ledger is empty): the app
  reads the newest backup that still holds data and offers ادغام / جایگزینی
  کامل. **Android 11 and newer hide the files an earlier install left behind** —
  uninstall clears their MediaStore owner, and after that they are invisible to
  our query, to the `File` API and even to the system file picker (verified on
  Android 16: "No matches in SDCARD"). So the offer asks for
  `MANAGE_EXTERNAL_STORAGE` ("All files access"), which the user can only turn
  on in the system settings; `AppGate` picks the offer back up on resume. That
  resume re-arms the look instead of closing it — a process started before the
  grant cannot always see it, and closing the offer on that answer would throw
  away the only copy of the data. The access dialog is therefore shown at most
  once per launch; a second pass says «دیپی را دوباره باز کنید». Tapping بعداً
  ends the offer (`backupRecoveryOffered`), and on Android 10 and older nothing
  is asked because the rows are already visible.
- `android:allowBackup="false"` keeps the OS from uploading app data.

## App lock

* PIN is never stored: `sha256('dipi:v1:<salt>:<pin>')` lives in `app_settings`
  together with a random 16-byte salt and the PIN length.
* The lock screen accepts 4–8 digits, auto-submits at the stored length, shakes
  on a wrong PIN and offers biometrics when the device has an enrolled one.
* `AppGate` locks again when the app goes to `paused`/`hidden`.

## Testing notes

Widget tests that mount `DipiApp` must unmount it inside the test body and pump
one extra frame, otherwise drift's zero-duration cleanup timer trips
`!timersPending`:

```dart
await tester.pumpWidget(const SizedBox.shrink());
await tester.pump(const Duration(milliseconds: 1));
```

Money is stored in Rial; Toman is display/entry only (`CurrencyUnit.rialFactor`).
