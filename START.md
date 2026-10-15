# Task: Build "Dipi" (دیپی) — an offline Persian (RTL) Flutter Android app

## App identity

- English name: Dipi. Persian name shown to the user: دیپی.
- Meaning: "Dipi" is an Old Persian word for "writing" or "record". Use this idea in the about page and the splash screen (one short Persian line).
- Android app label: دیپی.
- Dart package name: `dipi`.
- Application ID: `com.yourname.dipi` (I will change `yourname` later; keep it in one place so it is easy to edit).
- Store title idea: «دیپی | ثبت روزکار و حساب‌کتاب».
- Use the name in the about page, backup file name (`dipi-backup-YYYYMMDD.json`), and export file names.

## Goal

Workers and employees write their workdays and the money they get in a paper notebook. Replace that notebook with a fast, beautiful, offline app. The user logs workdays on a calendar, logs payments, and always knows who owes whom.

## Hard rules

- Platform: Android only. Flutter (latest stable), Dart null-safety.
- Language: Persian only. Full RTL. Font: Vazirmatn (bundled in assets, no network).
- Fully offline. No sign-up. No backend.
- Calendar: Jalali (Shamsi). Week starts on Saturday. Show Persian digits everywhere.
- Store all dates in the database as Gregorian ISO strings. Convert to Jalali only in the UI. (Use `shamsi_date` or similar.)
- Store money as integers. Never use double for money.
- Currency: user can choose Toman or Rial in settings. Format with thousand separators and Persian digits.
- Light and dark theme.

## Architecture

- Feature-first folders (`features/calendar`, `features/employers`, `features/payments`, `features/stats`, `features/backup`, `features/export`, `features/settings`).
- Shared widgets in a `shared/` folder. Keep widgets small. No huge `build` methods.
- State: Riverpod. Local DB: Drift (SQLite). Use migrations and a schema version.
- Keep business logic (balance, stats) in pure Dart classes. Easy to unit test.

## Data model

**Employer**: id, name, color, phone (optional), note (optional), default wage type, default daily wage (optional), is_archived.

**WorkEntry** (many per day are allowed, also for different employers):

- id, employer_id, date
- place (text), job (text) — remember old values and show them as quick suggestions
- start_time, end_time (optional; support shifts that cross midnight; compute duration)
- wage_type: `fixed` | `variable`
- wage_amount (nullable). If `variable` and the amount is not known yet, status is `pending`. The user can fill it later.
- out_of_pocket_amount (default 0): money the worker paid for the employer
- note (optional)

**Payment**: id, employer_id, date, amount, type (`wage` | `advance` | `expense_refund`), note (optional).

## Balance rule (important, test it)

For one employer in a period:
`balance = sum(wage_amount) + sum(out_of_pocket_amount) − sum(payments)`

- Positive → employer owes the user (طلبکار).
- Negative → user owes the employer (بدهکار), for example after a big advance.
- Pending wages are shown separately and are not counted until a value is set.
  Wage payment schedule (monthly, every few days) is just how often payments are logged. No special logic needed.

## Screens and features

1. **Calendar (home)**
   - Month view, Jalali. Swipe to change month.
   - A day with work gets the employer's color. If there are many employers, show a split color or small colored dots. A day without work has no color.
   - Tap a day → bottom sheet with that day's entries and an "Add" button. Edit and delete from there. Delete needs confirm, then Undo snackbar.
   - Add/Edit form: employer picker, place, job, time from/to, wage type and amount, out-of-pocket amount, note.
2. **Employers**: list, add, edit, archive. Each employer has a color picker. Employer detail page shows balance, entries, and payments.
3. **Payments**: add, edit, delete payments per employer. List with filters.
4. **Settlement view** (per employer): shows total wage, total expenses, total payments, final balance, with a clear "طلبکار / بدهکار / تسویه" label and color.
5. **Stats**
   - Overall: total days, total hours, total earned, total expenses, total received, total balance.
   - Per employer: same numbers plus a monthly chart (use `fl_chart`).
   - Filter by date range (Jalali) and employer.
6. **Export** (txt, md, docx)
   - Filters: date range and one or more employers.
   - Content: entries, payments, totals, and balance per employer.
   - Persian text must be right-to-left in all three formats.
   - For docx: build it with raw OOXML (`archive` package) so RTL (`w:bidi`, `w:rtl`) and Persian font work correctly. Do not use a weak docx package.
   - Share with `share_plus` or save with the system file picker.
7. **Backup and restore**
   - Local export/import as one JSON file with `schemaVersion`. Validate on import. Ask: replace all data or merge.
   - Google Drive backup using `google_sign_in` + Drive API with the `drive.appdata` scope only. No sign-up in the app. Google login is used only for backup. Manual backup/restore buttons. Optional auto-backup toggle.
   - Show "last backup" date. Remind the user if no backup for 30 days.
   - Tell me the exact Google Cloud / OAuth / SHA-1 steps I must do by hand.
8. **Settings**: currency unit, theme, optional app lock (PIN / biometric), backup, about (app name Dipi, short meaning line, version).

## UI and animation

- Smooth and modern. Target 60 fps.
- Use `flutter_animate` (and Lottie for empty states) for: page transitions, list item entrance, calendar month change, color fill on days, number count-up in stats, press feedback on buttons.
- Use Hero animations between list and detail pages.
- Respect the system "reduce motion" setting.
- Add helpful empty states and clear Persian error messages.
- Make a simple app icon and splash screen for Dipi. Idea: an ancient-style tablet or reed pen with a small calendar mark. Use `flutter_launcher_icons` and `flutter_native_splash`.

## Quality

- Unit tests: balance calculation, midnight-crossing duration, Jalali ↔ Gregorian conversion, backup export → import round trip.
- Run `flutter analyze` with no warnings.
- Do not add analytics or any network call except Google Drive backup.

## Delivery plan (work in this order, stop after each step and show a short summary)

1. Project setup (name, app id, icon, splash), theme, RTL, font, Drift schema, navigation.
2. Employers + Calendar + WorkEntry CRUD.
3. Payments + balance + settlement view.
4. Stats and charts.
5. Local JSON backup/import, then export txt/md/docx.
6. Google Drive backup.
7. Animations polish, app lock, tests.

Before you start, ask me only if something blocks you. Otherwise, choose the simple option and tell me what you chose.
