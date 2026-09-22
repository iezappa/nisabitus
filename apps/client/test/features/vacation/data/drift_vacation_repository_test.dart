import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/features/vacation/data/drift_vacation_repository.dart';
import 'package:nisabitus/features/vacation/domain/vacation.dart';
import 'package:nisabitus/features/vacation/domain/vacation_repository.dart';

void main() {
  late AppDatabase db;
  late VacationRepository repository;

  final monday = DateTime(2026, 9, 7);
  final friday = DateTime(2026, 9, 11);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftVacationRepository(db);
  });
  tearDown(() => db.close());

  test('starts with nothing paused', () async {
    expect(await repository.list(), isEmpty);
    expect((await repository.calendar()).covers(monday), isFalse);
  });

  test('writes a break down and reads it back', () async {
    await repository.add(
      VacationDraft(start: monday, end: friday, note: 'Viaje'),
    );

    final stored = (await repository.list()).single;
    expect(stored.start, monday);
    expect(stored.endsOn, friday);
    expect(stored.note, 'Viaje');
  });

  test('keeps the day only, not the hour it was written at', () async {
    await repository.add(VacationDraft(start: DateTime(2026, 9, 7, 23, 40)));

    expect((await repository.list()).single.start, monday);
  });

  group('the switch', () {
    test('opens a break with no end', () async {
      final started = await repository.start(monday);

      expect(started.isOpenEnded, isTrue);
      expect((await repository.calendar()).covers(friday), isTrue);
    });

    test('files one break however many times it is turned on', () async {
      await repository.start(monday);
      await repository.start(friday);

      final periods = await repository.list();
      expect(periods, hasLength(1));
      expect(periods.single.start, monday, reason: 'the first one stands');
    });

    test('closes the open break on the day it is turned off', () async {
      await repository.start(monday);
      await repository.end(friday);

      final stored = (await repository.list()).single;
      expect(stored.endsOn, friday);
      expect(stored.isOpenEnded, isFalse);
    });

    test('leaves a closed break alone when turned off again', () async {
      await repository.start(monday);
      await repository.end(friday);
      await repository.end(DateTime(2026, 9, 20));

      expect((await repository.list()).single.endsOn, friday);
    });

    test('never ends a break before it began', () async {
      // A holiday written down for next month, switched off today.
      await repository.add(VacationDraft(start: DateTime(2026, 10, 5)));
      await repository.end(monday);

      final stored = (await repository.list()).single;
      expect(stored.endsOn, DateTime(2026, 10, 5));
    });
  });

  test('edits a break in place', () async {
    final stored = await repository.add(VacationDraft(start: monday));

    await repository.update(
      stored.id,
      VacationDraft(start: monday, end: friday, note: 'Gripe'),
    );

    final updated = (await repository.list()).single;
    expect(updated.id, stored.id);
    expect(updated.endsOn, friday);
    expect(updated.note, 'Gripe');
  });

  test('deletes a break, and stops pausing its days', () async {
    final stored = await repository.add(
      VacationDraft(start: monday, end: friday),
    );

    await repository.delete(stored.id);

    expect(await repository.list(), isEmpty);
    expect((await repository.calendar()).covers(monday), isFalse);
  });

  test('lists the breaks oldest first', () async {
    await repository.add(VacationDraft(start: friday));
    await repository.add(VacationDraft(start: monday, end: monday));

    expect((await repository.list()).map((period) => period.start), [
      monday,
      friday,
    ]);
  });
}
