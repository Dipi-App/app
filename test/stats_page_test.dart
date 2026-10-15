import 'package:dipi/core/providers/database_providers.dart';
import 'package:dipi/core/utils/jalali_utils.dart';
import 'package:dipi/data/db/app_database.dart';
import 'package:dipi/data/db/employer_dao.dart';
import 'package:dipi/data/db/payment_dao.dart';
import 'package:dipi/data/db/work_entry_dao.dart';
import 'package:dipi/features/stats/presentation/stats_page.dart';
import 'package:dipi/shared/widgets/simple_bar_chart.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, AppDatabase database) async {
  await tester.binding.setSurfaceSize(const Size(420, 1100));
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
        home: const StatsPage(),
      ),
    ),
  );
  await tester.pump();
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
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

  testWidgets('shows totals and a chart for the filtered range', (tester) async {
    final employerId = await employers.create(
      name: 'کارگاه آفتاب',
      color: 0xFF2E7D6F,
      defaultWageType: 'fixed',
    );
    final today = toIsoDate(DateTime.now());
    await entries.create(
      WorkEntriesCompanion.insert(
        employerId: employerId,
        date: today,
        createdAt: DateTime.now().toIso8601String(),
        startTime: const Value('08:00'),
        endTime: const Value('16:00'),
        wageAmount: const Value(5000000),
      ),
    );
    await payments.create(
      PaymentsCompanion.insert(
        employerId: employerId,
        date: today,
        amount: 2000000,
        createdAt: DateTime.now().toIso8601String(),
        type: const Value('wage'),
      ),
    );

    await _pump(tester, database);

    expect(find.text('جمع بازه'), findsOneWidget);
    expect(find.text('نمودار ماهانه'), findsOneWidget);
    expect(find.text('به تفکیک کارفرما'), findsOneWidget);
    expect(find.byType(SimpleBarChart), findsOneWidget);

    // 5,000,000 − 2,000,000 = 3,000,000 Rial = 300,000 Toman outstanding.
    expect(find.text('طلب شما'), findsWidgets);
    expect(find.textContaining('۳۰۰٬۰۰۰'), findsWidgets);
    expect(find.textContaining('۵۰۰٬۰۰۰'), findsWidgets);
    expect(find.textContaining('۲۰۰٬۰۰۰'), findsWidgets);
    expect(find.text('کارگاه آفتاب'), findsWidgets);

    await _dispose(tester);
  });

  testWidgets('says so when the range has no data', (tester) async {
    await _pump(tester, database);

    expect(find.textContaining('در این بازه داده‌ای نیست'), findsOneWidget);

    await _dispose(tester);
  });
}
