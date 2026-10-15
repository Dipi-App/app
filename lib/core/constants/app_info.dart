class AppInfo {
  const AppInfo._();

  static const String nameEn = 'Dipi';
  static const String nameFa = 'دیپی';
  static const String storeTitle = 'دیپی | ثبت روزکار و حساب‌کتاب';

  static const String taglineFa = 'دیپی: واژه‌ای پارسی باستانی به معنای نوشتن و ثبت کردن.';

  static const String version = '1.0.0';
  static const int schemaVersion = 1;

  static const String backupPrefix = 'dipi-backup-';
  static const String backupScheme = 'dipi-backup';

  static String backupFileName(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$backupPrefix$y$m$d.json';
  }

  static String exportBaseName(DateTime now) {
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'dipi-$y$m$d';
  }
}
