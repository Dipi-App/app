import '../../../core/utils/money.dart';
import '../../../domain/enums.dart';

class AppSettings {
  const AppSettings({
    this.currencyUnit = CurrencyUnit.toman,
    this.themeChoice = ThemeChoice.system,
    this.appLockEnabled = false,
    this.appLockPinHash,
    this.appLockSalt,
    this.appLockPinLength,
    this.biometricEnabled = false,
    this.lastBackupAt,
    this.lastBackupReminderAt,
    this.onboardingSeen = false,
    this.voiceHintsEnabled = true,
    this.coachMarksSeen = const {},
    this.lastUpdateCheckAt,
  });

  final CurrencyUnit currencyUnit;
  final ThemeChoice themeChoice;
  final bool appLockEnabled;
  final String? appLockPinHash;
  final String? appLockSalt;
  final int? appLockPinLength;
  final bool biometricEnabled;

  /// ISO time of the last successful backup (manual or automatic).
  final String? lastBackupAt;
  final String? lastBackupReminderAt;

  /// True once the first-run slideshow has been completed or skipped.
  final bool onboardingSeen;

  /// Whether the little speaker buttons read help text aloud.
  final bool voiceHintsEnabled;

  /// Ids of the one-time coach-mark tips the user has already seen.
  final Set<String> coachMarksSeen;

  /// ISO time of the last successful update check, for the 24-hour limit.
  final String? lastUpdateCheckAt;

  DateTime? get lastUpdateCheckDate => lastUpdateCheckAt == null
      ? null
      : DateTime.tryParse(lastUpdateCheckAt!);

  DateTime? get lastBackupDate =>
      lastBackupAt == null ? null : DateTime.tryParse(lastBackupAt!);

  bool get hasPin => (appLockPinHash ?? '').isNotEmpty;

  AppSettings copyWith({
    CurrencyUnit? currencyUnit,
    ThemeChoice? themeChoice,
    bool? appLockEnabled,
    String? appLockPinHash,
    String? appLockSalt,
    int? appLockPinLength,
    bool clearPin = false,
    bool? biometricEnabled,
    String? lastBackupAt,
    String? lastBackupReminderAt,
    bool? onboardingSeen,
    bool? voiceHintsEnabled,
    Set<String>? coachMarksSeen,
    String? lastUpdateCheckAt,
  }) {
    return AppSettings(
      currencyUnit: currencyUnit ?? this.currencyUnit,
      themeChoice: themeChoice ?? this.themeChoice,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appLockPinHash: clearPin ? null : (appLockPinHash ?? this.appLockPinHash),
      appLockSalt: clearPin ? null : (appLockSalt ?? this.appLockSalt),
      appLockPinLength: clearPin
          ? null
          : (appLockPinLength ?? this.appLockPinLength),
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      lastBackupAt: lastBackupAt ?? this.lastBackupAt,
      lastBackupReminderAt: lastBackupReminderAt ?? this.lastBackupReminderAt,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      voiceHintsEnabled: voiceHintsEnabled ?? this.voiceHintsEnabled,
      coachMarksSeen: coachMarksSeen ?? this.coachMarksSeen,
      lastUpdateCheckAt: lastUpdateCheckAt ?? this.lastUpdateCheckAt,
    );
  }

  Map<String, String> toMap() => {
    'currencyUnit': currencyUnit.name,
    'themeChoice': themeChoice.name,
    'appLockEnabled': appLockEnabled.toString(),
    'appLockPinHash': appLockPinHash ?? '',
    'appLockSalt': appLockSalt ?? '',
    'appLockPinLength': appLockPinLength?.toString() ?? '',
    'biometricEnabled': biometricEnabled.toString(),
    'lastBackupAt': lastBackupAt ?? '',
    'lastBackupReminderAt': lastBackupReminderAt ?? '',
    'onboardingSeen': onboardingSeen.toString(),
    'voiceHintsEnabled': voiceHintsEnabled.toString(),
    'coachMarksSeen': coachMarksSeen.join(','),
    'lastUpdateCheckAt': lastUpdateCheckAt ?? '',
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
      appLockSalt: nonEmpty('appLockSalt'),
      appLockPinLength: int.tryParse(map['appLockPinLength'] ?? ''),
      biometricEnabled: map['biometricEnabled'] == 'true',
      lastBackupAt: nonEmpty('lastBackupAt'),
      lastBackupReminderAt: nonEmpty('lastBackupReminderAt'),
      onboardingSeen: map['onboardingSeen'] == 'true',
      voiceHintsEnabled: map['voiceHintsEnabled'] != 'false',
      coachMarksSeen: (map['coachMarksSeen'] ?? '')
          .split(',')
          .where((id) => id.isNotEmpty)
          .toSet(),
      lastUpdateCheckAt: nonEmpty('lastUpdateCheckAt'),
    );
  }
}
