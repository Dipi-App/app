import 'package:dipi/core/providers/database_providers.dart';
import 'package:dipi/core/theme/app_theme.dart';
import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/features/onboarding/presentation/onboarding_page.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester,
  AppDatabase database,
  VoidCallback onDone,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: OnboardingPage(onFinish: onDone),
        ),
      ),
    ),
  );
  // Let the settings controller finish loading before interacting.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pumpAndSettle();
}

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  testWidgets('walks through the slides and can be skipped', (tester) async {
    var done = false;
    await _pump(tester, database, () => done = true);

    expect(find.text('به دیپی خوش آمدی'), findsOneWidget);

    await tester.tap(find.text('بعدی'));
    await tester.pumpAndSettle();
    expect(find.text('هر روز کار، یک روزکار'), findsOneWidget);

    await tester.tap(find.text('رد کردن'));
    await tester.pumpAndSettle();
    expect(done, isTrue);
  });
}
