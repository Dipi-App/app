# دیپی (Dipi)

> دیپی: واژه‌ای پارسی باستانی به معنای نوشتن و ثبت کردن.
> A paper-notebook replacement for workers: log workdays and payments on a
> Jalali calendar and always know who owes whom — fully offline, Persian, RTL.

[![Build & Release](https://github.com/mst-ghi/dipi/actions/workflows/build.yml/badge.svg)](https://github.com/mst-ghi/dipi/actions/workflows/build.yml)
[![Latest release](https://img.shields.io/github/v/release/mst-ghi/dipi)](https://github.com/mst-ghi/dipi/releases/latest)

## دانلود و نصب (فارسی)

<p align="center">
  <a href="https://github.com/mst-ghi/dipi/releases/latest">
    <img src="https://img.shields.io/badge/%D8%AF%D8%A7%D9%86%D9%84%D9%88%D8%AF-%D8%A2%D8%AE%D8%B1%DB%8C%D9%86_%D9%86%D8%B3%D8%AE%D9%87-0D3B42?style=for-the-badge&logo=android&logoColor=white" alt="Download the latest release" height="48">
  </a>
</p>

۱. روی دکمه **دانلود** بالا بزن و از صفحه‌ی Releases آخرین فایل را بگیر.
   برای بیشتر گوشی‌ها فایل `dipi-vX.Y.Z-arm64-v8a.apk` مناسب است.
۲. فایل دانلود‌شده را در گوشی باز کن.
۳. اگر گوشی پیام داد، در تنظیمات اجازه‌ی **نصب از منابع ناشناس** را برای
   برنامه‌ی فایل‌ها روشن کن (گوشی‌های جدید معمولاً خودشان راهنمایی می‌کنند).
۴. «نصب» را بزن. تمام! دیپی بدون اینترنت کار می‌کند.

> فایل `dipi-vX.Y.Z-universal.apk` برای همه‌ی گوشی‌ها کار می‌کند و کمی
> حجیم‌تر است. بقیه‌ی فایل‌ها سبک‌ترند و مخصوص یک نوع پردازنده هستند.

## Download & install (English)

1. Tap the **Download** button above and grab the latest APK from the Releases
   page. Most phones want `dipi-vX.Y.Z-arm64-v8a.apk`.
2. Open the downloaded file on the phone.
3. If Android asks, allow **installing from unknown sources** for your file
   manager (newer Android shows a one-tap guide).
4. Tap **Install**. Done — Dipi works with no internet connection.

`dipi-vX.Y.Z-universal.apk` runs on any phone and is a bit larger; the per-ABI
APKs are smaller and faster.

## Features

- **Calendar** — Jalali month grid, swipe to change month, each day coloured
  with the employer's colour, a dot for unknown wages, and a month summary.
- **Employers** — add/edit (name, colour, phone, note, default wage),
  archive/restore, delete, and a detail page with totals.
- **Work entries** — employer, place, job, times (cross-midnight shifts),
  fixed/variable wage, out-of-pocket money and a note; smart defaults (today,
  last employer, last place/job).
- **Payments** — wage, advance and expense-refund payments with filters and a
  whole-ledger balance summary.
- **Settlement & stats** — per employer and per range: wages, out-of-pocket,
  received, balance, a monthly chart and a per-employer breakdown.
- **Backup & export** — one JSON file, local or Google Drive (`drive.appdata`),
  and txt/md/docx export that stays right-to-left.
- **App lock** — optional 4–8 digit PIN (salted SHA-256) with fingerprint.
- **Made for low literacy** — big icons and short Persian labels everywhere, a
  floating bottom bar with a large "add workday" center button, first-run
  onboarding, contextual "?" guides, one-time coach marks and optional spoken
  help (device Persian voice required).

## Requirements

- Flutter 3.47+ (stable), Dart 3.13+, Java 17 for Android builds.
- Persian is the only language; the app is fully RTL and uses Persian digits.

## Build

```bash
export PATH="/home/mostafa/flutter/bin:$PATH"        # use Flutter's Dart, not a standalone SDK
export PUB_HOSTED_URL=https://pub.flutter-io.cn      # pub.dev is unreachable on the maintainer's machine

flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift codegen
flutter analyze                                            # must stay clean
flutter test
flutter build apk --debug
```

Regenerate the app icon and splash after changing the artwork:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

Release builds optionally use `android/key.properties` for signing (see below).
When it is missing the build falls back to the debug keys.

## CI/CD & releases

Every push to `main` runs the **Build & Release** workflow
(`.github/workflows/build.yml`): it analyzes, tests, bumps the version, tags,
builds `--split-per-abi` plus a universal APK, uploads them as artifacts and
publishes a GitHub Release with auto-generated notes. No release is made when a
push contains no `feat:`/`fix:`/breaking commit.

See [`docs/RELEASE.md`](docs/RELEASE.md) for the step-by-step guide.

### GitHub secrets to add

Repository → Settings → Secrets and variables → Actions → **New repository
secret**:

| Secret | What it is |
| --- | --- |
| `KEYSTORE_BASE64` | the `.jks` keystore encoded with `base64 -w0 keystore.jks` |
| `KEYSTORE_PASSWORD` | the keystore password |
| `KEY_ALIAS` | the key alias inside the keystore |
| `KEY_PASSWORD` | the key password |

`GITHUB_TOKEN` is provided automatically; the workflow only asks for
`contents: write`.

Create a keystore once:

```bash
keytool -genkeypair -v -keystore dipi-release.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias dipi
base64 -w0 dipi-release.jks     # paste this into KEYSTORE_BASE64
```

## Versioning

Semantic versioning `MAJOR.MINOR.PATCH+BUILD`, kept in `pubspec.yaml`
(`version:`). A small script (`scripts/bump_version.sh`) reads the Conventional
Commits since the last `vX.Y.Z` tag — `feat!:`/`BREAKING CHANGE` → major,
`feat:` → minor, `fix:` → patch — updates `pubspec.yaml` and `CHANGELOG.md`,
and the workflow tags `vX.Y.Z`. The build number grows on every release (Android
needs a new version code each time), and the bump commit carries `[skip ci]` so
it never triggers another run. This is simpler and more predictable than
`release-please` because the version lives in exactly one file (`pubspec.yaml`)
that Flutter already reads for the APK's `versionName`/`versionCode`.

Use Conventional Commits: `feat: …`, `fix: …`, `chore: …`, `feat!: …`.

## Layout

```
lib/
  app.dart                     MaterialApp: locale fa, RTL, themes, AppGate
  main.dart                    ProviderScope + runApp
  core/
    constants/app_info.dart    name, tagline, version, backup file names
    help/                      help text, help screen, coach marks, voice hints
    providers/                 database + DAO + app-info providers
    theme/                     brand colour scheme, tokens, employer palette
    utils/                     persian_digits, jalali_utils, money, time_utils
    widgets/                   floating navigation bar
  data/db/                     drift tables, database, generated code, DAOs
  domain/                      enums, balance rule, entry statistics
  features/<feature>/          domain / presentation / state
  presentation/                home shell, app gate
  shared/                      widgets + motion helper + branding (DipiMark)
assets/                        fonts (Vazirmatn), branding, lottie animation
scripts/bump_version.sh        conventional-commit version bump
docs/RELEASE.md                how to cut a release
```

`lib/data/db/app_database.g.dart` and the launcher icon / splash output are
generated — never edit them by hand.

## Invariants

- Persian only, full RTL, Persian digits everywhere in the UI.
- Dates live in the database as Gregorian ISO text (`YYYY-MM-DD`).
- Money is **integer Rial** and never a `double`; Toman is display/entry only.
- No network calls except the optional Google Drive backup.
- Business logic (balance, stats) lives in pure Dart classes, not widgets.

## Tests

```bash
flutter test
```

Widget tests that mount `DipiApp` must unmount it inside the test body and pump
one extra frame, otherwise drift's zero-duration cleanup timer trips
`!timersPending`:

```dart
await tester.pumpWidget(const SizedBox.shrink());
await tester.pump(const Duration(milliseconds: 1));
```

## Google Drive backup

The Drive client is written but stays disabled until you create an OAuth client
in the [Google Cloud Console](https://console.cloud.google.com):

1. Create a project, then **APIs & Services → Library → Google Drive API → Enable**.
2. **OAuth consent screen**: type *External*, add only the scope
   `.../auth/drive.appdata`, and add your own account under *Test users*.
3. **Credentials** → create an **Android** client (package `dipiAppId` + your
   SHA-1) and a **Web application** client (no redirect URI).
4. Build with the **Web** client id:

   ```bash
   flutter build apk --dart-define=DIPI_GOOGLE_SERVER_CLIENT_ID=XXXX.apps.googleusercontent.com
   ```

## Application id

Set `dipiAppId` in `android/gradle.properties` — the single place. The Kotlin
namespace stays `com.yourname.dipi` so no source file has to move.

## Branding

The visual identity lives in `assets/branding/` (a gold `D` with a cuneiform
wedge on deep teal). `lib/core/theme/brand_colors.dart` holds the palette,
`lib/shared/branding/dipi_logo.dart` the widgets, and the launcher icon plus
splash are generated from those sources. See `assets/branding/BRANDING.md`.
