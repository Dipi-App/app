import 'dart:math';

import 'package:drift/drift.dart' show Value;

import '../core/theme/app_colors.dart';
import '../core/utils/jalali_utils.dart';
import '../core/utils/money.dart';
import '../core/utils/persian_digits.dart';
import '../data/db/app_database.dart';
import '../data/db/key_value_dao.dart';
import '../domain/allocation.dart';
import '../domain/enums.dart';
import '../domain/settlement.dart';

/// True only in demo builds (`flutter run --dart-define=DIPI_DEMO=true`).
///
/// A const `false` in normal builds: the compiler drops the call site, so every
/// string below is tree-shaken out of the release APK.
const bool kDemoMode = bool.fromEnvironment('DIPI_DEMO');

/// Fills an empty database with deterministic, fictional Persian data.
///
/// Runs only when [kDemoMode] is true and the database has no employers, so a
/// normal release build can never reach it.
Future<void> seedDemoData(AppDatabase db) async {
  if (!kDemoMode) return;
  final existing = await db.select(db.employers).get();
  if (existing.isNotEmpty) return;

  final seeder = _DemoSeeder(db, Random(42));
  await seeder.run();
}

// ---------------------------------------------------------------------------
// Data model of the generated demo.
// ---------------------------------------------------------------------------

/// Per-employer recipe. All money is in Toman here; it is converted to Rial
/// (the canonical storage unit) on the way into the database.
class _Plan {
  const _Plan({
    required this.name,
    required this.color,
    required this.job,
    required this.places,
    required this.wageType,
    required this.dailyWageToman,
    required this.monthlyWorkDays,
    required this.pendingRatio,
    this.manualWagesToman = const [],
    this.note,
    this.fridayCount = 0,
    this.ensureToday = false,
  });

  final String name;
  final int color;
  final String job;
  final List<String> places;
  final WageType wageType;

  /// Employer daily wage (Toman), or null when the employer has none.
  final int? dailyWageToman;

  /// How many workdays to place in each Jalali month of the range.
  final List<int> monthlyWorkDays;

  /// Share of the workdays left without a wage amount (pending).
  final double pendingRatio;

  /// Wages to pick from when [dailyWageToman] is null.
  final List<int> manualWagesToman;

  final String? note;

  /// How many of this employer's workdays fall on a Friday.
  final int fridayCount;

  /// Whether today must be one of this employer's workdays.
  final bool ensureToday;
}

class _WorkDay {
  _WorkDay({
    required this.date,
    required this.place,
    required this.job,
    required this.startMinute,
    required this.durationMinutes,
    required this.pending,
    required this.wageToman,
    required this.pocketToman,
    this.note,
    this.overtime = false,
  });

  final DateTime date;
  final String place;
  final String job;
  final int startMinute;
  final int durationMinutes;
  final bool pending;
  final int wageToman;
  int pocketToman;
  final String? note;
  final bool overtime;
}

class _PaymentSeed {
  const _PaymentSeed(this.type, this.amountToman, this.date);

  final PaymentType type;
  final int amountToman;
  final DateTime date;
}

// ---------------------------------------------------------------------------
// The seeder.
// ---------------------------------------------------------------------------

class _DemoSeeder {
  _DemoSeeder(this._db, this._rng);

  final AppDatabase _db;
  final Random _rng;

  final List<_Plan> _plans = [
    _Plan(
      name: 'استاد احمدی',
      color: EmployerPalette.colors[0],
      job: 'بنایی',
      places: ['ویلا رضایی', 'ساختمان نگین', 'مغازه گلستان'],
      wageType: WageType.fixed,
      dailyWageToman: 2000000,
      monthlyWorkDays: [4, 4, 4, 4],
      pendingRatio: 0.25,
      note: 'کارفرمای قدیمی و خوش‌حساب.',
      fridayCount: 1,
      ensureToday: true,
    ),
    _Plan(
      name: 'شرکت ساختمانی پارس',
      color: EmployerPalette.colors[1],
      job: 'آجرکاری',
      places: ['ساختمان پارس', 'ویلا ساحلی', 'برج نگین'],
      wageType: WageType.fixed,
      dailyWageToman: 2500000,
      monthlyWorkDays: [2, 3, 3, 3],
      pendingRatio: 0,
    ),
    _Plan(
      name: 'استاد نوری',
      color: EmployerPalette.colors[2],
      job: 'نقاشی ساختمان',
      places: ['ساختمان آبی', 'مغازه نرگس'],
      wageType: WageType.fixed,
      dailyWageToman: 1800000,
      monthlyWorkDays: [1, 1, 2, 2],
      pendingRatio: 0.67,
      fridayCount: 1,
    ),
    _Plan(
      name: 'آقای صادقی',
      color: EmployerPalette.colors[3],
      job: 'گچ‌کاری',
      places: ['ویلا آفتاب', 'مغازه میوه‌فروشی'],
      wageType: WageType.variable,
      dailyWageToman: null,
      monthlyWorkDays: [2, 2, 2, 2],
      pendingRatio: 0.5,
      manualWagesToman: [1700000, 1900000, 2100000, 2300000],
    ),
    _Plan(
      name: 'تعاونی ساختمانی البرز',
      color: EmployerPalette.colors[4],
      job: 'کاشی‌کاری',
      places: ['ساختمان البرز', 'ویلا سبز', 'مغازه شهر'],
      wageType: WageType.fixed,
      dailyWageToman: 2200000,
      monthlyWorkDays: [4, 4, 4, 5],
      pendingRatio: 0.9,
      fridayCount: 1,
    ),
    _Plan(
      name: 'استاد قدیمی',
      color: EmployerPalette.colors[5],
      job: 'آجرکاری',
      places: ['ساختمان قدیمی', 'ویلا کوه'],
      wageType: WageType.fixed,
      dailyWageToman: 1700000,
      monthlyWorkDays: [4, 0, 0, 0],
      pendingRatio: 0.5,
    ),
  ];

