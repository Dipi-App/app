// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $EmployersTable extends Employers
    with TableInfo<$EmployersTable, Employer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EmployersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0xFF2E7D6F),
  );
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
    'phone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _defaultWageTypeMeta = const VerificationMeta(
    'defaultWageType',
  );
  @override
  late final GeneratedColumn<String> defaultWageType = GeneratedColumn<String>(
    'default_wage_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fixed'),
  );
  static const VerificationMeta _defaultDailyWageMeta = const VerificationMeta(
    'defaultDailyWage',
  );
  @override
  late final GeneratedColumn<int> defaultDailyWage = GeneratedColumn<int>(
    'default_daily_wage',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    color,
    phone,
    note,
    defaultWageType,
    defaultDailyWage,
    isArchived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'employers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Employer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('phone')) {
      context.handle(
        _phoneMeta,
        phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('default_wage_type')) {
      context.handle(
        _defaultWageTypeMeta,
        defaultWageType.isAcceptableOrUnknown(
          data['default_wage_type']!,
          _defaultWageTypeMeta,
        ),
      );
    }
    if (data.containsKey('default_daily_wage')) {
      context.handle(
        _defaultDailyWageMeta,
        defaultDailyWage.isAcceptableOrUnknown(
          data['default_daily_wage']!,
          _defaultDailyWageMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Employer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Employer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      )!,
      phone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}phone'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      defaultWageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_wage_type'],
      )!,
      defaultDailyWage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_daily_wage'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $EmployersTable createAlias(String alias) {
    return $EmployersTable(attachedDatabase, alias);
  }
}

