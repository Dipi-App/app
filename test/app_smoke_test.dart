import 'package:dipi/app.dart';
import 'package:dipi/core/providers/database_providers.dart';
import 'package:dipi/core/theme/app_theme.dart';
import 'package:dipi/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpApp(WidgetTester tester, AppDatabase database) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const DipiApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1200));
  await tester.pump(const Duration(milliseconds: 600));
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

    expect(find.text('تقویم'), findsWidgets);
    expect(find.text('کارفرماها'), findsWidgets);
    expect(find.text('پرداخت‌ها'), findsWidgets);
    expect(find.text('آمار'), findsWidgets);
    expect(find.text('تنظیمات'), findsWidgets);

    final direction = Directionality.of(
      tester.element(find.byType(NavigationBar)),
    );
    expect(direction, TextDirection.rtl);

    final text = tester.widget<Text>(find.text('تقویم').last);
    expect(text.style?.fontFamily, anyOf(isNull, AppTheme.fontFamily));

    await _disposeApp(tester);
  });

  testWidgets('switching tabs shows each section', (tester) async {
    await _pumpApp(tester, database);

    await tester.tap(find.text('تنظیمات').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('واحد پول'), findsOneWidget);
    expect(find.text('درباره دیپی'), findsOneWidget);

    await tester.tap(find.text('آمار').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.textContaining('آماری برای نمایش نیست'), findsOneWidget);

    await _disposeApp(tester);
  });
}
