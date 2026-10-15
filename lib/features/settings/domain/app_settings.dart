import '../../../core/utils/money.dart';
import '../../../domain/enums.dart';

class AppSettings {
  const AppSettings({
    this.currencyUnit = CurrencyUnit.toman,
    this.themeChoice = ThemeChoice.system,
    this.appLockEnabled = false,
    this.appLockPinHash,
    this.biometricEnabled = false,
    this.autoBackupEnabled = false,
    this.lastBackupAt,
    this.lastBackupReminderAt,
    this.driveAccountEmail,
  });

  final CurrencyUnit currencyUnit;
  final ThemeChoice themeChoice;
  final bool appLockEnabled;
  final String? appLockPinHash;
  final bool biometricEnabled;
  final bool autoBackupEnabled;
  final String? lastBackupAt;
  final String? lastBackupReminderAt;
  final String? driveAccountEmail;

  DateTime? get lastBackupDate =>
      lastBackupAt == null ? null : DateTime.tryParse(lastBackupAt!);

  bool get hasPin => (appLockPinHash ?? '').isNotEmpty;

  AppSettings copyWith({
    CurrencyUnit? currencyUnit,
    ThemeChoice? themeChoice,
    bool? appLockEnabled,
    String? appLockPinHash,
    bool clearPin = false,
    bool? biometricEnabled,
    bool? autoBackupEnabled,
    String? lastBackupAt,
    String? lastBackupReminderAt,
    String? driveAccountEmail,
    bool clearDriveAccount = false,
  }) {
    return AppSettings(
      currencyUnit: currencyUnit ?? this.currencyUnit,
      themeChoice: themeChoice ?? this.themeChoice,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appLockPinHash: clearPin ? null : (appLockPinHash ?? this.appLockPinHash),
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      autoBackupEnabled: autoBackupEnabled ?? this.autoBackupEnabled,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      lastBackupReminderAt: lastBackupReminderAt ?? this.lastBackupReminderAt,
      driveAccountEmail:
          clearDriveAccount ? null : (driveAccountEmail ?? this.driveAccountEmail),
    );
  }

  Map<String, String> toMap() => {
    'currencyUnit': currencyUnit.name,
    'themeChoice': themeChoice.name,
    'appLockEnabled': appLockEnabled.toString(),
    'appLockPinHash': appLockPinHash ?? '',
    'biometricEnabled': biometricEnabled.toString(),
    'autoBackupEnabled': autoBackupEnabled.toString(),
    'lastBackupAt': lastBackupAt ?? '',
    'lastBackupReminderAt': lastBackupReminderAt ?? '',
    'driveAccountEmail': driveAccountEmail ?? '',
  };

  static AppSettings fromMap(Map<String, String?> map) {
    String? nonEmpty(String key) {
      final value = map[key];
      return (value == null || value.isEmpty) ? null : value;
    }

    return AppSettings(
      currencyUnit: CurrencyUnit.fromName(map['currencyUnit']),
      themeChoice: ThemeChoice.fromName(map['themeChoice']),
      appLockEnabled: map['appLockEnabled'] == 'true',
      appLockPinHash: nonEmpty('appLockPinHash'),
      biometricEnabled: map['biometricEnabled'] == 'true',
      autoBackupEnabled: map['autoBackupEnabled'] == 'true',
      lastBackupAt: nonEmpty('lastBackupAt'),
      lastBackupReminderAt: nonEmpty('lastBackupReminderAt'),
      driveAccountEmail: nonEmpty('driveAccountEmail'),
    );
  }
}