class Employer extends DataClass implements Insertable<Employer> {
  final int id;
  final String name;
  final int color;
  final String? phone;
  final String? note;
  final String defaultWageType;
  final int? defaultDailyWage;
  final bool isArchived;
  final String createdAt;
  const Employer({
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['color'] = Variable<int>(color);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['default_wage_type'] = Variable<String>(defaultWageType);
    if (!nullToAbsent || defaultDailyWage != null) {
      map['default_daily_wage'] = Variable<int>(defaultDailyWage);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  EmployersCompanion toCompanion(bool nullToAbsent) {
    return EmployersCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      phone: phone == null && nullToAbsent
          ? const Value.absent()
          : Value(phone),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      defaultWageType: Value(defaultWageType),
      defaultDailyWage: defaultDailyWage == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultDailyWage),
      isArchived: Value(isArchived),
      createdAt: Value(createdAt),
    );
  }

  factory Employer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Employer(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int>(json['color']),
      phone: serializer.fromJson<String?>(json['phone']),
      note: serializer.fromJson<String?>(json['note']),
      defaultWageType: serializer.fromJson<String>(json['defaultWageType']),
      defaultDailyWage: serializer.fromJson<int?>(json['defaultDailyWage']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int>(color),
      'phone': serializer.toJson<String?>(phone),
      'note': serializer.toJson<String?>(note),
      'defaultWageType': serializer.toJson<String>(defaultWageType),
      'defaultDailyWage': serializer.toJson<int?>(defaultDailyWage),
      'isArchived': serializer.toJson<bool>(isArchived),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Employer copyWith({
    int? id,
    String? name,
    int? color,
    Value<String?> phone = const Value.absent(),
    Value<String?> note = const Value.absent(),
    String? defaultWageType,
    Value<int?> defaultDailyWage = const Value.absent(),
    bool? isArchived,
    String? createdAt,
  }) => Employer(
    id: id ?? this.id,
    name: name ?? this.name,
    color: color ?? this.color,
    phone: phone.present ? phone.value : this.phone,
    note: note.present ? note.value : this.note,
    defaultWageType: defaultWageType ?? this.defaultWageType,
    defaultDailyWage: defaultDailyWage.present
        ? defaultDailyWage.value
        : this.defaultDailyWage,
    isArchived: isArchived ?? this.isArchived,
    createdAt: createdAt ?? this.createdAt,
  );
  Employer copyWithCompanion(EmployersCompanion data) {
    return Employer(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      phone: data.phone.present ? data.phone.value : this.phone,
      note: data.note.present ? data.note.value : this.note,
      defaultWageType: data.defaultWageType.present
          ? data.defaultWageType.value
          : this.defaultWageType,
      defaultDailyWage: data.defaultDailyWage.present
          ? data.defaultDailyWage.value
          : this.defaultDailyWage,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Employer(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('defaultWageType: $defaultWageType, ')
          ..write('defaultDailyWage: $defaultDailyWage, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    color,
    phone,
    note,
    defaultWageType,
    defaultDailyWage,
    isArchived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Employer &&
          other.id == this.id &&
          other.name == this.name &&
          other.color == this.color &&
          other.phone == this.phone &&
          other.note == this.note &&
          other.defaultWageType == this.defaultWageType &&
          other.defaultDailyWage == this.defaultDailyWage &&
          other.isArchived == this.isArchived &&
          other.createdAt == this.createdAt);
}

class EmployersCompanion extends UpdateCompanion<Employer> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> color;
  final Value<String?> phone;
  final Value<String?> note;
  final Value<String> defaultWageType;
  final Value<int?> defaultDailyWage;
  final Value<bool> isArchived;
  final Value<String> createdAt;
  const EmployersCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.defaultWageType = const Value.absent(),
    this.defaultDailyWage = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  EmployersCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.color = const Value.absent(),
    this.phone = const Value.absent(),
    this.note = const Value.absent(),
    this.defaultWageType = const Value.absent(),
    this.defaultDailyWage = const Value.absent(),
    this.isArchived = const Value.absent(),
    required String createdAt,
  }) : name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<Employer> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? color,
    Expression<String>? phone,
    Expression<String>? note,
    Expression<String>? defaultWageType,
    Expression<int>? defaultDailyWage,
    Expression<bool>? isArchived,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (phone != null) 'phone': phone,
      if (note != null) 'note': note,
      if (defaultWageType != null) 'default_wage_type': defaultWageType,
      if (defaultDailyWage != null) 'default_daily_wage': defaultDailyWage,
      if (isArchived != null) 'is_archived': isArchived,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  EmployersCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? color,
    Value<String?>? phone,
    Value<String?>? note,
    Value<String>? defaultWageType,
    Value<int?>? defaultDailyWage,
    Value<bool>? isArchived,
    Value<String>? createdAt,
  }) {
    return EmployersCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      phone: phone ?? this.phone,
      note: note ?? this.note,
      defaultWageType: defaultWageType ?? this.defaultWageType,
      defaultDailyWage: defaultDailyWage ?? this.defaultDailyWage,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (defaultWageType.present) {
      map['default_wage_type'] = Variable<String>(defaultWageType.value);
    }
    if (defaultDailyWage.present) {
      map['default_daily_wage'] = Variable<int>(defaultDailyWage.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EmployersCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('phone: $phone, ')
          ..write('note: $note, ')
          ..write('defaultWageType: $defaultWageType, ')
          ..write('defaultDailyWage: $defaultDailyWage, ')
          ..write('isArchived: $isArchived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $WorkEntriesTable extends WorkEntries
    with TableInfo<$WorkEntriesTable, WorkEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _employerIdMeta = const VerificationMeta(
    'employerId',
  );
  @override
  late final GeneratedColumn<int> employerId = GeneratedColumn<int>(
    'employer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES employers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _placeMeta = const VerificationMeta('place');
  @override
  late final GeneratedColumn<String> place = GeneratedColumn<String>(
    'place',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jobMeta = const VerificationMeta('job');
  @override
  late final GeneratedColumn<String> job = GeneratedColumn<String>(
    'job',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<String> startTime = GeneratedColumn<String>(
    'start_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<String> endTime = GeneratedColumn<String>(
    'end_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _wageTypeMeta = const VerificationMeta(
    'wageType',
  );
  @override
  late final GeneratedColumn<String> wageType = GeneratedColumn<String>(
    'wage_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('fixed'),
  );
  static const VerificationMeta _wageAmountMeta = const VerificationMeta(
    'wageAmount',
  );
  @override
  late final GeneratedColumn<int> wageAmount = GeneratedColumn<int>(
    'wage_amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _outOfPocketAmountMeta = const VerificationMeta(
    'outOfPocketAmount',
  );
  @override
  late final GeneratedColumn<int> outOfPocketAmount = GeneratedColumn<int>(
    'out_of_pocket_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    employerId,
    date,
    place,
    job,
    startTime,
    endTime,
    wageType,
    wageAmount,
    outOfPocketAmount,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'work_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('employer_id')) {
      context.handle(
        _employerIdMeta,
        employerId.isAcceptableOrUnknown(data['employer_id']!, _employerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employerIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('place')) {
      context.handle(
        _placeMeta,
        place.isAcceptableOrUnknown(data['place']!, _placeMeta),
      );
    }
    if (data.containsKey('job')) {
      context.handle(
        _jobMeta,
        job.isAcceptableOrUnknown(data['job']!, _jobMeta),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    }
    if (data.containsKey('wage_type')) {
      context.handle(
        _wageTypeMeta,
        wageType.isAcceptableOrUnknown(data['wage_type']!, _wageTypeMeta),
      );
    }
    if (data.containsKey('wage_amount')) {
      context.handle(
        _wageAmountMeta,
        wageAmount.isAcceptableOrUnknown(data['wage_amount']!, _wageAmountMeta),
      );
    }
    if (data.containsKey('out_of_pocket_amount')) {
      context.handle(
        _outOfPocketAmountMeta,
        outOfPocketAmount.isAcceptableOrUnknown(
          data['out_of_pocket_amount']!,
          _outOfPocketAmountMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      employerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}employer_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      place: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place'],
      ),
      job: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}job'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_time'],
      ),
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_time'],
      ),
      wageType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}wage_type'],
      )!,
      wageAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wage_amount'],
      ),
      outOfPocketAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}out_of_pocket_amount'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $WorkEntriesTable createAlias(String alias) {
    return $WorkEntriesTable(attachedDatabase, alias);
  }
}

class WorkEntry extends DataClass implements Insertable<WorkEntry> {
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
  const WorkEntry({
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
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['employer_id'] = Variable<int>(employerId);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || place != null) {
      map['place'] = Variable<String>(place);
    }
    if (!nullToAbsent || job != null) {
      map['job'] = Variable<String>(job);
    }
    if (!nullToAbsent || startTime != null) {
      map['start_time'] = Variable<String>(startTime);
    }
    if (!nullToAbsent || endTime != null) {
      map['end_time'] = Variable<String>(endTime);
    }
    map['wage_type'] = Variable<String>(wageType);
    if (!nullToAbsent || wageAmount != null) {
      map['wage_amount'] = Variable<int>(wageAmount);
    }
    map['out_of_pocket_amount'] = Variable<int>(outOfPocketAmount);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  WorkEntriesCompanion toCompanion(bool nullToAbsent) {
    return WorkEntriesCompanion(
      id: Value(id),
      employerId: Value(employerId),
      date: Value(date),
      place: place == null && nullToAbsent
          ? const Value.absent()
          : Value(place),
      job: job == null && nullToAbsent ? const Value.absent() : Value(job),
      startTime: startTime == null && nullToAbsent
          ? const Value.absent()
          : Value(startTime),
      endTime: endTime == null && nullToAbsent
          ? const Value.absent()
          : Value(endTime),
      wageType: Value(wageType),
      wageAmount: wageAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(wageAmount),
      outOfPocketAmount: Value(outOfPocketAmount),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory WorkEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkEntry(
      id: serializer.fromJson<int>(json['id']),
      employerId: serializer.fromJson<int>(json['employerId']),
      date: serializer.fromJson<String>(json['date']),
      place: serializer.fromJson<String?>(json['place']),
      job: serializer.fromJson<String?>(json['job']),
      startTime: serializer.fromJson<String?>(json['startTime']),
      endTime: serializer.fromJson<String?>(json['endTime']),
      wageType: serializer.fromJson<String>(json['wageType']),
      wageAmount: serializer.fromJson<int?>(json['wageAmount']),
      outOfPocketAmount: serializer.fromJson<int>(json['outOfPocketAmount']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'employerId': serializer.toJson<int>(employerId),
      'date': serializer.toJson<String>(date),
      'place': serializer.toJson<String?>(place),
      'job': serializer.toJson<String?>(job),
      'startTime': serializer.toJson<String?>(startTime),
      'endTime': serializer.toJson<String?>(endTime),
      'wageType': serializer.toJson<String>(wageType),
      'wageAmount': serializer.toJson<int?>(wageAmount),
      'outOfPocketAmount': serializer.toJson<int>(outOfPocketAmount),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  WorkEntry copyWith({
    int? id,
    int? employerId,
    String? date,
    Value<String?> place = const Value.absent(),
    Value<String?> job = const Value.absent(),
    Value<String?> startTime = const Value.absent(),
    Value<String?> endTime = const Value.absent(),
    String? wageType,
    Value<int?> wageAmount = const Value.absent(),
    int? outOfPocketAmount,
    Value<String?> note = const Value.absent(),
    String? createdAt,
  }) => WorkEntry(
    id: id ?? this.id,
    employerId: employerId ?? this.employerId,
    date: date ?? this.date,
    place: place.present ? place.value : this.place,
    job: job.present ? job.value : this.job,
    startTime: startTime.present ? startTime.value : this.startTime,
    endTime: endTime.present ? endTime.value : this.endTime,
    wageType: wageType ?? this.wageType,
    wageAmount: wageAmount.present ? wageAmount.value : this.wageAmount,
    outOfPocketAmount: outOfPocketAmount ?? this.outOfPocketAmount,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  WorkEntry copyWithCompanion(WorkEntriesCompanion data) {
    return WorkEntry(
      id: data.id.present ? data.id.value : this.id,
      employerId: data.employerId.present
          ? data.employerId.value
          : this.employerId,
      date: data.date.present ? data.date.value : this.date,
      place: data.place.present ? data.place.value : this.place,
      job: data.job.present ? data.job.value : this.job,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      wageType: data.wageType.present ? data.wageType.value : this.wageType,
      wageAmount: data.wageAmount.present
          ? data.wageAmount.value
          : this.wageAmount,
      outOfPocketAmount: data.outOfPocketAmount.present
          ? data.outOfPocketAmount.value
          : this.outOfPocketAmount,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkEntry(')
          ..write('id: $id, ')
          ..write('employerId: $employerId, ')
          ..write('date: $date, ')
          ..write('place: $place, ')
          ..write('job: $job, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('wageType: $wageType, ')
          ..write('wageAmount: $wageAmount, ')
          ..write('outOfPocketAmount: $outOfPocketAmount, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    employerId,
    date,
    place,
    job,
    startTime,
    endTime,
    wageType,
    wageAmount,
    outOfPocketAmount,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkEntry &&
          other.id == this.id &&
          other.employerId == this.employerId &&
          other.date == this.date &&
          other.place == this.place &&
          other.job == this.job &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.wageType == this.wageType &&
          other.wageAmount == this.wageAmount &&
          other.outOfPocketAmount == this.outOfPocketAmount &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class WorkEntriesCompanion extends UpdateCompanion<WorkEntry> {
  final Value<int> id;
  final Value<int> employerId;
  final Value<String> date;
  final Value<String?> place;
  final Value<String?> job;
  final Value<String?> startTime;
  final Value<String?> endTime;
  final Value<String> wageType;
  final Value<int?> wageAmount;
  final Value<int> outOfPocketAmount;
  final Value<String?> note;
  final Value<String> createdAt;
  const WorkEntriesCompanion({
    this.id = const Value.absent(),
    this.employerId = const Value.absent(),
    this.date = const Value.absent(),
    this.place = const Value.absent(),
    this.job = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.wageType = const Value.absent(),
    this.wageAmount = const Value.absent(),
    this.outOfPocketAmount = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  WorkEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int employerId,
    required String date,
    this.place = const Value.absent(),
    this.job = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.wageType = const Value.absent(),
    this.wageAmount = const Value.absent(),
    this.outOfPocketAmount = const Value.absent(),
    this.note = const Value.absent(),
    required String createdAt,
  }) : employerId = Value(employerId),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<WorkEntry> custom({
    Expression<int>? id,
    Expression<int>? employerId,
    Expression<String>? date,
    Expression<String>? place,
    Expression<String>? job,
    Expression<String>? startTime,
    Expression<String>? endTime,
    Expression<String>? wageType,
    Expression<int>? wageAmount,
    Expression<int>? outOfPocketAmount,
    Expression<String>? note,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employerId != null) 'employer_id': employerId,
      if (date != null) 'date': date,
      if (place != null) 'place': place,
      if (job != null) 'job': job,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (wageType != null) 'wage_type': wageType,
      if (wageAmount != null) 'wage_amount': wageAmount,
      if (outOfPocketAmount != null) 'out_of_pocket_amount': outOfPocketAmount,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  WorkEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? employerId,
    Value<String>? date,
    Value<String?>? place,
    Value<String?>? job,
    Value<String?>? startTime,
    Value<String?>? endTime,
    Value<String>? wageType,
    Value<int?>? wageAmount,
    Value<int>? outOfPocketAmount,
    Value<String?>? note,
    Value<String>? createdAt,
  }) {
    return WorkEntriesCompanion(
      id: id ?? this.id,
      employerId: employerId ?? this.employerId,
      date: date ?? this.date,
      place: place ?? this.place,
      job: job ?? this.job,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      wageType: wageType ?? this.wageType,
      wageAmount: wageAmount ?? this.wageAmount,
      outOfPocketAmount: outOfPocketAmount ?? this.outOfPocketAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (employerId.present) {
      map['employer_id'] = Variable<int>(employerId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (place.present) {
      map['place'] = Variable<String>(place.value);
    }
    if (job.present) {
      map['job'] = Variable<String>(job.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<String>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<String>(endTime.value);
    }
    if (wageType.present) {
      map['wage_type'] = Variable<String>(wageType.value);
    }
    if (wageAmount.present) {
      map['wage_amount'] = Variable<int>(wageAmount.value);
    }
    if (outOfPocketAmount.present) {
      map['out_of_pocket_amount'] = Variable<int>(outOfPocketAmount.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkEntriesCompanion(')
          ..write('id: $id, ')
          ..write('employerId: $employerId, ')
          ..write('date: $date, ')
          ..write('place: $place, ')
          ..write('job: $job, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('wageType: $wageType, ')
          ..write('wageAmount: $wageAmount, ')
          ..write('outOfPocketAmount: $outOfPocketAmount, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $PaymentsTable extends Payments with TableInfo<$PaymentsTable, Payment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PaymentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _employerIdMeta = const VerificationMeta(
    'employerId',
  );
  @override
  late final GeneratedColumn<int> employerId = GeneratedColumn<int>(
    'employer_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES employers (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('wage'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    employerId,
    date,
    amount,
    type,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'payments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Payment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('employer_id')) {
      context.handle(
        _employerIdMeta,
        employerId.isAcceptableOrUnknown(data['employer_id']!, _employerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_employerIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Payment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Payment(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      employerId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}employer_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $PaymentsTable createAlias(String alias) {
    return $PaymentsTable(attachedDatabase, alias);
  }
}

class Payment extends DataClass implements Insertable<Payment> {
  final int id;
  final int employerId;
  final String date;
  final int amount;
  final String type;
  final String? note;
  final String createdAt;
  const Payment({
    required this.id,
    required this.employerId,
    required this.date,
    required this.amount,
    required this.type,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['employer_id'] = Variable<int>(employerId);
    map['date'] = Variable<String>(date);
    map['amount'] = Variable<int>(amount);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  PaymentsCompanion toCompanion(bool nullToAbsent) {
    return PaymentsCompanion(
      id: Value(id),
      employerId: Value(employerId),
      date: Value(date),
      amount: Value(amount),
      type: Value(type),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory Payment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Payment(
      id: serializer.fromJson<int>(json['id']),
      employerId: serializer.fromJson<int>(json['employerId']),
      date: serializer.fromJson<String>(json['date']),
      amount: serializer.fromJson<int>(json['amount']),
      type: serializer.fromJson<String>(json['type']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'employerId': serializer.toJson<int>(employerId),
      'date': serializer.toJson<String>(date),
      'amount': serializer.toJson<int>(amount),
      'type': serializer.toJson<String>(type),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  Payment copyWith({
    int? id,
    int? employerId,
    String? date,
    int? amount,
    String? type,
    Value<String?> note = const Value.absent(),
    String? createdAt,
  }) => Payment(
    id: id ?? this.id,
    employerId: employerId ?? this.employerId,
    date: date ?? this.date,
    amount: amount ?? this.amount,
    type: type ?? this.type,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  Payment copyWithCompanion(PaymentsCompanion data) {
    return Payment(
      id: data.id.present ? data.id.value : this.id,
      employerId: data.employerId.present
          ? data.employerId.value
          : this.employerId,
      date: data.date.present ? data.date.value : this.date,
      amount: data.amount.present ? data.amount.value : this.amount,
      type: data.type.present ? data.type.value : this.type,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Payment(')
          ..write('id: $id, ')
          ..write('employerId: $employerId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, employerId, date, amount, type, note, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Payment &&
          other.id == this.id &&
          other.employerId == this.employerId &&
          other.date == this.date &&
          other.amount == this.amount &&
          other.type == this.type &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class PaymentsCompanion extends UpdateCompanion<Payment> {
  final Value<int> id;
  final Value<int> employerId;
  final Value<String> date;
  final Value<int> amount;
  final Value<String> type;
  final Value<String?> note;
  final Value<String> createdAt;
  const PaymentsCompanion({
    this.id = const Value.absent(),
    this.employerId = const Value.absent(),
    this.date = const Value.absent(),
    this.amount = const Value.absent(),
    this.type = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PaymentsCompanion.insert({
    this.id = const Value.absent(),
    required int employerId,
    required String date,
    required int amount,
    this.type = const Value.absent(),
    this.note = const Value.absent(),
    required String createdAt,
  }) : employerId = Value(employerId),
       date = Value(date),
       amount = Value(amount),
       createdAt = Value(createdAt);
  static Insertable<Payment> custom({
    Expression<int>? id,
    Expression<int>? employerId,
    Expression<String>? date,
    Expression<int>? amount,
    Expression<String>? type,
    Expression<String>? note,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (employerId != null) 'employer_id': employerId,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (type != null) 'type': type,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PaymentsCompanion copyWith({
    Value<int>? id,
    Value<int>? employerId,
    Value<String>? date,
    Value<int>? amount,
    Value<String>? type,
    Value<String?>? note,
    Value<String>? createdAt,
  }) {
    return PaymentsCompanion(
      id: id ?? this.id,
      employerId: employerId ?? this.employerId,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (employerId.present) {
      map['employer_id'] = Variable<int>(employerId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PaymentsCompanion(')
          ..write('id: $id, ')
          ..write('employerId: $employerId, ')
          ..write('date: $date, ')
          ..write('amount: $amount, ')
          ..write('type: $type, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $KeyValuesTable extends KeyValues
    with TableInfo<$KeyValuesTable, KeyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValuesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValue(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $KeyValuesTable createAlias(String alias) {
    return $KeyValuesTable(attachedDatabase, alias);
  }
}

class KeyValue extends DataClass implements Insertable<KeyValue> {
  final String key;
  final String? value;
  const KeyValue({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  KeyValuesCompanion toCompanion(bool nullToAbsent) {
    return KeyValuesCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory KeyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValue(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  KeyValue copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
  }) => KeyValue(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  KeyValue copyWithCompanion(KeyValuesCompanion data) {
    return KeyValue(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValue(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValue && other.key == this.key && other.value == this.value);
}

class KeyValuesCompanion extends UpdateCompanion<KeyValue> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const KeyValuesCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValuesCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<KeyValue> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValuesCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return KeyValuesCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValuesCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $EmployersTable employers = $EmployersTable(this);
  late final $WorkEntriesTable workEntries = $WorkEntriesTable(this);
  late final $PaymentsTable payments = $PaymentsTable(this);
  late final $KeyValuesTable keyValues = $KeyValuesTable(this);
  late final Index idxEmployersArchived = Index(
    'idx_employers_archived',
    'CREATE INDEX idx_employers_archived ON employers (is_archived)',
  );
  late final Index idxWorkEntriesEmployer = Index(
    'idx_work_entries_employer',
    'CREATE INDEX idx_work_entries_employer ON work_entries (employer_id)',
  );
  late final Index idxWorkEntriesDate = Index(
    'idx_work_entries_date',
    'CREATE INDEX idx_work_entries_date ON work_entries (date)',
  );
  late final Index idxPaymentsEmployer = Index(
    'idx_payments_employer',
    'CREATE INDEX idx_payments_employer ON payments (employer_id)',
  );
  late final Index idxPaymentsDate = Index(
    'idx_payments_date',
    'CREATE INDEX idx_payments_date ON payments (date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    employers,
    workEntries,
    payments,
    keyValues,
    idxEmployersArchived,
    idxWorkEntriesEmployer,
    idxWorkEntriesDate,
    idxPaymentsEmployer,
    idxPaymentsDate,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'employers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('work_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'employers',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('payments', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$EmployersTableCreateCompanionBuilder = EmployersCompanion Function({
  Value<int> id,
  required String name,
  Value<int> color,
  Value<String?> phone,
  Value<String?> note,
  Value<String> defaultWageType,
  Value<int?> defaultDailyWage,
  Value<bool> isArchived,
  required String createdAt,
});
typedef $$EmployersTableUpdateCompanionBuilder = EmployersCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int> color,
  Value<String?> phone,
  Value<String?> note,
  Value<String> defaultWageType,
  Value<int?> defaultDailyWage,
  Value<bool> isArchived,
  Value<String> createdAt,
});

final class $$EmployersTableReferences
    extends BaseReferences<_$AppDatabase, $EmployersTable, Employer> {
  $$EmployersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$WorkEntriesTable, List<WorkEntry>>
  _workEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.workEntries,
    aliasName: 'employers__id__work_entries__employer_id',
  );

  $$WorkEntriesTableProcessedTableManager get workEntriesRefs {
    final manager = $$WorkEntriesTableTableManager(
      $_db,
      $_db.workEntries,
    ).filter((f) => f.employerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_workEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PaymentsTable, List<Payment>> _paymentsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.payments,
    aliasName: 'employers__id__payments__employer_id',
  );

  $$PaymentsTableProcessedTableManager get paymentsRefs {
    final manager = $$PaymentsTableTableManager(
      $_db,
      $_db.payments,
    ).filter((f) => f.employerId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_paymentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$EmployersTableFilterComposer
    extends Composer<_$AppDatabase, $EmployersTable> {
  $$EmployersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultWageType => $composableBuilder(
    column: $table.defaultWageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultDailyWage => $composableBuilder(
    column: $table.defaultDailyWage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> workEntriesRefs(
    Expression<bool> Function($$WorkEntriesTableFilterComposer f) f,
  ) {
    final $$WorkEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workEntries,
      getReferencedColumn: (t) => t.employerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkEntriesTableFilterComposer(
            $db: $db,
            $table: $db.workEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> paymentsRefs(
    Expression<bool> Function($$PaymentsTableFilterComposer f) f,
  ) {
    final $$PaymentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.employerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableFilterComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EmployersTableOrderingComposer
    extends Composer<_$AppDatabase, $EmployersTable> {
  $$EmployersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get phone => $composableBuilder(
    column: $table.phone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultWageType => $composableBuilder(
    column: $table.defaultWageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultDailyWage => $composableBuilder(
    column: $table.defaultDailyWage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EmployersTableAnnotationComposer
    extends Composer<_$AppDatabase, $EmployersTable> {
  $$EmployersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get defaultWageType => $composableBuilder(
    column: $table.defaultWageType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultDailyWage => $composableBuilder(
    column: $table.defaultDailyWage,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> workEntriesRefs<T extends Object>(
    Expression<T> Function($$WorkEntriesTableAnnotationComposer a) f,
  ) {
    final $$WorkEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.workEntries,
      getReferencedColumn: (t) => t.employerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.workEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> paymentsRefs<T extends Object>(
    Expression<T> Function($$PaymentsTableAnnotationComposer a) f,
  ) {
    final $$PaymentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.payments,
      getReferencedColumn: (t) => t.employerId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PaymentsTableAnnotationComposer(
            $db: $db,
            $table: $db.payments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$EmployersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $EmployersTable,
          Employer,
          $$EmployersTableFilterComposer,
          $$EmployersTableOrderingComposer,
          $$EmployersTableAnnotationComposer,
          $$EmployersTableCreateCompanionBuilder,
          $$EmployersTableUpdateCompanionBuilder,
          (Employer, $$EmployersTableReferences),
          Employer,
          PrefetchHooks Function({bool workEntriesRefs, bool paymentsRefs})
        > {
  $$EmployersTableTableManager(_$AppDatabase db, $EmployersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EmployersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EmployersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EmployersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> color = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> defaultWageType = const Value.absent(),
                Value<int?> defaultDailyWage = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => EmployersCompanion(
                id: id,
                name: name,
                color: color,
                phone: phone,
                note: note,
                defaultWageType: defaultWageType,
                defaultDailyWage: defaultDailyWage,
                isArchived: isArchived,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<int> color = const Value.absent(),
                Value<String?> phone = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> defaultWageType = const Value.absent(),
                Value<int?> defaultDailyWage = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                required String createdAt,
              }) => EmployersCompanion.insert(
                id: id,
                name: name,
                color: color,
                phone: phone,
                note: note,
                defaultWageType: defaultWageType,
                defaultDailyWage: defaultDailyWage,
                isArchived: isArchived,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EmployersTable, Employer>(table),
                  $$EmployersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workEntriesRefs = false, paymentsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (workEntriesRefs) db.workEntries,
                    if (paymentsRefs) db.payments,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (workEntriesRefs)
                        await $_getPrefetchedData<
                          Employer,
                          $EmployersTable,
                          WorkEntry
                        >(
                          currentTable: table,
                          referencedTable: $$EmployersTableReferences
                              ._workEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmployersTableReferences(
                                db,
                                table,
                                p0,
                              ).workEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.employerId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (paymentsRefs)
                        await $_getPrefetchedData<
                          Employer,
                          $EmployersTable,
                          Payment
                        >(
                          currentTable: table,
                          referencedTable: $$EmployersTableReferences
                              ._paymentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$EmployersTableReferences(
                                db,
                                table,
                                p0,
                              ).paymentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.employerId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$EmployersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $EmployersTable,
      Employer,
      $$EmployersTableFilterComposer,
      $$EmployersTableOrderingComposer,
      $$EmployersTableAnnotationComposer,
      $$EmployersTableCreateCompanionBuilder,
      $$EmployersTableUpdateCompanionBuilder,
      (Employer, $$EmployersTableReferences),
      Employer,
      PrefetchHooks Function({bool workEntriesRefs, bool paymentsRefs})
    >;
typedef $$WorkEntriesTableCreateCompanionBuilder =
    WorkEntriesCompanion Function({
      Value<int> id,
      required int employerId,
      required String date,
      Value<String?> place,
      Value<String?> job,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<String> wageType,
      Value<int?> wageAmount,
      Value<int> outOfPocketAmount,
      Value<String?> note,
      required String createdAt,
    });
typedef $$WorkEntriesTableUpdateCompanionBuilder =
    WorkEntriesCompanion Function({
      Value<int> id,
      Value<int> employerId,
      Value<String> date,
      Value<String?> place,
      Value<String?> job,
      Value<String?> startTime,
      Value<String?> endTime,
      Value<String> wageType,
      Value<int?> wageAmount,
      Value<int> outOfPocketAmount,
      Value<String?> note,
      Value<String> createdAt,
    });

final class $$WorkEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $WorkEntriesTable, WorkEntry> {
  $$WorkEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmployersTable _employerIdTable(_$AppDatabase db) =>
      db.employers.createAlias('work_entries__employer_id__employers__id');

  $$EmployersTableProcessedTableManager get employerId {
    final $_column = $_itemColumn<int>('employer_id')!;

    final manager = $$EmployersTableTableManager(
      $_db,
      $_db.employers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WorkEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkEntriesTable> {
  $$WorkEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get job => $composableBuilder(
    column: $table.job,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get wageType => $composableBuilder(
    column: $table.wageType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wageAmount => $composableBuilder(
    column: $table.wageAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get outOfPocketAmount => $composableBuilder(
    column: $table.outOfPocketAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EmployersTableFilterComposer get employerId {
    final $$EmployersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employerId,
      referencedTable: $db.employers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployersTableFilterComposer(
            $db: $db,
            $table: $db.employers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkEntriesTable> {
  $$WorkEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get place => $composableBuilder(
    column: $table.place,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get job => $composableBuilder(
    column: $table.job,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get wageType => $composableBuilder(
    column: $table.wageType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wageAmount => $composableBuilder(
    column: $table.wageAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get outOfPocketAmount => $composableBuilder(
    column: $table.outOfPocketAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmployersTableOrderingComposer get employerId {
    final $$EmployersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employerId,
      referencedTable: $db.employers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployersTableOrderingComposer(
            $db: $db,
            $table: $db.employers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkEntriesTable> {
  $$WorkEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get place =>
      $composableBuilder(column: $table.place, builder: (column) => column);

  GeneratedColumn<String> get job =>
      $composableBuilder(column: $table.job, builder: (column) => column);

  GeneratedColumn<String> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<String> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<String> get wageType =>
      $composableBuilder(column: $table.wageType, builder: (column) => column);

  GeneratedColumn<int> get wageAmount => $composableBuilder(
    column: $table.wageAmount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get outOfPocketAmount => $composableBuilder(
    column: $table.outOfPocketAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EmployersTableAnnotationComposer get employerId {
    final $$EmployersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employerId,
      referencedTable: $db.employers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployersTableAnnotationComposer(
            $db: $db,
            $table: $db.employers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WorkEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkEntriesTable,
          WorkEntry,
          $$WorkEntriesTableFilterComposer,
          $$WorkEntriesTableOrderingComposer,
          $$WorkEntriesTableAnnotationComposer,
          $$WorkEntriesTableCreateCompanionBuilder,
          $$WorkEntriesTableUpdateCompanionBuilder,
          (WorkEntry, $$WorkEntriesTableReferences),
          WorkEntry,
          PrefetchHooks Function({bool employerId})
        > {
  $$WorkEntriesTableTableManager(_$AppDatabase db, $WorkEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> employerId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> place = const Value.absent(),
                Value<String?> job = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<String> wageType = const Value.absent(),
                Value<int?> wageAmount = const Value.absent(),
                Value<int> outOfPocketAmount = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => WorkEntriesCompanion(
                id: id,
                employerId: employerId,
                date: date,
                place: place,
                job: job,
                startTime: startTime,
                endTime: endTime,
                wageType: wageType,
                wageAmount: wageAmount,
                outOfPocketAmount: outOfPocketAmount,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int employerId,
                required String date,
                Value<String?> place = const Value.absent(),
                Value<String?> job = const Value.absent(),
                Value<String?> startTime = const Value.absent(),
                Value<String?> endTime = const Value.absent(),
                Value<String> wageType = const Value.absent(),
                Value<int?> wageAmount = const Value.absent(),
                Value<int> outOfPocketAmount = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String createdAt,
              }) => WorkEntriesCompanion.insert(
                id: id,
                employerId: employerId,
                date: date,
                place: place,
                job: job,
                startTime: startTime,
                endTime: endTime,
                wageType: wageType,
                wageAmount: wageAmount,
                outOfPocketAmount: outOfPocketAmount,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkEntriesTable, WorkEntry>(table),
                  $$WorkEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({employerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (employerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.employerId,
                        referencedTable: $$WorkEntriesTableReferences
                            ._employerIdTable(db),
                        referencedColumn: $$WorkEntriesTableReferences
                            ._employerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WorkEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkEntriesTable,
      WorkEntry,
      $$WorkEntriesTableFilterComposer,
      $$WorkEntriesTableOrderingComposer,
      $$WorkEntriesTableAnnotationComposer,
      $$WorkEntriesTableCreateCompanionBuilder,
      $$WorkEntriesTableUpdateCompanionBuilder,
      (WorkEntry, $$WorkEntriesTableReferences),
      WorkEntry,
      PrefetchHooks Function({bool employerId})
    >;
typedef $$PaymentsTableCreateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  required int employerId,
  required String date,
  required int amount,
  Value<String> type,
  Value<String?> note,
  required String createdAt,
});
typedef $$PaymentsTableUpdateCompanionBuilder = PaymentsCompanion Function({
  Value<int> id,
  Value<int> employerId,
  Value<String> date,
  Value<int> amount,
  Value<String> type,
  Value<String?> note,
  Value<String> createdAt,
});

final class $$PaymentsTableReferences
    extends BaseReferences<_$AppDatabase, $PaymentsTable, Payment> {
  $$PaymentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $EmployersTable _employerIdTable(_$AppDatabase db) =>
      db.employers.createAlias('payments__employer_id__employers__id');

  $$EmployersTableProcessedTableManager get employerId {
    final $_column = $_itemColumn<int>('employer_id')!;

    final manager = $$EmployersTableTableManager(
      $_db,
      $_db.employers,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_employerIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PaymentsTableFilterComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$EmployersTableFilterComposer get employerId {
    final $$EmployersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employerId,
      referencedTable: $db.employers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployersTableFilterComposer(
            $db: $db,
            $table: $db.employers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$EmployersTableOrderingComposer get employerId {
    final $$EmployersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employerId,
      referencedTable: $db.employers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployersTableOrderingComposer(
            $db: $db,
            $table: $db.employers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PaymentsTable> {
  $$PaymentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$EmployersTableAnnotationComposer get employerId {
    final $$EmployersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.employerId,
      referencedTable: $db.employers,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$EmployersTableAnnotationComposer(
            $db: $db,
            $table: $db.employers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PaymentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PaymentsTable,
          Payment,
          $$PaymentsTableFilterComposer,
          $$PaymentsTableOrderingComposer,
          $$PaymentsTableAnnotationComposer,
          $$PaymentsTableCreateCompanionBuilder,
          $$PaymentsTableUpdateCompanionBuilder,
          (Payment, $$PaymentsTableReferences),
          Payment,
          PrefetchHooks Function({bool employerId})
        > {
  $$PaymentsTableTableManager(_$AppDatabase db, $PaymentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PaymentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PaymentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PaymentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> employerId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String> createdAt = const Value.absent(),
              }) => PaymentsCompanion(
                id: id,
                employerId: employerId,
                date: date,
                amount: amount,
                type: type,
                note: note,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int employerId,
                required String date,
                required int amount,
                Value<String> type = const Value.absent(),
                Value<String?> note = const Value.absent(),
                required String createdAt,
              }) => PaymentsCompanion.insert(
                id: id,
                employerId: employerId,
                date: date,
                amount: amount,
                type: type,
                note: note,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PaymentsTable, Payment>(table),
                  $$PaymentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({employerId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (employerId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.employerId,
                        referencedTable: $$PaymentsTableReferences
                            ._employerIdTable(db),
                        referencedColumn: $$PaymentsTableReferences
                            ._employerIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PaymentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PaymentsTable,
      Payment,
      $$PaymentsTableFilterComposer,
      $$PaymentsTableOrderingComposer,
      $$PaymentsTableAnnotationComposer,
      $$PaymentsTableCreateCompanionBuilder,
      $$PaymentsTableUpdateCompanionBuilder,
      (Payment, $$PaymentsTableReferences),
      Payment,
      PrefetchHooks Function({bool employerId})
    >;
typedef $$KeyValuesTableCreateCompanionBuilder = KeyValuesCompanion Function({
  required String key,
  Value<String?> value,
  Value<int> rowid,
});
typedef $$KeyValuesTableUpdateCompanionBuilder = KeyValuesCompanion Function({
  Value<String> key,
  Value<String?> value,
  Value<int> rowid,
});

class $$KeyValuesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValuesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValuesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValuesTable> {
  $$KeyValuesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValuesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValuesTable,
          KeyValue,
          $$KeyValuesTableFilterComposer,
          $$KeyValuesTableOrderingComposer,
          $$KeyValuesTableAnnotationComposer,
          $$KeyValuesTableCreateCompanionBuilder,
          $$KeyValuesTableUpdateCompanionBuilder,
          (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
          KeyValue,
          PrefetchHooks Function()
        > {
  $$KeyValuesTableTableManager(_$AppDatabase db, $KeyValuesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValuesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValuesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValuesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => KeyValuesCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$KeyValuesTable, KeyValue>(table),
                  BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValuesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValuesTable,
      KeyValue,
      $$KeyValuesTableFilterComposer,
      $$KeyValuesTableOrderingComposer,
      $$KeyValuesTableAnnotationComposer,
      $$KeyValuesTableCreateCompanionBuilder,
      $$KeyValuesTableUpdateCompanionBuilder,
      (KeyValue, BaseReferences<_$AppDatabase, $KeyValuesTable, KeyValue>),
      KeyValue,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$EmployersTableTableManager get employers =>
      $$EmployersTableTableManager(_db, _db.employers);
  $$WorkEntriesTableTableManager get workEntries =>
      $$WorkEntriesTableTableManager(_db, _db.workEntries);
  $$PaymentsTableTableManager get payments =>
      $$PaymentsTableTableManager(_db, _db.payments);
  $$KeyValuesTableTableManager get keyValues =>
      $$KeyValuesTableTableManager(_db, _db.keyValues);
}
