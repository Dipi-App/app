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

از تب Actions روی «Build & Release» بزن، «Run workflow» را انتخاب کن و نوع
بالا رفتن نسخه را بگو (`auto`، `patch`، `minor` یا `major`).

### اگر ربات کار نکرد

- مطمئن شو Secretها درست‌اند (`KEY_ALIAS` معمولاً `dipi` است).
- اگر خطای NDK گرفتی، مقدار `dipiNdkVersion` در `android/gradle.properties`
  را خالی بگذار تا از NDK پیش‌فرض فلاتر استفاده شود.
- برای گرفتن نسخه روی شاخه‌ی `main` باشد، نه شاخه‌ی دیگر.

---

## In English

Releases are automated. Push to `main` with Conventional Commit messages:

- `feat: …` → minor bump (1.1.0 → 1.2.0)
- `fix: …` → patch bump (1.2.0 → 1.2.1)
- `feat!: …` / `BREAKING CHANGE` → major bump (1.2.1 → 2.0.0)
- `chore:` / `docs:` / … only → no release

The **Build & Release** workflow then analyzes, tests, bumps `pubspec.yaml`,
writes `CHANGELOG.md`, tags `vX.Y.Z`, builds `--split-per-abi` + universal APKs,
uploads them as artifacts and creates a GitHub Release with generated notes.

1. **Create the signing keystore once** (commands above) and add the four
   secrets. Never commit the `.jks` or the passwords.
2. **Manual run:** Actions → *Build & Release* → *Run workflow*, choosing the
   bump (`auto`/`patch`/`minor`/`major`). Manual runs always release.
3. **Build number** always increments on every release because Android needs a
   fresh `versionCode`.
4. **No CI loop:** the version commit message ends with `[skip ci]`, and the job
   ignores commits containing that marker.

### Installing a release locally

```bash
flutter build apk --release            # uses debug keys when key.properties is absent
flutter build apk --release --split-per-abi
```

Outputs: `build/app/outputs/flutter-apk/app-release.apk` (universal) and
`app-<abi>-release.apk` per ABI.
