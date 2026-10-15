import 'dart:convert';

import 'package:drift/drift.dart' show Value;

import '../../../core/constants/app_info.dart';
import '../../../data/db/app_database.dart';

/// Thrown when an imported file is not a Dipi backup, is from a newer schema,
/// or has rows we cannot understand. [message] is shown to the user in Persian.
class BackupFormatException implements Exception {
  BackupFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// The on-disk JSON contract of a Dipi backup.
///
/// Keys and value types are explicit and validated on import so a hand-edited
/// file gives a clear Persian error instead of a database crash.
class BackupDocument {
  const BackupDocument({
    required this.schemaVersion,
    required this.appVersion,
    required this.exportedAt,
    required this.employers,
    required this.workEntries,
    required this.payments,
    required this.settings,
  });

  static const int currentSchemaVersion = AppInfo.schemaVersion;

  final int schemaVersion;
  final String appVersion;
  final String exportedAt;
  final List<BackupEmployer> employers;
  final List<BackupWorkEntry> workEntries;
  final List<BackupPayment> payments;
  final Map<String, String> settings;

  int get totalRows =>
      employers.length + workEntries.length + payments.length;

  Map<String, Object?> toJson() => {
    'app': AppInfo.nameEn,
    'schemaVersion': schemaVersion,
    'appVersion': appVersion,
    'exportedAt': exportedAt,
    'counts': {
      'employers': employers.length,
      'workEntries': workEntries.length,
      'payments': payments.length,
    },
    'employers': [for (final row in employers) row.toJson()],
    'workEntries': [for (final row in workEntries) row.toJson()],
    'payments': [for (final row in payments) row.toJson()],
    'settings': settings,
  };

  String encode({bool pretty = true}) => pretty
      ? const JsonEncoder.withIndent('  ').convert(toJson())
      : jsonEncode(toJson());

  factory BackupDocument.fromJson(Map<String, Object?> json) {
    final schemaVersion = _int(json, 'schemaVersion');
    if (schemaVersion > currentSchemaVersion) {
      throw BackupFormatException(
        'این فایل با نسخه تازه‌تری از دیپی ساخته شده است '
        '(قالب $schemaVersion، پشتیبانی تا $currentSchemaVersion). '
        'برنامه را به‌روز کنید.',
      );
    }
    if (schemaVersion < 1) {
      throw BackupFormatException('شماره قالب فایل پشتیبان معتبر نیست.');
    }

    final employers = _rows(json, 'employers', BackupEmployer.fromJson);
    final workEntries = _rows(json, 'workEntries', BackupWorkEntry.fromJson);
    final payments = _rows(json, 'payments', BackupPayment.fromJson);

    final knownEmployers = {for (final employer in employers) employer.id};
    for (final entry in workEntries) {
      if (!knownEmployers.contains(entry.employerId)) {
        throw BackupFormatException(
          'در فایل پشتیبان، روزکار شماره ${entry.id} به کارفرمایی اشاره می‌کند '
          'که در فایل نیست.',
        );
      }
    }
    for (final payment in payments) {
      if (!knownEmployers.contains(payment.employerId)) {
        throw BackupFormatException(
          'در فایل پشتیبان، پرداخت شماره ${payment.id} به کارفرمایی اشاره می‌کند '
          'که در فایل نیست.',
        );
      }
    }

    final settingsJson = json['settings'];
    final settings = <String, String>{};
    if (settingsJson is Map) {
      for (final entry in settingsJson.entries) {
        final value = entry.value;
        if (value == null) continue;
        settings[entry.key.toString()] = value.toString();
      }
    }

    return BackupDocument(
      schemaVersion: schemaVersion,
      appVersion: _string(json, 'appVersion', fallback: ''),
      exportedAt: _string(json, 'exportedAt', fallback: ''),
      employers: employers,
      workEntries: workEntries,
      payments: payments,
      settings: settings,
    );
  }

  factory BackupDocument.decode(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      throw BackupFormatException('فایل خوانده نشد؛ متن JSON معتبر نیست.');
    }
    if (decoded is! Map) {
      throw BackupFormatException(
        'ساختار فایل پشتیبان درست نیست؛ یک شیء JSON انتظار می‌رفت.',
      );
    }
    return BackupDocument.fromJson(decoded.cast<String, Object?>());
  }

  static List<T> _rows<T>(
    Map<String, Object?> json,
    String key,
    T Function(Map<String, Object?> row, String path) parse,
  ) {
    final value = json[key];
    if (value == null) return const [];
    if (value is! List) {
      throw BackupFormatException('بخش «$key» در فایل پشتیبان باید فهرست باشد.');
    }
    return [
      for (var index = 0; index < value.length; index++)
        if (value[index] is Map)
          parse(
            (value[index] as Map).cast<String, Object?>(),
            '$key[$index]',
          )
        else
          throw BackupFormatException('مورد $index در «$key» ساختار درستی ندارد.'),
    ];
  }

