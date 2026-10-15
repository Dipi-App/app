import 'package:flutter/material.dart';

/// All the how-to text lives here so it is easy to edit in one place.
/// Keep the words short and plain: the readers may have low literacy.
class HelpTopic {
  const HelpTopic({
    required this.id,
    required this.title,
    required this.icon,
    required this.steps,
    this.intro,
  });

  final String id;
  final String title;
  final IconData icon;

  /// Two or three short steps, in order.
  final List<String> steps;

  /// One friendly sentence shown above the steps.
  final String? intro;

  /// The text the speaker button reads aloud.
  String get speechText {
    final parts = <String>[
      ?intro,
      for (var i = 0; i < steps.length; i++) '${i + 1}. ${steps[i]}',
    ];
    return parts.join('. ');
  }
}

/// The five "how-to cards" requested for the help section, plus a couple of
/// extras for the main screens.
abstract final class HelpContent {
  static const HelpTopic addWorkday = HelpTopic(
    id: 'add-workday',
    title: 'چطور یک روزکار ثبت کنم؟',
    icon: Icons.event_available_outlined,
    intro: 'ثبت روزکار یعنی نوشتن اینکه آن روز برای کی کار کردی.',
    steps: [
      'روی دکمه بزرگ «روزکار» در پایین صفحه بزن.',
      'کارفرما را انتخاب کن. مبلغ دستمزد خودش می‌آید.',
      'اگر خواستی ساعت و محل کار را هم بنویس، بعد «ثبت» را بزن.',
    ],
  );

  static const HelpTopic addPayment = HelpTopic(
    id: 'add-payment',
    title: 'چطور یک پرداخت ثبت کنم؟',
    icon: Icons.receipt_long_outlined,
    intro: 'پرداخت یعنی پولی که کارفرما به تو داده است.',
    steps: [
      'به بخش «پرداخت‌ها» برو.',
      'روی «پرداخت» بزن و کارفرما و مبلغ را بنویس.',
      'تاریخ را بزن و بعد «ثبت» کن.',
    ],
  );

  static const HelpTopic seeBalance = HelpTopic(
    id: 'see-balance',
    title: 'چطور بفهمم چقدر طلب دارم؟',
    icon: Icons.account_balance_wallet_outlined,
    intro: 'سبز یعنی کارفرما به تو بدهکار است، سرخ یعنی تو به او.',
    steps: [
      'به بخش «آمار» برو.',
      'بالای صفحه «مانده کل» را ببین.',
      'برای هر کارفرما، روی نامش بزن تا حساب دقیق را ببینی.',
    ],
  );

  static const HelpTopic makeBackup = HelpTopic(
    id: 'make-backup',
    title: 'چطور پشتیبان بگیرم؟',
    icon: Icons.backup_outlined,
    intro: 'پشتیبان یعنی یک نسخه امن از همه اطلاعات تو. برنامه خودش این کار را می‌کند.',
    steps: [
      'برنامه هر ۱۲ ساعت خودش یک پشتیبان در پوشه Documents/dipi گوشی می‌سازد.',
      'برای پشتیبان فوری: تنظیمات ← پشتیبان‌گیری و بازگردانی ← «پشتیبان‌گیری الان».',
      'اگر گوشی را عوض کردی، با «بازگردانی از فایل» همه چیز برمی‌گردد.',
    ],
  );

  static const HelpTopic exportFile = HelpTopic(
    id: 'export-file',
    title: 'چطور خروجی بگیرم؟',
    icon: Icons.description_outlined,
    intro: 'خروجی یعنی یک فایل که می‌توانی چاپ کنی یا برای کسی بفرستی.',
    steps: [
      'به «تنظیمات» برو و «خروجی گرفتن» را باز کن.',
      'بازه تاریخ و کارفرماها را انتخاب کن.',
      'فرمت را بزن و فایل را ذخیره یا هم‌رسانی کن.',
    ],
  );

  static const HelpTopic calendarOverview = HelpTopic(
    id: 'calendar-overview',
    title: 'تقویم چه چیزهایی را نشان می‌دهد؟',
    icon: Icons.calendar_month_outlined,
    intro: 'هر روز که کار کرده‌ای، با رنگ کارفرما روی تقویم نشان داده می‌شود.',
    steps: [
      'برای دیدن کارهای یک روز، روی آن روز بزن.',
      'برای عوض کردن ماه، انگشت را بکش یا فلش‌ها را بزن.',
      'پایین صفحه، جمع روزها و دستمزد همان ماه است.',
    ],
  );

  static const HelpTopic employers = HelpTopic(
    id: 'employers',
    title: 'کارفرماها چطور کار می‌کنند؟',
    icon: Icons.people_outline,
    intro: 'هر کارفرما یک رنگ دارد و حسابش جدا نگه داشته می‌شود.',
    steps: [
      'روی «کارفرما» بزن و نام و رنگ او را انتخاب کن.',
      'اگر دستمزد روزانه‌اش ثابت است، همان‌جا بنویس تا خودکار پر شود.',
      'حساب هر کارفرما را در همان صفحه جدا ببین.',
    ],
  );

  static const List<HelpTopic> all = [
    addWorkday,
    addPayment,
    seeBalance,
    makeBackup,
    exportFile,
    calendarOverview,
    employers,
  ];

  static HelpTopic? byId(String id) {
    for (final topic in all) {
      if (topic.id == id) return topic;
    }
    return null;
  }
}
