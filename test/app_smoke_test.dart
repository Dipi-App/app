import 'package:dipi/app.dart';
import 'package:dipi/core/help/coach_mark.dart';
import 'package:dipi/core/providers/database_providers.dart';
import 'package:dipi/core/theme/app_theme.dart';
import 'package:dipi/core/widgets/floating_nav_bar.dart';
import 'package:dipi/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpApp(WidgetTester tester, AppDatabase database) async {
  // Turning animations off keeps the assertions deterministic and exercises
  // the reduce-motion code path.
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        coachMarksEnabledProvider.overrideWithValue(false),
      ],
      child: const DipiApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump(const Duration(milliseconds: 600));
  // First run shows the onboarding slides; skip them to reach the shell.
  if (find.text('رد کردن').evaluate().isNotEmpty) {
    await tester.tap(find.text('رد کردن'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// Unmounts the app inside the test body and flushes the zero-duration timers
/// drift schedules when its stream queries are closed.
Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  late AppDatabase database;

  setUp(() => database = AppDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => database.close());

  testWidgets('boots into a right to left persian shell', (tester) async {
    await _pumpApp(tester, database);

    expect(find.byType(FloatingNavBar), findsOneWidget);
    expect(find.text('تقویم'), findsWidgets);
    expect(find.text('کارفرماها'), findsWidgets);
    expect(find.text('پرداخت‌ها'), findsWidgets);
    expect(find.text('آمار'), findsWidgets);
    // The center slot is the add-workday action, not a tab.
    expect(find.text('روزکار'), findsWidgets);

    final direction = Directionality.of(
      tester.element(find.byType(FloatingNavBar)),
    );
    expect(direction, TextDirection.rtl);

    final text = tester.widget<Text>(find.text('تقویم').last);
    expect(text.style?.fontFamily, anyOf(isNull, AppTheme.fontFamily));

    await _disposeApp(tester);
  });

  testWidgets('switching tabs shows each section', (tester) async {
    await _pumpApp(tester, database);

    await tester.tap(find.byTooltip('تنظیمات').hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('واحد پول'), findsOneWidget);
    expect(find.textContaining('پشتیبان'), findsWidgets);

    // tester.pageBack() looks for an English "Back" tooltip; under the Persian
    // locale we tap the material BackButton directly.
    await tester.tap(find.byType(BackButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('آمار').hitTestable());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('جمع بازه'), findsOneWidget);
    expect(find.text('نمودار ماهانه'), findsOneWidget);

    await _disposeApp(tester);
  });
}