  static int _int(
    Map<String, Object?> json,
    String key, {
    String path = '',
    int? fallback,
  }) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String && value.isNotEmpty) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
    }
    if (fallback != null) return fallback;
    throw BackupFormatException(
      'مقدار «${path.isEmpty ? key : path}» در فایل پشتیبان پیدا نشد یا عدد نیست.',
    );
  }

  static int? _intOrNull(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String && value.isNotEmpty) return int.tryParse(value);
    return null;
  }

  static String _string(
    Map<String, Object?> json,
    String key, {
    String? fallback,
    bool required = false,
  }) {
    final value = json[key];
    if (value is String) return value;
    if (value == null) {
      if (fallback != null) return fallback;
      if (!required) return '';
      throw BackupFormatException('مقدار «$key» در فایل پشتیبان پیدا نشد.');
    }
    return value.toString();
  }

  static String? _stringOrNull(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return null;
    final text = value.toString();
    return text.isEmpty ? null : text;
  }

  static bool _bool(Map<String, Object?> json, String key, {bool fallback = false}) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == 'true' || value == '1';
    return fallback;
  }
}

class BackupEmployer {
  const BackupEmployer({
    required this.id,
    required this.name,
    required this.color,
    this.phone,
    this.note,
    required this.defaultWageType,
    this.defaultDailyWage,
    required this.isArchived,
    required this.createdAt,
  });

  final int id;
  final String name;
  final int color;
  final String? phone;
  final String? note;
  final String defaultWageType;
  final int? defaultDailyWage;
  final bool isArchived;
  final String createdAt;

  factory BackupEmployer.fromJson(Map<String, Object?> json, String path) {
    final name = BackupDocument._string(json, 'name', required: true);
    if (name.trim().isEmpty) {
      throw BackupFormatException('نام کارفرما در «$path» خالی است.');
    }
    return BackupEmployer(
      id: BackupDocument._int(json, 'id'),
      name: name,
      color: BackupDocument._int(json, 'color', fallback: 0xFF2E7D6F),
      phone: BackupDocument._stringOrNull(json, 'phone'),
      note: BackupDocument._stringOrNull(json, 'note'),
      defaultWageType: BackupDocument._string(
        json,
        'defaultWageType',
        fallback: 'fixed',
      ),
      defaultDailyWage: BackupDocument._intOrNull(json, 'defaultDailyWage'),
      isArchived: BackupDocument._bool(json, 'isArchived'),
      createdAt: BackupDocument._string(json, 'createdAt', fallback: ''),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'color': color,
    'phone': phone,
    'note': note,
    'defaultWageType': defaultWageType,
    'defaultDailyWage': defaultDailyWage,
    'isArchived': isArchived,
    'createdAt': createdAt,
  };

  factory BackupEmployer.fromRow(Employer row) => BackupEmployer(
    id: row.id,
    name: row.name,
    color: row.color,
    phone: row.phone,
    note: row.note,
    defaultWageType: row.defaultWageType,
    defaultDailyWage: row.defaultDailyWage,
    isArchived: row.isArchived,
    createdAt: row.createdAt,
  );

  EmployersCompanion toCompanion() => EmployersCompanion(
    id: Value(id),
    name: Value(name),
    color: Value(color),
    phone: Value(phone),
    note: Value(note),
    defaultWageType: Value(defaultWageType),
    defaultDailyWage: Value(defaultDailyWage),
    isArchived: Value(isArchived),
    createdAt: Value(createdAt.isEmpty ? DateTime.now().toIso8601String() : createdAt),
  );
}

class BackupWorkEntry {
  const BackupWorkEntry({
    required this.id,
    required this.employerId,
    required this.date,
    this.place,
    this.job,
    this.startTime,
    this.endTime,
    required this.wageType,
    this.wageAmount,
    required this.outOfPocketAmount,
    this.note,
    required this.createdAt,
  });

  final int id;
  final int employerId;
  final String date;
  final String? place;
  final String? job;
  final String? startTime;
  final String? endTime;
  final String wageType;
  final int? wageAmount;
  final int outOfPocketAmount;
  final String? note;
  final String createdAt;

