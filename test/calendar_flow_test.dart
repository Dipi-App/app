import 'package:dipi/app.dart';
import 'package:dipi/core/providers/database_providers.dart';
import 'package:dipi/core/utils/jalali_utils.dart';
import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/data/db/employer_dao.dart';
import 'package:dipi/data/db/work_entry_dao.dart';
import 'package:dipi/features/calendar/presentation/widgets/day_cell.dart';
import 'package:dipi/shared/widgets/money_field.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpApp(WidgetTester tester, AppDatabase database) async {
  tester.view.devicePixelRatio = 1.0;
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  await tester.pumpWidget(
    ProviderScope(
      overrides: [databaseProvider.overrideWithValue(database)],
      child: const DipiApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 1400));
  await tester.pump(const Duration(milliseconds: 700));
}

Future<void> _settle(WidgetTester tester, [int ms = 500]) async {
  await tester.pump();
  await tester.pump(Duration(milliseconds: ms));
}

/// Unmounts the app inside the test body and flushes the zero-duration timers
/// drift schedules when its stream queries are closed.
Future<void> _disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

Finder _todayCell() => find.byWidgetPredicate(
  (widget) => widget is DayCell && isSameDay(widget.day, DateTime.now()),
);

void main() {
  late AppDatabase database;
  late EmployerDao employers;
  late WorkEntryDao entries;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    employers = EmployerDao(database);
    entries = WorkEntryDao(database);
  });

  tearDown(() => database.close());

  testWidgets('tapping a day opens the day sheet with its entries', (
    tester,
  ) async {
    final employerId = await employers.create(
      name: 'کارگاه آفتاب',
      color: 0xFF2E7D6F,
      defaultWageType: 'fixed',
    );
    await entries.create(
      WorkEntriesCompanion.insert(
        employerId: employerId,
        date: toIsoDate(DateTime.now()),
        createdAt: DateTime.now().toIso8601String(),
        place: const Value('کارگاه ۲'),
        job: const Value('بنایی'),
        wageAmount: const Value(50000),
      ),
    );

    await _pumpApp(tester, database);
    expect(_todayCell(), findsOneWidget);

    await tester.tap(_todayCell());
    await _settle(tester);

    expect(find.text('افزودن روزکار'), findsOneWidget);
    expect(find.text('کارگاه آفتاب'), findsOneWidget);
    expect(find.textContaining('کارگاه ۲'), findsWidgets);
    expect(find.textContaining('۵٬۰۰۰ تومان'), findsWidgets);

    await _disposeApp(tester);
  });

  testWidgets('the entry form prefills the wage from the employer default', (
    tester,
  ) async {
    await employers.create(
      name: 'کارگاه ماه',
      color: 0xFF2F6FBF,
      defaultWageType: 'fixed',
      defaultDailyWage: 700000,
    );

    await _pumpApp(tester, database);

    await tester.tap(_todayCell());
    await _settle(tester);

    await tester.tap(find.text('افزودن روزکار'));
    await _settle(tester);
    expect(find.text('روزکار تازه'), findsOneWidget);
    expect(find.text(formatJalaliFullLong(DateTime.now())), findsWidgets);

    await tester.tap(find.byType(DropdownButtonFormField<int>));
    await _settle(tester);
    await tester.tap(find.text('کارگاه ماه').last);
    await _settle(tester);

    final wageInput = tester.widget<TextField>(
      find.descendant(
        of: find.byType(MoneyField).first,
        matching: find.byType(TextField),
      ),
    );
    expect(wageInput.controller!.text, '۷۰٬۰۰۰');

    await _disposeApp(tester);
  });
}