  static const List<String> _notes = [
    'کار نیمه‌تمام ماند',
    'مصالح را خودم خریدم',
    'باران گرفت و تعطیل شد',
    'با کمک برادرم تمام شد',
    'سفارش فوری بود',
    'نقاشی طبقه دوم',
  ];

  Future<void> run() async {
    final now = DateTime.now();
    final today = dateOnly(now);
    final createdAt = now.toIso8601String();

    final currentMonth = firstDayOfJalaliMonth(today);
    final firstMonth = toJalali(currentMonth).addMonths(-3).withDay(1).toDateTime();
    final months = jalaliMonthsBetween(firstMonth, currentMonth);

    for (final plan in _plans) {
      await _seedEmployer(
        plan: plan,
        months: months,
        today: today,
        createdAt: createdAt,
      );
    }

    await _writeSettings(now);
    await _printSummary();
  }

  Future<void> _seedEmployer({
    required _Plan plan,
    required List<DateTime> months,
    required DateTime today,
    required String createdAt,
  }) async {
    final employerId = await _db
        .into(_db.employers)
        .insert(
          EmployersCompanion.insert(
            name: plan.name,
            color: Value(plan.color),
            note: Value(plan.note),
            defaultWageType: Value(plan.wageType.name),
            defaultDailyWage: Value(
              plan.dailyWageToman == null ? null : _toRial(plan.dailyWageToman!),
            ),
            createdAt: createdAt,
          ),
        );

    final days = _buildDays(plan, months, today);
    if (plan.ensureToday && !days.any((day) => isSameDay(day.date, today))) {
      if (days.isNotEmpty) days.removeLast();
      days.add(_makeDay(plan, today, overtime: false));
      days.sort((a, b) => a.date.compareTo(b.date));
    }
    // Settled employer: drop incidental pocket costs so earned stays a
    // multiple of 100٬000 and payments can match it exactly.
    if (plan.name == 'شرکت ساختمانی پارس') {
      for (final day in days) {
        day.pocketToman = 0;
      }
    }

    for (final day in days) {
      await _db
          .into(_db.workEntries)
          .insert(
            WorkEntriesCompanion.insert(
              employerId: employerId,
              date: toIsoDate(day.date),
              place: Value(day.place),
              job: Value(day.job),
              startTime: Value(_clock(day.startMinute)),
              endTime: Value(_clock(day.startMinute + day.durationMinutes)),
              wageType: Value(
                day.overtime ? WageType.variable.name : plan.wageType.name,
              ),
              wageAmount: Value(day.pending ? null : _toRial(day.wageToman)),
              outOfPocketAmount: Value(_toRial(day.pocketToman)),
              note: Value(day.note),
              createdAt: createdAt,
            ),
          );
    }

    final payments = _buildPayments(plan, days, today);
    for (final payment in payments) {
      await _db
          .into(_db.payments)
          .insert(
            PaymentsCompanion.insert(
              employerId: employerId,
              date: toIsoDate(payment.date),
              amount: _toRial(payment.amountToman),
              type: Value(payment.type.name),
              createdAt: createdAt,
            ),
          );
    }
  }

