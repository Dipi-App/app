# بررسی نسخه‌ی جدید / Update check

## به زبان ساده (فارسی)

دیپی خودش می‌فهمد که نسخه‌ی تازه‌تری هست، ولی **هیچ‌وقت خودش چیزی دانلود یا
نصب نمی‌کند**. فقط خبر می‌دهد و یک دکمه می‌گذارد که صفحه‌ی دانلود را در مرورگر
باز می‌کند.

### چطور کار می‌کند؟

۱. وقتی برنامه باز می‌شود، **حداکثر روزی یک‌بار** نسخه‌ی آخر را از
   **GitHub Releases** می‌پرسد
   (`https://api.github.com/repos/mst-ghi/dipi/releases/latest`).
۲. نسخه‌ی تگ (مثل `v1.2.0`) را با نسخه‌ی نصب‌شده مقایسه می‌کند (مقایسه‌ی
   عددی درست، نه متن‌به‌متن).
۳. اگر نسخه‌ی تازه‌تر نبود، **هیچ پیامی نشان نمی‌دهد** و برنامه مثل همیشه کار
   می‌کند.
۴. اگر نسخه‌ی تازه‌تر بود، یک پنجره‌ی ساده‌ی فارسی نشان می‌دهد: شماره‌ی نسخه،
   «تازه‌ها در این نسخه» و یک دکمه‌ی **«دانلود از گیت‌هاب»**.
۵. با زدن آن دکمه، **مرورگر** گوشی باز می‌شود و فایل APK از گیت‌هاب دانلود
   می‌شود. نصب را خودت با مرورگر انجام می‌دهی
   (راهنما: [`INSTALL.fa.md`](INSTALL.fa.md)).

آیکون کوچک فلش دانلود در نوار بالای صفحه هم تا وقتی نسخه‌ی تازه هست نمایش داده
می‌شود؛ با زدنش همان پنجره باز می‌شود.

### بررسی دستی

از **تنظیمات → بررسی نسخه جدید** می‌توانی هر وقت خواستی بررسی کنی. بررسی دستی
محدودیت روزی یک‌بار را نادیده می‌گیرد.

### بدون اینترنت یا خطای API

اگر اینترنت نباشد یا گیت‌هاب خطا بدهد، **هیچ پیامی نشان داده نمی‌شود و برنامه
کرش نمی‌کند**. دیپی کاملاً آفلاین کار می‌کند؛ بررسی نسخه فقط یک امکان اضافه است.

### چرا اجازه و نصب خودکار نداریم؟

چون برنامه خودش APK را نصب نمی‌کند:

- هیچ اجازه‌ی اضافه‌ای (مثل `REQUEST_INSTALL_PACKAGES`) لازم نیست،
- هشدارهای امنیتی هنگام نصب کمتر می‌شود،
- دانلود و نصب کاملاً در دست کاربر است.

### چطور نسخه‌ی جدید منتشر کنم؟

یک تگ نسخه بزن و آن را push کن:

```bash
git tag v1.2.3
git push origin v1.2.3
```

(یا مثل قبل کارت‌های استاندارد روی `main` بفرست.) راهنمای کامل در
[`RELEASE.md`](RELEASE.md) است.

---

## In English

Dipi checks its **latest GitHub Release** on start, at most once every 24 hours,
by calling `api.github.com/repos/mst-ghi/dipi/releases/latest`. It compares the
tag with the installed version using a real numeric semver compare. If a newer
version exists it shows a small Persian dialog with the version number, the
release notes and a **"Download from GitHub"** button that opens the APK link in
the system browser. Nothing is downloaded or installed by the app, so it needs no
special permission and adds no install-time security warning. A small download
icon appears in the header while an update is available.

Network and API errors are handled quietly (never a crash), and the app stays
fully offline-capable. A manual check is available in
**Settings → بررسی نسخه جدید** and ignores the 24-hour window.

There is no ABI matching or checksum download any more: the browser performs the
download and the user can verify the published `<file>.apk.sha256` by hand (see
[`INSTALL.fa.md`](INSTALL.fa.md)).
