# راهنمای انتشار نسخه‌ی جدید / Release guide

## به زبان ساده (فارسی)

انتشار نسخه تقریباً خودکار است. کافی است کارت را با پیام‌های استاندارد
(Conventional Commits) روی شاخه‌ی `main` بالا بفرستی:

- `feat: ...` → یک نسخه‌ی کوچک بالا می‌رود (مثلاً ۱.۱.۰ → ۱.۲.۰)
- `fix: ...` → نسخه‌ی اصلاحی بالا می‌رود (۱.۲.۰ → ۱.۲.۱)
- `feat!: ...` یا `BREAKING CHANGE` → نسخه‌ی اصلی (۱.۲.۱ → ۲.۰.۰)
- فقط `chore:` و `docs:` و … → نسخه‌ای منتشر نمی‌شود

بعد از هر push، ربات این کارها را انجام می‌دهد:

۱. کد را بررسی و تست می‌کند (`flutter analyze` و `flutter test`).
۲. شماره‌ی نسخه را در `pubspec.yaml` بالا می‌برد و `CHANGELOG.md` را می‌سازد.
۳. یک تگ مثل `v1.2.0` می‌زند.
۴. فایل‌های APK را می‌سازد: `universal` و جدا برای هر پردازنده.
۵. یک Release می‌سازد و فایل‌ها را کنارش می‌گذارد.

### ساختن کلید امضا (یک بار برای همیشه)

```bash
keytool -genkeypair -v -keystore dipi-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias dipi

# متن آماده برای Secret:
base64 -w0 dipi-release.jks
```

سپس در گیت‌هاب → Settings → Secrets and variables → Actions این چهار مقدار را
اضافه کن: `KEYSTORE_BASE64`، `KEYSTORE_PASSWORD`، `KEY_ALIAS`، `KEY_PASSWORD`.

> ⚠️ فایل `.jks` و رمزها را **هرگز** در مخزن نگذار. فایل `android/key.properties`
> در `.gitignore` هست.

### اگر خواستی دستی منتشر کنی

دو راه داری:

**راه تگ (پیشنهادی):** یک تگ نسخه بزن و آن را push کن. شماره‌ی نسخه در
`pubspec.yaml` باید با تگ یکی باشد.

```bash
git tag v1.2.3
git push origin v1.2.3
```

**راه تب Actions:** از تب Actions روی «Build & Release» بزن، «Run workflow» را
انتخاب کن و نوع بالا رفتن نسخه را بگو (`auto`، `patch`، `minor` یا `major`).
این راه خودش نسخه را بالا می‌برد و تگ می‌زند.

راهنمای نصب برای کاربران در [`INSTALL.fa.md`](INSTALL.fa.md) است و در متن هر
Release هم لینک می‌شود.

### اگر ربات کار نکرد

- مطمئن شو Secretها درست‌اند (`KEY_ALIAS` معمولاً `dipi` است).
- اگر خطای NDK گرفتی، مقدار `dipiNdkVersion` در `android/gradle.properties`
  را خالی بگذار تا از NDK پیش‌فرض فلاتر استفاده شود.
- برای گرفتن نسخه روی شاخه‌ی `main` باشد، نه شاخه‌ی دیگر.

---

## In English

Releases are cut by pushing a version tag (`vX.Y.Z`); pushing to `main` still
auto-bumps from Conventional Commits and tags for you.

1. **Create the signing keystore once** (commands above) and add the four
   secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`,
   `KEY_PASSWORD`). Never commit the `.jks` or the passwords.
2. **Tag release:** `git tag v1.2.3 && git push origin v1.2.3`. The version in
   `pubspec.yaml` must match the tag. The workflow validates this.
3. **Auto/manual release:** `main` runs bump `pubspec.yaml`, write `CHANGELOG.md`
   and tag `vX.Y.Z` from Conventional Commits. A manual run from the Actions tab
   also always releases.
4. The workflow builds `--split-per-abi` + universal APKs, **verifies every APK
   with `apksigner verify --print-certs` and fails if any is signed with the
   Android Debug key**, writes `<apk>.sha256` files, and creates the release with
   the checksums in the notes.
5. **Build number** always increments on every release because Android needs a
   fresh `versionCode`.
6. **No CI loop:** the version commit message ends with `[skip ci]`, and the job
   ignores commits containing that marker. Tags pushed by the workflow's own
   `GITHUB_TOKEN` do not re-trigger the workflow.

Users install from [`INSTALL.fa.md`](INSTALL.fa.md); the release notes link to it.

### Installing a release locally

Release builds are **never** signed with the debug key: without a keystore the
build fails. Configure `android/key.properties` (git-ignored) or the
`DIPI_*` environment variables first.

```bash
flutter build apk --release --split-per-abi
flutter build apk --release            # universal APK
```

Outputs: `build/app/outputs/flutter-apk/app-release.apk` (universal) and
`app-<abi>-release.apk` per ABI.