  List<_WorkDay> _buildDays(_Plan plan, List<DateTime> months, DateTime today) {
    final total = plan.monthlyWorkDays.fold(0, (a, b) => a + b);
    final target = (total * plan.pendingRatio).round();

    final picked = <DateTime>[];
    for (var i = 0; i < months.length; i++) {
      final count = plan.monthlyWorkDays[i];
      if (count <= 0) continue;
      final fridays = i == months.length - 1 ? plan.fridayCount : 0;
      picked.addAll(
        _pickDays(
          month: months[i],
          count: count,
          today: today,
          fridays: fridays,
          includeToday: plan.ensureToday,
        ),
      );
    }
    picked.sort((a, b) => a.compareTo(b));

    final pendingCount = min(target, picked.length);
    final pendingFlags = List<bool>.filled(picked.length, false);
    final order = List<int>.generate(picked.length, (i) => i)..shuffle(_rng);
    for (var i = 0; i < pendingCount; i++) {
      pendingFlags[order[i]] = true;
    }

    // Today must be a paid day so the calendar "paid" screenshot has a card.
    if (plan.ensureToday) {
      for (var i = 0; i < picked.length; i++) {
        if (isSameDay(picked[i], today)) pendingFlags[i] = false;
      }
    }

    return [
      for (var i = 0; i < picked.length; i++)
        _makeDay(
          plan,
          picked[i],
          pending: pendingFlags[i],
          overtime: _rng.nextDouble() < 0.12,
        ),
    ];
  }

  /// Picks [count] days inside one Jalali month, Saturday–Thursday by default
  /// plus [fridays] Fridays. Never goes past [today]. Today is kept free for
  /// every employer except the one whose [includeToday] is set, so "today" has
  /// exactly one workday.
  List<DateTime> _pickDays({
    required DateTime month,
    required int count,
    required DateTime today,
    required int fridays,
    required bool includeToday,
  }) {
    final days = _daysOfMonth(month)
        .where((day) => !day.isAfter(today))
        .where((day) => includeToday || !isSameDay(day, today))
        .toList();
    final weekdayDays = days
        .where((day) => persianWeekdayIndex(day) != 6)
        .toList();
    final fridayDays = days.where((day) => persianWeekdayIndex(day) == 6).toList();

    weekdayDays.shuffle(_rng);
    fridayDays.shuffle(_rng);

    final wantedFridays = min(fridays, fridayDays.length);
    final wantedWeekdays = min(count - wantedFridays, weekdayDays.length);

    final result = <DateTime>[
      ...weekdayDays.take(max(0, wantedWeekdays)),
      ...fridayDays.take(wantedFridays),
    ];
    result.sort((a, b) => a.compareTo(b));
    return result;
  }

  _WorkDay _makeDay(
    _Plan plan,
    DateTime date, {
    bool pending = false,
    required bool overtime,
  }) {
    final duration = overtime ? 11 + _rng.nextInt(2) : 6 + _rng.nextInt(5);
    final startMinute = 7 * 60 + _rng.nextInt(90);
    final place = plan.places[_rng.nextInt(plan.places.length)];
    final wage = plan.dailyWageToman ??
        plan.manualWagesToman[_rng.nextInt(plan.manualWagesToman.length)];
    final pocket = _rng.nextDouble() < 0.08
        ? (2 + _rng.nextInt(8)) * 50000
        : 0;
    final note = _rng.nextDouble() < 0.22
        ? _notes[_rng.nextInt(_notes.length)]
        : null;
    return _WorkDay(
      date: date,
      place: place,
      job: plan.job,
      startMinute: startMinute,
      durationMinutes: duration * 60,
      pending: pending,
      wageToman: wage,
      pocketToman: pocket,
      note: note,
      overtime: overtime,
    );
  }

  List<_PaymentSeed> _buildPayments(
    _Plan plan,
    List<_WorkDay> days,
    DateTime today,
  ) {
    if (days.isEmpty) return const [];
    final pendingDays = days.where((day) => day.pending).toList();
    final earned = days
        .where((day) => !day.pending)
        .fold(0, (sum, day) => sum + day.wageToman);
    final wage = plan.dailyWageToman;

    switch (plan.name) {
      // Fully settled on both ledgers: no pending days, payments = earned.
      case 'شرکت ساختمانی پارس':
        final earned = days.fold<int>(
          0,
          (sum, day) => sum + day.wageToman + day.pocketToman,
        );
        return _spread(earned, 3, [
          PaymentType.wage,
          PaymentType.wage,
          PaymentType.wage,
        ], days, today);
      case 'استاد قدیمی':
        return _spread(
          wage! * pendingDays.length,
          1,
          [PaymentType.wage],
          days,
          today,
        );
      // Pays all but two pending days.
      case 'استاد احمدی':
        final covered = max(0, pendingDays.length - 2);
        return _spread(wage! * covered, 3, [
          PaymentType.wage,
          PaymentType.advance,
          PaymentType.wage,
        ], days, today);
      // Covers every pending day and leaves a half-day credit.
      case 'استاد نوری':
        return _spread(
          wage! * pendingDays.length + wage ~/ 2,
          1,
          [PaymentType.wage],
          days,
          today,
        );
      // No daily wage: a few manual payments against the explicit days.
      case 'آقای صادقی':
        return _spread(earned * 65 ~/ 100, 3, [
          PaymentType.wage,
          PaymentType.advance,
          PaymentType.expenseRefund,
        ], days, today);
      // Big balance: only a small advance.
      default:
        final covered = min(3, max(0, pendingDays.length - 1));
        return _spread(wage! * covered, 2, [
          PaymentType.advance,
          PaymentType.wage,
        ], days, today);
    }
  }

