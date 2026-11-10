# به‌روزرسانی دیپی / Update

## به زبان ساده (فارسی)

دیپی خودش می‌فهمد نسخه‌ی تازه‌تری هست. اگر نسخه‌ی تازه باشد، شماره‌ی نسخه و
«تازه‌ها» را نشان می‌دهد و دکمه‌ی **«دانلود و نصب»** می‌گذارد. تا تو این دکمه را
نزنی، هیچ فایلی دانلود و هیچ چیزی نصب نمی‌شود.

### چطور کار می‌کند؟

۱. وقتی برنامه باز می‌شود، **حداکثر روزی یک‌بار** نسخه‌ی آخر را از
   **GitHub Releases** می‌پرسد
   (`https://api.github.com/repos/Dipi-App/app/releases/latest`).
۲. نسخه‌ی تگ (مثل `v1.8.0`) را با نسخه‌ی نصب‌شده مقایسه می‌کند (مقایسه‌ی
   عددی درست، نه متن‌به‌متن).
۳. اگر نسخه‌ی تازه‌تر نبود، **هیچ پیامی نشان نمی‌دهد**.
۴. اگر نسخه‌ی تازه‌تر بود، پنجره‌ی فارسی باز می‌شود: نسخه، «تازه‌ها» و دکمه‌ی
   **«دانلود و نصب»**.
۵. با زدن دکمه، برنامه فایل مناسب پردازنده‌ی گوشی را از گیت‌هاب دانلود می‌کند
   (نوار پیشرفت نشان داده می‌شود).
۶. پیش از نصب، برنامه خودش بررسی می‌کند که فایل:
   - همان بسته‌ی دیپی باشد (نه برنامه‌ی دیگر)،
   - شماره‌ی نسخه‌اش از نسخه‌ی نصب‌شده بیشتر باشد،
   - با همان کلیدی امضا شده باشد که نسخه‌ی نصب‌شده دارد.
   اگر SHA-256 منتشرشده در گیت‌هاب موجود باشد، آن هم بررسی می‌شود.
۷. اگر همه‌چیز درست بود، پنجره‌ی نصب اندروید باز می‌شود و **خودت** نصب را تأیید
   می‌کنی. داده‌هایت سر جایشان می‌مانند.

آیکون کوچک فلش دانلود در نوار بالای صفحه هم تا وقتی نسخه‌ی تازه هست نمایش داده
می‌شود؛ با زدنش همان پنجره باز می‌شود.

### اجازه‌ی نصب

بار اول، اندروید برای نصب از بیرون فروشگاه یک اجازه می‌خواهد. دیپی توضیح می‌دهد
و دکمه‌ی **«رفتن به تنظیمات»** را می‌گذارد تا گزینه‌ی «نصب برنامه‌های ناشناس» را
برای دیپی روشن کنی. بعد از برگشتن، دانلود خودش شروع می‌شود. این اجازه فقط برای
همین نصب است؛ نصب همچنان با تأیید خودت انجام می‌شود.

### بررسی دستی

از **تنظیمات → بررسی نسخه جدید** می‌توانی هر وقت خواستی بررسی کنی. بررسی دستی
محدودیت روزی یک‌بار را نادیده می‌گیرد. اگر اینترنت نباشد، پیام «بررسی انجام نشد»
می‌آید و برنامه کرش نمی‌کند.

### اگر دانلود یا نصب نشد

- اتصال اینترنت را بررسی کن و **«تلاش دوباره»** را بزن.
- اگر پنجره‌ی نصب باز نشد، در پنجره‌ی نسخه‌ی تازه گزینه‌ی **«باز کردن صفحه انتشار
  در مرورگر»** هم هست؛ می‌توانی مثل قبل APK را دستی دانلود و نصب کنی
  ([راهنمای نصب](INSTALL.fa.md)).
- اگر برنامه در پس‌زمینه بود، ممکن است به‌جای پنجره‌ی نصب یک **اعلان** ببینی؛
  روی همان بزن.

### چرا نصب خودکار (بی‌صدا) نداریم؟

چون امنیت مهم‌تر است:

- هیچ فایلی بدون زدن دکمه توسط تو دانلود نمی‌شود.
- فایل ناشناس یا با امضای دیگر هرگز به نصب‌کننده داده نمی‌شود.
- تأیید نهایی همیشه با خود اندروید و خود توست.

### چطور نسخه‌ی جدید منتشر کنم؟

یک تگ نسخه بزن و آن را push کن:

```bash
git tag v1.2.3
git push origin v1.2.3
```

(یا کارت‌های استاندارد روی `main` بفرست.) راهنمای کامل در
[`RELEASE.md`](RELEASE.md) است.

---

## In English

Dipi checks the **latest GitHub Release** on start, at most once every 24 hours,
at `api.github.com/repos/Dipi-App/app/releases/latest`. It compares the tag with
the installed version using a numeric semver compare and stays quiet when there
is nothing new.

When a newer release exists, the dialog offers **Download and install**. The APK
for the device ABI is downloaded only after that tap, with progress. Before
Android's installer is opened, the app verifies that the file is the same
package, has a higher `versionCode`, and is signed with the installed app's
certificate; GitHub's SHA-256 digest is checked when present. Android then shows
its own install confirmation, so nothing is installed silently.

On first use Android requires "install unknown apps" permission for Dipi; the
dialog explains it and opens the exact settings page. If the app is in the
background when the file is ready, a notification opens the confirmation. The
GitHub release page remains available as a browser fallback.

Network and API errors never crash the app: automatic checks stay silent, and a
manual check reports that it could not run. A missing repository (HTTP 404) is
now an error rather than a false "up to date", which is what previously hid a
stale owner/repo in the update feed.

A manual check is available in **Settings → بررسی نسخه جدید** and ignores the
24-hour window.
