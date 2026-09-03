import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/time/date_range.dart';
import 'package:nisabitus/features/meditation/data/drift_meditation_repository.dart';
import 'package:nisabitus/features/meditation/domain/meditation_repository.dart';

void main() {
  late AppDatabase db;
  late MeditationRepository repository;

  final monday = DateTime(2026, 3, 9);
  final tuesday = DateTime(2026, 3, 10);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftMeditationRepository(db);
  });
  tearDown(() => db.close());

  test('writes a sitting down and reads it back on its day', () async {
    await repository.add(monday, const MeditationDraft(minutes: 20));

    expect((await repository.sessionsFor(monday)).single.minutes, 20);
    expect(await repository.sessionsFor(tuesday), isEmpty);
  });

  test('keeps every sitting of the day apart, and adds them up', () async {
    await repository.add(monday, const MeditationDraft(minutes: 10));
    await repository.add(monday, const MeditationDraft(minutes: 15));

    expect(await repository.sessionsFor(monday), hasLength(2));
    expect((await repository.dayFor(monday)).minutes, 25);
  });

  test('ignores the time of day it was sat at', () async {
    await repository.add(
      DateTime(2026, 3, 9, 6, 15),
      const MeditationDraft(minutes: 20),
    );

    expect(await repository.sessionsFor(monday), hasLength(1));
  });

  test('keeps the note as written', () async {
    await repository.add(
      monday,
      const MeditationDraft(minutes: 20, note: 'Costó arrancar'),
    );

    expect(
      (await repository.sessionsFor(monday)).single.note,
      'Costó arrancar',
    );
  });

  test('refuses a sitting the domain would not accept', () async {
    expect(
      repository.add(monday, const MeditationDraft(minutes: 0)),
      throwsArgumentError,
    );
    expect(await repository.sessionsFor(monday), isEmpty);
  });

  test('corrects a sitting without moving it to another day', () async {
    final session = await repository.add(
      monday,
      const MeditationDraft(minutes: 20),
    );

    await repository.update(session.id, const MeditationDraft(minutes: 30));

    final stored = (await repository.sessionsFor(monday)).single;
    expect(stored.minutes, 30);
    expect(stored.date, monday);
  });

  test('clears a note that was written before', () async {
    // Not the same as leaving it alone: someone who wrote something they did
    // not mean has to be able to take it back.
    final session = await repository.add(
      monday,
      const MeditationDraft(minutes: 20, note: 'Algo'),
    );

    await repository.update(session.id, const MeditationDraft(minutes: 20));

    expect((await repository.sessionsFor(monday)).single.note, isNull);
  });

  test('refuses to correct a sitting that is not there', () async {
    expect(
      repository.update(404, const MeditationDraft(minutes: 20)),
      throwsStateError,
    );
  });

  test('takes a sitting back', () async {
    final session = await repository.add(
      monday,
      const MeditationDraft(minutes: 20),
    );

    await repository.delete(session.id);

    expect(await repository.sessionsFor(monday), isEmpty);
  });

  test('reports only the window it was asked about', () async {
    await repository.add(monday, const MeditationDraft(minutes: 20));
    await repository.add(tuesday, const MeditationDraft(minutes: 30));

    final stats = await repository.statsFor(DateRange(monday, monday));

    expect(stats.totalMinutes, 20);
    expect(stats.daysPractised, 1);
  });
}
