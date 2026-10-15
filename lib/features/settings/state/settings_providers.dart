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

  Future<void> setAppLock({
    required bool enabled,
    String? pinHash,
    bool biometric = false,
  }) => _persist(
    _current.copyWith(
      appLockEnabled: enabled,
      appLockPinHash: pinHash,
      clearPin: pinHash == null && !enabled,
      biometricEnabled: biometric,
    ),
  );
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

final settingsValueProvider = Provider<AppSettings>(
  (ref) =>
      ref.watch(settingsControllerProvider).value ?? const AppSettings(),
);
