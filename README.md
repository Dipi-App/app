# Dipi (دیپی)

دیپی: واژه‌ای پارسی باستانی به معنای نوشتن و ثبت کردن.

Offline Android app for workers and employees to log workdays and payments on a
Jalali calendar — a paper notebook replacement that always knows who owes whom.

- Persian only, full RTL, Vazirmatn font bundled, Persian digits everywhere.
- Fully offline. No sign-up. No backend. The only network feature is the optional
  Google Drive backup (`drive.appdata` scope).
- Jalali calendar, week starts Saturday. Dates are stored as Gregorian ISO text
  and converted to Jalali only in the UI.
- Money is stored as integer Rial; Toman or Rial for display and entry.
- Light and dark theme, Material 3.

## Status

| Step | Scope | State |
| --- | --- | --- |
| 1 | Project setup, theme, RTL, font, drift schema, navigation | done |
| 2 | Employers + Calendar + WorkEntry CRUD | done |
| 3 | Payments + balance + settlement view | done |
| 4 | Stats and charts | done |
| 5 | Local JSON backup/import, export txt/md/docx | done |
| 6 | Google Drive backup | done (needs a Google OAuth client) |
| 7 | Animation polish, app lock, tests | done |

See `START.md` for the full product brief and `AGENTS.md` for development notes.

## Features today

- **Calendar** — Jalali month grid, swipe to change month, a day is coloured with
  the employer's colour (split when several employers worked that day), a dot for
  wages still unknown, and a month summary (workdays, hours, wages, pending).
- **Employers** — list, add/edit (name, colour, phone, note, default wage),
  archive/restore, delete (cascades), and a detail page with totals.
- **Work entries** — add/edit/delete from a day sheet or an employer page, with
  employer, place, job, times (shifts crossing midnight are supported), wage type
  fixed/variable, wage amount, out-of-pocket money and a note. Place and job are
  offered as quick suggestions from previous values.
- **Payments** — wage, advance and expense-refund payments with employer and type
  filters, plus a whole-ledger balance summary.
- **Settlement** — per employer: total wages, out-of-pocket expenses, total
  payments and the final balance, labelled طلبکار / بدهکار / تسویه.
- **Stats** — filter by range (this month, 3/6/12 months, this year, from the
  start, or a custom Jalali range) and by employer. Shows workdays, hours, wages,
  out-of-pocket, received and the balance, a monthly chart of earnings versus
  receipts, and a per-employer breakdown. The settlement page carries the same
  chart for the last 12 months.
- **Backup** — one JSON file with `schemaVersion`, validated on import, restored
  either by replacing everything or by merging (employers match by name, duplicate
  entries and payments are skipped). Optional Google Drive backup into the hidden
  `drive.appdata` folder, plus a reminder when the last backup is over 30 days old.
- **Export** — txt, md or docx for a Jalali range and any set of employers, with
  per-employer totals and the balance. Persian stays right-to-left in all three:
  plain text gets a UTF-8 BOM and a right-to-left mark on every line, markdown is
  wrapped in a `dir="rtl"` block, and the docx is hand-built OOXML with `w:bidi`,
  `w:rtl` and `w:bidiVisual` so Word and LibreOffice lay it out correctly.
- **App lock** — optional 4–8 digit PIN (stored only as a salted SHA-256 hash)
  with an optional fingerprint/face unlock. Re-arms when the app is backgrounded.

## Balance rule

For one employer in a period:

```
balance = sum(wage_amount) + sum(out_of_pocket_amount) − sum(payments)
```

Positive → the employer owes the worker (طلبکار). Negative → the worker owes the
employer (بدهکار), for example after a big advance. Work entries whose wage amount
is not filled in yet are reported separately and are not counted.

## Build

```bash
export PATH="/home/mostafa/flutter/bin:$PATH"
export PUB_HOSTED_URL=https://pub.flutter-io.cn   # pub.dev is unreachable here

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

## Layout

```
lib/
  app.dart                     MaterialApp: locale fa, RTL, themes, AppGate
  main.dart                    ProviderScope + runApp
  core/
    constants/app_info.dart    name, tagline, version, backup file names
    providers/                 database + DAO providers
    theme/                     light/dark ColorScheme, employer palette
    utils/                     persian_digits, jalali_utils, money, time_utils
  data/db/                     drift tables, database, generated code, DAOs
  domain/                      enums, balance rule, entry statistics
  features/<feature>/
    domain/ presentation/ state/
  presentation/                home shell, app gate
  shared/                      widgets + motion helper + branding (DipiMark)
assets/
  fonts/                       Vazirmatn (bundled, no network)
  branding/                    D-mark logo, app icon + splash sources
  lottie/                      empty-state animation (self-authored)
```

`lib/data/db/app_database.g.dart` is generated by build_runner — never edit it by
hand. The launcher icon, splash and Android mipmaps/drawables are generated too.

## Invariants

- Persian only, full RTL, Persian digits everywhere in the UI.
- Dates live in the database as Gregorian ISO text (`YYYY-MM-DD`).
- Money is **integer Rial** and never a `double`.
- No network calls except the Google Drive backup.
- Business logic (balance, stats) lives in pure Dart classes, not widgets.

## Tests

```bash
flutter test
```

Covers the balance rule and settlement states, entry totals and midnight-crossing
shifts, Jalali ↔ Gregorian conversion, Persian digits and money formatting, the
DAOs (range boundaries, ordering, undo-keeps-id, SQL aggregates, cascade deletes)
and a few widget flows (app shell, day sheet, entry form, settlement page).

Widget tests that mount `DipiApp` must unmount it inside the test body and pump one
extra frame, otherwise drift's zero-duration cleanup timer trips `!timersPending`:

```dart
await tester.pumpWidget(const SizedBox.shrink());
await tester.pump(const Duration(milliseconds: 1));
```

## Google Drive backup

The feature is written but stays switched off until you create an OAuth client in
[Google Cloud Console](https://console.cloud.google.com):

1. Create a project, then **APIs & Services → Library → Google Drive API → Enable**.
2. **OAuth consent screen**: type *External*, add only the scope
   `.../auth/drive.appdata`, and add your own account under *Test users*.
3. **Credentials** → create an **Android** client (package `dipiAppId` + your
   SHA-1) and a **Web application** client (no redirect URI).
4. Build with the **Web** client id:

   ```bash
   flutter build apk --dart-define=DIPI_GOOGLE_SERVER_CLIENT_ID=XXXX.apps.googleusercontent.com
   ```

The exact steps and the SHA-1 command are also inside the app
(تنظیمات → پشتیبان‌گیری). Without the define the section shows the guide and
nothing else in the app touches the network.

## Application id

Set `dipiAppId` in `android/gradle.properties` — the single place. The Kotlin
namespace stays `com.yourname.dipi` so no source file has to move.

## Branding

The visual identity lives in `assets/branding/` (a gold `D` with a cuneiform
wedge on deep teal). `lib/core/theme/brand_colors.dart` holds the palette,
`lib/shared/branding/dipi_logo.dart` the `DipiMark` / `DipiLogo` widgets, and the
launcher icon plus splash are generated from those sources with
`flutter_launcher_icons` and `flutter_native_splash`. See
`assets/branding/BRANDING.md` for the rules.
