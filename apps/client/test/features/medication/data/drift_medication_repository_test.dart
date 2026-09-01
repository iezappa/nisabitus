import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/medication/data/drift_medication_repository.dart';
import 'package:nisabitus/features/medication/domain/medication.dart';
import 'package:nisabitus/features/medication/domain/medication_repository.dart';

void main() {
  late AppDatabase db;
  late MedicationRepository repository;

  final monday = DateTime(2026, 3, 9);
  final tuesday = DateTime(2026, 3, 10);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftMedicationRepository(db);
  });
  tearDown(() => db.close());

  Future<Medication> create({
    String name = 'Vitamina D',
    MedicationKind kind = MedicationKind.supplement,
    String? dose,
    String? schedule,
    bool active = true,
  }) => repository.create(
    MedicationDraft(
      name: name,
      kind: kind,
      dose: dose,
      schedule: schedule,
      active: active,
    ),
  );

  group('MedicationKind', () {
    test('round-trips and falls back on a blank', () {
      expect(MedicationKind.parse('MEDICATION'), MedicationKind.medication);
      expect(MedicationKind.parse('supplement'), MedicationKind.supplement);
      expect(MedicationKind.parse(null), MedicationKind.fallback);
    });

    test('rejects a value it does not know', () {
      expect(() => MedicationKind.parse('VITAMIN'), throwsArgumentError);
    });
  });

  group('the list', () {
    test('starts empty', () async {
      expect(await repository.all(), isEmpty);
    });

    test('rejects a blank name', () {
      expect(() => create(name: '   '), throwsArgumentError);
    });

    test('keeps the dose and schedule as free text', () async {
      await create(dose: '2 cápsulas', schedule: 'Con el desayuno');

      final stored = (await repository.all()).single;
      expect(stored.dose, '2 cápsulas');
      expect(stored.schedule, 'Con el desayuno');
      expect(stored.summary, '2 cápsulas · Con el desayuno');
    });

    test('puts what is active first, then alphabetical', () async {
      await create(name: 'Zinc');
      await create(name: 'Omega 3');
      await create(name: 'Ibuprofeno', active: false);

      expect(
        (await repository.all()).map((m) => m.name),
        ['Omega 3', 'Zinc', 'Ibuprofeno'],
      );
    });

    test('can be edited and removed', () async {
      final medication = await create();

      await repository.update(
        medication.id,
        const MedicationDraft(
          name: 'Vitamina D3',
          kind: MedicationKind.supplement,
          dose: '1000 UI',
        ),
      );
      expect((await repository.all()).single.dose, '1000 UI');

      await repository.delete(medication.id);
      expect(await repository.all(), isEmpty);
    });
  });

  group('the day', () {
    test('lists only what is active', () async {
      await create(name: 'Activo');
      await create(name: 'Pausado', active: false);

      final day = await repository.dayFor(monday);

      expect(day.statuses.map((s) => s.medication.name), ['Activo']);
    });

    test('starts with nothing ticked', () async {
      await create();

      final day = await repository.dayFor(monday);

      expect(day.taken, 0);
      expect(day.total, 1);
      expect(day.isComplete, isFalse);
    });

    test('ticks and unticks the same entry', () async {
      final medication = await create();

      expect(await repository.toggleIntake(medication.id, monday), isTrue);
      expect((await repository.dayFor(monday)).taken, 1);

      expect(await repository.toggleIntake(medication.id, monday), isFalse);
      expect((await repository.dayFor(monday)).taken, 0);
    });

    test('keeps each day separate', () async {
      final medication = await create();
      await repository.toggleIntake(medication.id, monday);

      expect((await repository.dayFor(monday)).taken, 1);
      expect((await repository.dayFor(tuesday)).taken, 0);
    });

    test('is complete once everything active is ticked', () async {
      final a = await create(name: 'A');
      final b = await create(name: 'B');
      await create(name: 'Pausado', active: false);

      await repository.toggleIntake(a.id, monday);
      await repository.toggleIntake(b.id, monday);

      // The paused one is history, so it cannot hold the day open.
      expect((await repository.dayFor(monday)).isComplete, isTrue);
    });

    test('is empty when nothing is active', () async {
      await create(active: false);

      expect((await repository.dayFor(monday)).isEmpty, isTrue);
    });

    test('forgets the ticks of a deleted entry', () async {
      final medication = await create();
      await repository.toggleIntake(medication.id, monday);

      await repository.delete(medication.id);

      expect((await repository.dayFor(monday)).isEmpty, isTrue);
      expect(await db.select(db.medicationIntakes).get(), isEmpty);
    });
  });

  group('statsFor', () {
    test('is empty while nothing is active', () async {
      await create(active: false);

      final stats = await repository.statsFor(DateRange(monday, tuesday));

      expect(stats.isEmpty, isTrue);
    });

    test('measures the ticks against the active entries', () async {
      final vitamin = await create(name: 'Vitamina D');
      await create(name: 'Omega 3');
      await repository.toggleIntake(vitamin.id, monday);

      final stats = await repository.statsFor(DateRange(monday, tuesday));

      // Two entries over two days is four doses expected; one was taken.
      expect(stats.activeCount, 2);
      expect(stats.adherencePercent, 25);
      expect(stats.completeDays, 0);
    });

    test('counts a day complete once everything active is ticked', () async {
      final vitamin = await create(name: 'Vitamina D');
      final omega = await create(name: 'Omega 3');
      await repository.toggleIntake(vitamin.id, monday);
      await repository.toggleIntake(omega.id, monday);

      final stats = await repository.statsFor(DateRange(monday, tuesday));

      expect(stats.completeDays, 1);
    });

    test('leaves a paused entry out of both sides of the sum', () async {
      final vitamin = await create(name: 'Vitamina D');
      final paused = await create(name: 'Omega 3');
      await repository.toggleIntake(vitamin.id, monday);
      await repository.toggleIntake(paused.id, monday);
      await repository.update(
        paused.id,
        const MedicationDraft(name: 'Omega 3', active: false),
      );

      final stats = await repository.statsFor(DateRange(monday, monday));

      // One active entry, ticked on the only day of the window.
      expect(stats.activeCount, 1);
      expect(stats.adherencePercent, 100);
    });

    test('ignores ticks outside the window', () async {
      final vitamin = await create();
      await repository.toggleIntake(vitamin.id, DateTime(2026, 3, 20));

      final stats = await repository.statsFor(DateRange(monday, tuesday));

      expect(stats.adherencePercent, 0);
    });
  });
}
