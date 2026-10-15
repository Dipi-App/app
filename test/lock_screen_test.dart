import 'package:dipi/core/providers/database_providers.dart';
import 'package:dipi/core/utils/persian_digits.dart';
import 'package:dipi/core/utils/pin_hash.dart';
import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/data/db/key_value_dao.dart';
import 'package:dipi/features/lock/presentation/lock_screen.dart';
import 'package:dipi/features/lock/state/lock_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppDatabase> _databaseWithPin(String pin) async {
  final database = AppDatabase.forTesting(NativeDatabase.memory());
  final salt = generatePinSalt();
  final dao = KeyValueDao(database);
  await dao.write('appLockEnabled', 'true');
  await dao.write('appLockSalt', salt);
  await dao.write('appLockPinHash', hashPin(pin, salt));
  await dao.write('appLockPinLength', '${pin.length}');
  return database;
}

Future<void> _pump(WidgetTester tester, AppDatabase database) async {
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  // Turning animations off keeps the assertions deterministic and exercises
  // the reduce-motion code path.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        locale: const Locale('fa'),
        supportedLocales: const [Locale('fa')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: (context, child) =>
            Directionality(textDirection: TextDirection.rtl, child: child!),
        home: const LockScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

Future<void> _type(WidgetTester tester, String digits) async {
  for (final digit in digits.split('')) {
    await tester.tap(find.text(toPersianDigits(digit)).last);
    await tester.pump(const Duration(milliseconds: 120));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

bool _locked(WidgetTester tester) {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(LockScreen)),
  );
  return container.read(appLockProvider);
}

void main() {
  testWidgets('the right pin unlocks the app', (tester) async {
    final database = await _databaseWithPin('1234');
    addTearDown(database.close);

    await _pump(tester, database);
    expect(find.byType(LockScreen), findsOneWidget);
    expect(_locked(tester), isTrue);

    await _type(tester, '1234');

    expect(_locked(tester), isFalse);

    await _dispose(tester);
  });

  testWidgets('a wrong pin keeps the lock and shows an error', (tester) async {
    final database = await _databaseWithPin('1234');
    addTearDown(database.close);

    await _pump(tester, database);
    await _type(tester, '9999');

    expect(_locked(tester), isTrue);
    expect(find.text('رمز نادرست است.'), findsOneWidget);

    // And the correct pin still works afterwards.
    await _type(tester, '1234');
    expect(_locked(tester), isFalse);

    await _dispose(tester);
  });

  testWidgets('digits are shown as persian', (tester) async {
    final database = await _databaseWithPin('4321');
    addTearDown(database.close);

    await _pump(tester, database);

    for (final digit in ['۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹', '۰']) {
      expect(find.text(digit), findsOneWidget);
    }
    expect(_locked(tester), isTrue);

    await _dispose(tester);
  });
}
