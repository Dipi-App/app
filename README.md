# Dipi (دیپی)

**Dipi** is a free, offline Android app for workers and tradespeople: log your
workdays and payments on a Jalali calendar and always know who owes whom.
Everything stays on your phone — no account, no sign-up, no internet required.

<p align="center">
  <a href="https://github.com/Dipi-App/app/releases/latest">
    <img src="https://img.shields.io/badge/Download-latest%20release-0D3B42?style=for-the-badge&logo=android&logoColor=white" alt="Download the latest release" height="44">
  </a>
</p>

[![Build & Release](https://github.com/Dipi-App/app/actions/workflows/build.yml/badge.svg)](https://github.com/Dipi-App/app/actions/workflows/build.yml)
[![Latest release](https://img.shields.io/github/v/release/Dipi-App/app)](https://github.com/Dipi-App/app/releases/latest)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

- Website: <https://dipi-app.github.io/>
- Latest release: <https://github.com/Dipi-App/app/releases/latest>
- Installation guide: [docs/INSTALL.fa.md](docs/INSTALL.fa.md)

## Features

- **Work calendar** — log every workday on a Jalali month grid, with the employer
  shown by colour and a summary card for the selected day.
- **Employer management** — add, edit, archive and delete employers, each with its
  own colour, phone, note and default wage.
- **Payment tracking and balance** — record payments per employer and see the
  running balance ("owed to you" / "owed by you") at a glance.
- **Statistics** — workday, wage and payment totals, a monthly bar chart and one
  card per employer.
- **Works fully offline** — no server, no account, no network calls for your data.
- **No sign-up required** — install and start working; nothing to register.
- **Persian and RTL support** — a fully right-to-left interface with Persian
  digits throughout.
- **Automatic local JSON backup** — the app writes a JSON backup to your phone's
  storage every 12 hours and keeps the most recent copies.

## Screenshots

<!-- Replace the placeholders below with real screenshots once available. -->

| Calendar | Employers | Payments | Statistics |
| --- | --- | --- | --- |
| _screenshot placeholder_ | _screenshot placeholder_ | _screenshot placeholder_ | _screenshot placeholder_ |

## Download

Get the latest APK from the
[**latest release**](https://github.com/Dipi-App/app/releases/latest).
For step-by-step help (allowing install from this source, the "Install anyway"
prompt and checking the SHA-256), see the
[installation guide](docs/INSTALL.fa.md).

## Build from source

Requirements: Flutter (stable), Dart and Java 17 for Android builds.

```bash
flutter pub get
flutter run
```

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before
opening an issue or a pull request, and follow the
[Code of Conduct](CODE_OF_CONDUCT.md).

## License

Released under the [MIT License](LICENSE).

## Website

<https://dipi-app.github.io/>

---

Developed by Mostafa — <https://mst-ghi.github.io/>