  factory BackupWorkEntry.fromJson(Map<String, Object?> json, String path) {
    final date = BackupDocument._string(json, 'date', required: true);
    if (!_looksLikeIsoDate(date)) {
      throw BackupFormatException(
        'تاریخ روزکار در «$path» درست نیست (باید مانند ۲۰۲۴-۰۵-۱۲ باشد).',
      );
    }
    return BackupWorkEntry(
      id: BackupDocument._int(json, 'id'),
      employerId: BackupDocument._int(json, 'employerId'),
      date: date,
      place: BackupDocument._stringOrNull(json, 'place'),
      job: BackupDocument._stringOrNull(json, 'job'),
      startTime: BackupDocument._stringOrNull(json, 'startTime'),
      endTime: BackupDocument._stringOrNull(json, 'endTime'),
      wageType: BackupDocument._string(json, 'wageType', fallback: 'fixed'),
      wageAmount: BackupDocument._intOrNull(json, 'wageAmount'),
      outOfPocketAmount: BackupDocument._int(
        json,
        'outOfPocketAmount',
        fallback: 0,
      ),
      note: BackupDocument._stringOrNull(json, 'note'),
      createdAt: BackupDocument._string(json, 'createdAt', fallback: ''),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'employerId': employerId,
    'date': date,
    'place': place,
    'job': job,
    'startTime': startTime,
    'endTime': endTime,
    'wageType': wageType,
    'wageAmount': wageAmount,
    'outOfPocketAmount': outOfPocketAmount,
    'note': note,
    'createdAt': createdAt,
  };

  factory BackupWorkEntry.fromRow(WorkEntry row) => BackupWorkEntry(
    id: row.id,
    employerId: row.employerId,
    date: row.date,
    place: row.place,
    job: row.job,
    startTime: row.startTime,
    endTime: row.endTime,
    wageType: row.wageType,
    wageAmount: row.wageAmount,
    outOfPocketAmount: row.outOfPocketAmount,
    note: row.note,
    createdAt: row.createdAt,
  );

  WorkEntriesCompanion toCompanion({int? employerIdOverride}) =>
      WorkEntriesCompanion(
        id: Value(id),
        employerId: Value(employerIdOverride ?? employerId),
        date: Value(date),
        place: Value(place),
        job: Value(job),
        startTime: Value(startTime),
        endTime: Value(endTime),
        wageType: Value(wageType),
        wageAmount: Value(wageAmount),
        outOfPocketAmount: Value(outOfPocketAmount),
        note: Value(note),
        createdAt: Value(
          createdAt.isEmpty ? DateTime.now().toIso8601String() : createdAt,
        ),
      );

  /// Used to spot duplicates when merging into an existing ledger.
  String get mergeKey =>
      '$employerId|$date|${startTime ?? ''}|${endTime ?? ''}|'
      '${place ?? ''}|${job ?? ''}|${wageAmount ?? ''}|$outOfPocketAmount';
}

class BackupPayment {
  const BackupPayment({
    required this.id,
    required this.employerId,
    required this.date,
    required this.amount,
    required this.type,
    this.note,
    required this.createdAt,
  });

  final int id;
  final int employerId;
  final String date;
  final int amount;
  final String type;
  final String? note;
  final String createdAt;

  factory BackupPayment.fromJson(Map<String, Object?> json, String path) {
    final date = BackupDocument._string(json, 'date', required: true);
    if (!_looksLikeIsoDate(date)) {
      throw BackupFormatException(
        'تاریخ پرداخت در «$path» درست نیست (باید مانند ۲۰۲۴-۰۵-۱۲ باشد).',
      );
    }
    return BackupPayment(
      id: BackupDocument._int(json, 'id'),
      employerId: BackupDocument._int(json, 'employerId'),
      date: date,
      amount: BackupDocument._int(json, 'amount'),
      type: BackupDocument._string(json, 'type', fallback: 'wage'),
      note: BackupDocument._stringOrNull(json, 'note'),
      createdAt: BackupDocument._string(json, 'createdAt', fallback: ''),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'employerId': employerId,
    'date': date,
    'amount': amount,
    'type': type,
    'note': note,
    'createdAt': createdAt,
  };

  factory BackupPayment.fromRow(Payment row) => BackupPayment(
    id: row.id,
    employerId: row.employerId,
    date: row.date,
    amount: row.amount,
    type: row.type,
    note: row.note,
    createdAt: row.createdAt,
  );

  PaymentsCompanion toCompanion({int? employerIdOverride}) =>
      PaymentsCompanion(
        id: Value(id),
        employerId: Value(employerIdOverride ?? employerId),
        date: Value(date),
        amount: Value(amount),
        type: Value(type),
        note: Value(note),
        createdAt: Value(
          createdAt.isEmpty ? DateTime.now().toIso8601String() : createdAt,
        ),
      );

  String get mergeKey => '$employerId|$date|$amount|$type|${note ?? ''}';
}

bool _looksLikeIsoDate(String value) {
  if (value.length < 10) return false;
  final date = DateTime.tryParse(value);
  return date != null;
}
