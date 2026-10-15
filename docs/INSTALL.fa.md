# راهنمای نصب دیپی / Dipi install guide

دیپی فقط از **GitHub Releases** منتشر می‌شود. این راهنما با زبان ساده نوشته شده
تا نصب کردن برای همه آسان باشد.

## ۱. دانلود کن

۱. به صفحه‌ی نسخه‌ها برو:
   <https://github.com/mst-ghi/dipi/releases/latest>
۲. از بخش **Assets** فایل `dipi-<version>.apk` را بردار (این فایل روی همه‌ی
   گوشی‌ها نصب می‌شود). اگر می‌خواهی حجم کمتر باشد، فایل مناسب پردازنده‌ی
   گوشی‌ات را بگیر:
   - `dipi-<version>-arm64-v8a.apk` — تقریباً همه‌ی گوشی‌های جدید
   - `dipi-<version>-armeabi-v7a.apk` — گوشی‌های قدیمی‌تر
   - `dipi-<version>-x86_64.apk` — پردازنده‌ی اینتل (کم پیش می‌آید)
۳. هر وقت خواستی می‌توانی درستی فایل را با فایل `...apk.sha256` بررسی کنی
   (بخش ۴).

> نکته: دیپی **خودش چیزی نصب نمی‌کند**. فقط اگر نسخه‌ی تازه‌تری باشد، با یک
> پیام کوتاه به تو خبر می‌دهد و دکمه‌ای می‌گذارد که همین صفحه را در مرورگر
> باز می‌کند. دانلود و نصب را خودت با مرورگر انجام می‌دهی.

## ۲. اجازه‌ی نصب از این منبع را بده

اندروید اجازه نمی‌دهد برنامه‌ای که از اینترنت (نه از بازار) آمده، بی‌اجازه
نصب شود. یک‌بار باید این اجازه را بدهی:

۱. فایل `dipi-<version>.apk` را در گوشی باز کن (از پوشه‌ی **Downloads**).
۲. گوشی پیام می‌دهد که «نصب این برنامه مجاز نیست» یا «برای امنیت...».
۳. روی **تنظیمات** یا **Settings** بزن و گزینه‌ی
   **«اجازه از این منبع» / «Allow from this source»** را روشن کن.
   (روی گوشی‌های جدید فقط برای همان برنامه‌ی فایل‌ها/مرورگر لازم است.)
۴. برگرد و دوباره فایل را باز کن.

## ۳. «More details» و «Install anyway»

اگر Google Play Protect هشدار داد:

۱. روی **More details / جزئیات بیشتر** بزن.
۲. سپس روی **Install anyway / با این حال نصب کن** بزن.

این هشدار طبیعی است؛ برای هر برنامه‌ای که از بیرون گوگل‌پلی نصب می‌شود نشان
داده می‌شود. نگران نباش:

- دیپی **بدون اینترنت** کار می‌کند (تحریم/قطعی اینترنت مهم نیست).
- داده‌هایت **محلی و خصوصی** هستند و جایی فرستاده نمی‌شوند.
- نصب نسخه‌ی جدید، **داده‌های قبلی را پاک نمی‌کند** (چون همه‌ی نسخه‌ها با یک
  کلید امضا ساخته می‌شوند).

سپس روی **نصب / Install** بزن. تمام!

## ۴. بررسی SHA-256 (اختیاری ولی خوب است)

هش SHA-256 یک «اثر انگشت» برای فایل است. اگر با مقدار منتشرشده یکی باشد،
یعنی فایل کامل و دست‌نخورده دانلود شده است. مقدار درست کنار هر فایل در
صفحه‌ی Releases (بخش یادداشت‌ها) نوشته شده و در فایل `...apk.sha256` هم هست.

منظور از `<file>` نام همان فایلی است که دانلود کرده‌ای، مثلاً
`dipi-1.2.3.apk`.

**روش ۱ — روی کامپیوتر:**

```bash
# لینوکس / مک
shasum -a 256 <file>
# یا
sha256sum <file>
```

**ویندوز (PowerShell):**

```powershell
Get-FileHash <file> -Algorithm SHA256
```

**روش ۲ — روی خود گوشی:**

یک برنامه‌ی ساده مثل «Hash Droid» یا هر برنامه‌ی نمایش SHA-256 نصب کن،
فایل را انتخاب کن و مقدار را ببین.

خروجی یک متن ۶۴ حرفی (حروف a تا f و اعداد) است. اگر **دقیقاً** با مقداری که
در Releases نوشته شده یکی بود، فایل سالم است. اگر یکی نبود، فایل را دوباره
دانلود کن (ممکن است دانلود ناقص یا دست‌کاری‌شده باشد).

## ۵. به‌روزرسانی به نسخه‌ی بعدی

۱. در دیپی: **تنظیمات → بررسی نسخه جدید** (یا خودش وقتی برنامه را باز می‌کنی،
   حداکثر روزی یک‌بار بررسی می‌کند).
۲. اگر نسخه‌ی تازه باشد، دیپی شماره‌ی نسخه و «تازه‌ها» را نشان می‌دهد و دکمه‌ی
   **دانلود از گیت‌هاب** را می‌گذارد.
۳. با آن دکمه مرورگر باز می‌شود؛ APK تازه را دانلود کن و مثل بالا نصب کن.
   داده‌هایت سر جایشان می‌مانند.

---

## English (short)

Dipi is distributed **only through GitHub Releases**.

1. Download `dipi-<version>.apk` from the
   [latest release](https://github.com/mst-ghi/dipi/releases/latest). The plain
   `dipi-<version>.apk` works on every phone.
2. Open the file; Android asks you to **allow installs from this source** — turn
   it on for your file manager / browser.
3. If Play Protect warns, tap **More details → Install anyway**. The warning is
   normal for any app installed outside Play.
4. Optionally verify the download against the published **SHA-256**
   (`shasum -a 256 <file>`, `Get-FileHash <file> -Algorithm SHA256`, or a phone
   hashing app). A 64-character match means the file is intact.
5. Dipi itself never installs anything. When a newer version exists it shows a
   short message and a **Download from GitHub** button that opens this page in
   your browser. Installing a new version keeps your data (all releases share one
   signing key).