  /// Splits [totalToman] into [parts] amounts, each a multiple of 100 000 Toman.
  ///
  /// Each payment is dated a few days after a different slice of [days], so
  /// the dates spread across the period and always follow the work they pay
  /// for.
  List<_PaymentSeed> _spread(
    int totalToman,
    int parts,
    List<PaymentType> types,
    List<_WorkDay> days,
    DateTime today,
  ) {
    const step = 100000;
    final units = max(0, totalToman ~/ step);
    if (units == 0) return const [];
    final base = units ~/ parts;
    var remainder = units - base * parts;
    final result = <_PaymentSeed>[];
    for (var i = 0; i < parts; i++) {
      var amount = base;
      if (remainder > 0) {
        amount += 1;
        remainder -= 1;
      }
      if (amount == 0) continue;
      final anchorIndex = (((i + 1) * days.length) ~/ (parts + 1))
          .clamp(0, days.length - 1);
      var date = days[anchorIndex].date.add(
        Duration(days: 2 + _rng.nextInt(6)),
      );
      if (date.isAfter(today)) date = today;
      result.add(
        _PaymentSeed(types[i % types.length], amount * step, date),
      );
    }
    return result;
  }

  Future<void> _writeSettings(DateTime now) async {
    final dao = KeyValueDao(_db);
    final iso = now.toIso8601String();
    await dao.write('onboardingSeen', 'true');
    await dao.write('themeChoice', ThemeChoice.system.name);
    await dao.write('currencyUnit', CurrencyUnit.toman.name);
    await dao.write('voiceHintsEnabled', 'false');
    await dao.write('coachMarksSeen', 'calendar,payment,workday');
    // Keep the demo screen free of the update prompt and the backup banner.
    await dao.write('lastUpdateCheckAt', iso);
    await dao.write('lastBackupAt', iso);
    await dao.write('lastBackupReminderAt', iso);
  }

  Future<void> _printSummary() async {
    final employers = await _db.select(_db.employers).get();
    final entries = await _db.select(_db.workEntries).get();
    final payments = await _db.select(_db.payments).get();

    final buffer = StringBuffer()
      ..writeln('')
      ..writeln('===== Dipi demo data =====')
      ..writeln(
        'کارفرما | روزها | در انتظار | پرداخت‌شده | اعتبار | مانده',
      );
    for (final employer in employers) {
      final employerEntries =
          entries.where((e) => e.employerId == employer.id).toList();
      final employerPayments =
          payments.where((p) => p.employerId == employer.id).toList();
      final stats = summarizeSettlement(
        entries: employerEntries,
        payments: employerPayments,
      );
      final allocation = allocateEmployer(
        dailyWageRial: employer.defaultDailyWage,
        entries: employerEntries,
        payments: employerPayments,
      );
      final balance = employer.defaultDailyWage == null
          ? stats.balanceRial
          : allocation.balanceRial(employer.defaultDailyWage!);
      buffer.writeln(
        '${employer.name} | ${toPersianDigits('${stats.dayCount}')} | '
        '${toPersianDigits('${allocation.pendingCount}')} | '
        '${toPersianDigits('${stats.dayCount - allocation.pendingCount}')} | '
        '${formatMoney(allocation.creditRial, CurrencyUnit.toman, withUnit: false)} | '
        '${formatMoney(balance, CurrencyUnit.toman, withUnit: false)}',
      );
    }
    buffer
      ..writeln(
        'جمع: ${toPersianDigits('${entries.length}')} روزکار، '
        '${toPersianDigits('${payments.length}')} پرداخت',
      )
      ..writeln('==========================');
    // ignore: avoid_print
    print(buffer.toString());
  }

  List<DateTime> _daysOfMonth(DateTime month) {
    final jalali = toJalali(month);
    return [
      for (var day = 1; day <= jalaliMonthLength(jalali.year, jalali.month); day++)
        jalaliToDateTime(jalali.year, jalali.month, day),
    ];
  }

  static int _toRial(int toman) => toman * 10;

  static String _clock(int minuteOfDay) {
    final hour = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
    final minute = (minuteOfDay % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
