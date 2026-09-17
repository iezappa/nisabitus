import 'package:drift/drift.dart';

import 'uuid.dart';

/// The two columns every synchronisable record carries
/// (STACK-APPS-DINAMICAS.md 1.1).
///
/// - `id`: a UUID generated on the device, never an autoincrement number, so
///   records created on two devices can never collide.
/// - `updatedAt`: when the row was last written. Set on insert here, and set
///   by the repositories on every update; last-write-wins sync reads it.
mixin RecordColumns on Table {
  TextColumn get id => text().clientDefault(newUuid)();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The id of the only row of a [SingletonColumns] table.
const singletonId = 'singleton';

/// A table that holds exactly one row, such as a daily goal.
///
/// Its id is fixed rather than random: the row is "the goal", not "a goal",
/// and two devices must agree on which row that is.
mixin SingletonColumns on Table {
  TextColumn get id => text().withDefault(const Constant(singletonId))();

  DateTimeColumn get updatedAt => dateTime().clientDefault(DateTime.now)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Updates that also stamp `updatedAt`.
///
/// Every repository update goes through [writeTouched] rather than `write`,
/// so a row cannot change without its `updatedAt` moving with it — the one
/// field a last-write-wins sync decides on.
extension TouchingWrites<T extends Table, D> on UpdateStatement<T, D> {
  Future<int> writeTouched(Insertable<D> row, {DateTime? at}) => write(
    RawValuesInsertable<D>({
      ...row.toColumns(false),
      'updated_at': Variable<DateTime>(at ?? DateTime.now()),
    }),
  );
}
