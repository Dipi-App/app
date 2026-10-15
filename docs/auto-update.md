# به‌روزرسانی خودکار برنامه / Auto-update

## به زبان ساده (فارسی)

دیپی خودش می‌فهمد که نسخه‌ی تازه‌تری هست و آن را نصب می‌کند. کاربر لازم نیست
چیزی دانلود کند یا به سایت برود.

### چطور کار می‌کند؟

۱. وقتی برنامه باز می‌شود، **حداکثر هر ۶ ساعت یک‌بار** نسخه‌ی آخر را از
   **GitHub Releases** می‌پرسد (`api.github.com/.../releases/latest`). اگر
   اینترنت نباشد یا پاسخ نیاید، **هیچ پیامی نشان نمی‌دهد**.
۲. نسخه‌ی تگ (مثل `v1.2.0`) را با نسخه‌ی نصب‌شده مقایسه می‌کند (مقایسه‌ی
   عددی درست، نه متن‌به‌متن).
۳. اگر نسخه‌ی تازه‌تر بود، فایل APK مناسب **پردازنده‌ی همین گوشی** را انتخاب
   می‌کند (`arm64-v8a`، `armeabi-v7a`، `x86_64`)؛ اگر پیدا نشد، فایل
   `universal` را می‌گیرد.
۴. دانلود:
   - روی **وای‌فای** خودش شروع می‌کند.
   - روی **اینترنت موبایل** شروع نمی‌کند و اول می‌پرسد.
   - با قطع‌شدن اینترنت یا بستن برنامه، دفعه‌ی بعد از همان‌جا ادامه می‌دهد
     (دانلود با `Range`).
۵. بعد از دانلود، **SHA-256** فایل را با فایل `.sha256` کنارش مقایسه می‌کند.
   اگر یکی نبود، فایل پاک می‌شود و دوباره تلاش می‌کند. **هرگز فایل بررسی‌نشده
   نصب نمی‌شود.**
۶. آیکون سبز طلایی در نوار بالای صفحه («آماده نصب») نمایش داده می‌شود و با
   زدن آن، دکمه‌ی «نصب نسخه جدید» می‌آید.
۷. اگر گوشی اجازه‌ی «نصب از منابع ناشناس» بدهد، پنجره‌ی نصب باز می‌شود.
   **داده‌های شما پاک نمی‌شود**، چون امضای برنامه یکی است.

آیکون کوچک در نوار بالا وضعیت را نشان می‌دهد:

| وضعیت | آیکون |
| --- | --- |
| نسخه‌ی تازه هست، دانلود نشده | فلش دانلود |
| در حال دانلود | حلقه‌ی پیشرفت دور آیکون |
| آماده‌ی نصب | تیک طلایی با نبض آرام |
| خطا | علامت هشدار (زدن = تلاش دوباره) |

اگر مودال باز است و کاربر وسط یک فرم (ثبت روزکار، پرداخت، …) باشد، مودال
باز نمی‌شود تا از فرم بیرون بیاید. اگر یک‌بار «بعداً» بزند، تا پایان همان
اجرا دوباره خودش باز نمی‌شود (فقط آیکون نبض می‌زند).

### چطور نسخه‌ی جدید منتشر کنم؟

مثل همیشه: یک کارت با پیام استاندارد روی `main` بفرست (`feat:` یا `fix:`).
ربات این کارها را انجام می‌دهد:

- شماره‌ی نسخه و `versionCode` را بالا می‌برد،
- APK‌های `dipi-vX.Y.Z-<abi>.apk` و `dipi-vX.Y.Z-universal.apk` را می‌سازد،
- برای هر APK یک فایل `...apk.sha256` می‌سازد (`<hash>  <filename>`)،
- یادداشت‌های نسخه را از پیام‌های کارت‌ها می‌سازد،
- Release را با همین فایل‌ها منتشر می‌کند.

> ⚠️ همه‌ی نسخه‌ها باید با **یک کلید امضا** ساخته شوند، وگرنه نصب خودکار کار
> نمی‌کند. اگر Secretها نباشند، ربات با خطا متوقف می‌شود. راهنمای کلید در
> [`RELEASE.md`](RELEASE.md) هست.

### چطور امتحان کنم؟

۱. نسخه‌ی `1.0.0` را روی گوشی نصب کن (از صفحه‌ی Releases).
۲. یک تغییر کوچک بده و `1.0.1` را منتشر کن (کارت `fix: ...`).
۳. برنامه را باز کن:
   - آیکون دانلود در نوار بالا باید بیاید (روی وای‌فای خودش شروع می‌کند).
   - اگر روی اینترنت موبایل باشی، اول می‌پرسد.
   - پیشرفت دانلود و درصد باید درست باشد.
   - بعد از دانلود، تیک طلایی بیاید و مودال «آماده نصب» باز شود.
   - «نصب نسخه جدید» را بزن و نصب را کامل کن.
۴. برنامه دوباره باز می‌شود؛ یک پیام کوتاه «نسخه جدید نصب شد» می‌بینی و
   داده‌های قبلی سرجایشان هستند.

برای امتحان سریع بدون صبر ۶ ساعت، از **تنظیمات → درباره دیپی → بررسی نسخه
جدید** استفاده کن (بررسی دستی محدودیت زمانی ندارد).

---

## In English

Dipi updates itself from its **latest GitHub Release**. On start (at most once
every 6 hours) it asks `api.github.com/.../releases/latest`, compares the tag
with the installed version using a real numeric semver compare, picks the APK
for the phone's ABI (or `universal`), and downloads it with progress + HTTP
`Range` resume. The download starts by itself on Wi-Fi; on mobile it asks first
unless the Wi-Fi-only switch is off. The file is verified against the published
`.sha256` and the file is deleted on any mismatch — an unchecked APK is never
installed. A header icon tracks the state (available / downloading / ready /
error) and a modal drives download, cancel, retry and install. The install is
handed to the Android installer via `open_filex`; the "install unknown apps"
permission is handled through a small method channel that opens the right system
page. Because the signature is unchanged, user data is kept.

Publish: push a Conventional Commit to `main` (as before). The workflow now also
writes `<apk>.sha256` files, builds release notes from the commits, keeps the
`dipi-vX.Y.Z-<abi>.apk` / `-universal.apk` naming, and requires the shared
keystore. See [`RELEASE.md`](RELEASE.md).

Test: install `1.0.0`, publish `1.0.1`, open the app and watch the icon, the
progress, the modal and the install. Use **Settings → About → بررسی نسخه جدید**
for a manual check that ignores the 6-hour window.
