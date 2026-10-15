import 'package:dipi/core/providers/database_providers.dart';
import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/data/db/employer_dao.dart';
import 'package:dipi/data/db/payment_dao.dart';
import 'package:dipi/data/db/work_entry_dao.dart';
import 'package:dipi/features/payments/presentation/settlement_page.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, AppDatabase database, int employerId) async {
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
        home: SettlementPage(employerId: employerId),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _dispose(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  late AppDatabase database;
  late EmployerDao employers;
  late WorkEntryDao entries;
  late PaymentDao payments;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    employers = EmployerDao(database);
    entries = WorkEntryDao(database);
    payments = PaymentDao(database);
  });

  tearDown(() => database.close());

  testWidgets('shows a creditor balance with its breakdown', (tester) async {
    final employerId = await employers.create(
      name: 'کارگاه آفتاب',
      color: 0xFF2E7D6F,
      defaultWageType: 'fixed',
    );
    await entries.create(
      WorkEntriesCompanion.insert(
        employerId: employerId,
        date: '2024-05-12',
        createdAt: DateTime.now().toIso8601String(),
        wageAmount: const Value(5000000),
        outOfPocketAmount: const Value(500000),
      ),
    );
    await payments.create(
      PaymentsCompanion.insert(
        employerId: employerId,
        date: '2024-05-20',
        amount: 2000000,
        createdAt: DateTime.now().toIso8601String(),
        type: const Value('wage'),
      ),
    );

    await _pump(tester, database, employerId);

    // 5,000,000 + 500,000 − 2,000,000 = 3,500,000 Rial = 350,000 Toman.
    expect(find.text('طلبکار'), findsWidgets);
    expect(find.textContaining('۳۵۰٬۰۰۰'), findsWidgets);
    expect(find.textContaining('۵۰۰٬۰۰۰'), findsWidgets);

    await _dispose(tester);
  });

  testWidgets('shows a debtor balance after a big advance', (tester) async {
    final employerId = await employers.create(
      name: 'آقای رضایی',
      color: 0xFFC0562B,
      defaultWageType: 'fixed',
    );
    await entries.create(
      WorkEntriesCompanion.insert(
        employerId: employerId,
        date: '2024-05-12',
        createdAt: DateTime.now().toIso8601String(),
        wageAmount: const Value(1000000),
      ),
    );
    await payments.create(
      PaymentsCompanion.insert(
        employerId: employerId,
        date: '2024-05-13',
        amount: 3000000,
        createdAt: DateTime.now().toIso8601String(),
        type: const Value('advance'),
      ),
    );

    await _pump(tester, database, employerId);

    expect(find.text('بدهکار'), findsWidgets);
    // 1,000,000 − 3,000,000 = −2,000,000 Rial = 200,000 Toman owed.
    expect(find.textContaining('۲۰۰٬۰۰۰'), findsWidgets);

    await _dispose(tester);
  });

  testWidgets('reports pending wages that are not in the balance', (
    tester,
  ) async {
    final employerId = await employers.create(
      name: 'شرکت آبان',
      color: 0xFF2F6FBF,
      defaultWageType: 'variable',
    );
    await entries.create(
      WorkEntriesCompanion.insert(
        employerId: employerId,
        date: '2024-05-12',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );

    await _pump(tester, database, employerId);

    expect(find.text('تسویه'), findsWidgets);
    expect(find.textContaining('۱ روزکار با دستمزد نامعلوم'), findsOneWidget);

    await _dispose(tester);
  });
}
