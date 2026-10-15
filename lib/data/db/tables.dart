import 'package:drift/drift.dart';

@DataClassName('Employer')
@TableIndex(name: 'idx_employers_archived', columns: {#isArchived})
class Employers extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 120)();

  IntColumn get color => integer().withDefault(const Constant(0xFF2E7D6F))();

  TextColumn get phone => text().nullable()();

  TextColumn get note => text().nullable()();

  TextColumn get defaultWageType =>
      text().withDefault(const Constant('fixed'))();

  IntColumn get defaultDailyWage => integer().nullable()();

  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  TextColumn get createdAt => text()();
}

@DataClassName('WorkEntry')
@TableIndex(name: 'idx_work_entries_employer', columns: {#employerId})
@TableIndex(name: 'idx_work_entries_date', columns: {#date})
class WorkEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get employerId =>
      integer().references(Employers, #id, onDelete: KeyAction.cascade)();

  TextColumn get date => text()();

  TextColumn get place => text().nullable()();

  TextColumn get job => text().nullable()();

  TextColumn get startTime => text().nullable()();

  TextColumn get endTime => text().nullable()();

  TextColumn get wageType => text().withDefault(const Constant('fixed'))();

  IntColumn get wageAmount => integer().nullable()();

  IntColumn get outOfPocketAmount => integer().withDefault(const Constant(0))();

  TextColumn get note => text().nullable()();

  TextColumn get createdAt => text()();
}

@DataClassName('Payment')
@TableIndex(name: 'idx_payments_employer', columns: {#employerId})
@TableIndex(name: 'idx_payments_date', columns: {#date})
class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get employerId =>
      integer().references(Employers, #id, onDelete: KeyAction.cascade)();

  TextColumn get date => text()();

  IntColumn get amount => integer()();

  TextColumn get type => text().withDefault(const Constant('wage'))();

  TextColumn get note => text().nullable()();

  TextColumn get createdAt => text()();
}

@DataClassName('KeyValue')
class KeyValues extends Table {
  TextColumn get key => text()();

  TextColumn get value => text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}
