import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/database_providers.dart';
import '../../../core/utils/money.dart';
import '../../../domain/enums.dart';
import '../domain/app_settings.dart';

class SettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final dao = ref.watch(keyValueDaoProvider);
    return AppSettings.fromMap(await dao.all());
  }

  Future<void> _persist(AppSettings next) async {
    state = AsyncData(next);
    final dao = ref.read(keyValueDaoProvider);
    for (final entry in next.toMap().entries) {
      if (entry.value.isEmpty) {
        await dao.remove(entry.key);
      } else {
        await dao.write(entry.key, entry.value);
      }
    }
  }

  AppSettings get _current => state.requireValue;

  Future<void> setCurrencyUnit(CurrencyUnit unit) =>
      _persist(_current.copyWith(currencyUnit: unit));

  Future<void> setThemeChoice(ThemeChoice choice) =>
      _persist(_current.copyWith(themeChoice: choice));

  Future<void> setAutoBackup(bool enabled) =>
      _persist(_current.copyWith(autoBackupEnabled: enabled));

  Future<void> setLastBackupAt(DateTime at) =>
      _persist(_current.copyWith(lastBackupAt: at.toIso8601String()));

  Future<void> setLastBackupReminderAt(DateTime at) =>
      _persist(_current.copyWith(lastBackupReminderAt: at.toIso8601String()));

  Future<void> setDriveAccount(String? email) => _persist(
    email == null
        ? _current.copyWith(clearDriveAccount: true)
        : _current.copyWith(driveAccountEmail: email),
  );

  /// Applies the settings carried inside a restored backup.
  Future<void> applyImported(Map<String, String> values) {
    final imported = AppSettings.fromMap(values);
    return _persist(
      _current.copyWith(
        currencyUnit: imported.currencyUnit,
        themeChoice: imported.themeChoice,
      ),
    );
  }

  Future<void> setAppLock({
    required bool enabled,
    String? pinHash,
    String? pinSalt,
    int? pinLength,
    bool biometric = false,
  }) => _persist(
    _current.copyWith(
      appLockEnabled: enabled,
      appLockPinHash: pinHash,
      appLockSalt: pinSalt,
      appLockPinLength: pinLength,
      clearPin: pinHash == null && !enabled,
      biometricEnabled: biometric,
    ),
  );

  Future<void> setBiometricEnabled(bool enabled) =>
      _persist(_current.copyWith(biometricEnabled: enabled));

  Future<void> setOnboardingSeen(bool seen) =>
      _persist(_current.copyWith(onboardingSeen: seen));

  Future<void> setVoiceHintsEnabled(bool enabled) =>
      _persist(_current.copyWith(voiceHintsEnabled: enabled));

  Future<void> setAutoUpdateWifiOnly(bool enabled) =>
      _persist(_current.copyWith(autoUpdateWifiOnly: enabled));

  Future<void> setLastUpdateCheckAt(DateTime at) =>
      _persist(_current.copyWith(lastUpdateCheckAt: at.toIso8601String()));

  Future<void> markCoachMarkSeen(String id) {
    if (_current.coachMarksSeen.contains(id)) return Future.value();
    return _persist(
      _current.copyWith(coachMarksSeen: {..._current.coachMarksSeen, id}),
    );
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

final settingsValueProvider = Provider<AppSettings>(
  (ref) =>
      ref.watch(settingsControllerProvider).value ?? const AppSettings(),
);
