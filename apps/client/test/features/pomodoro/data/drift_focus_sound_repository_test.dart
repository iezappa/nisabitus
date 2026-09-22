import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/features/pomodoro/data/drift_focus_sound_repository.dart';
import 'package:nisabitus/features/pomodoro/domain/focus_sound.dart';
import 'package:nisabitus/features/pomodoro/domain/focus_sound_repository.dart';

void main() {
  late AppDatabase db;
  late FocusSoundRepository repository;

  const rain = 'https://www.youtube.com/watch?v=abcdefghijk';
  const noise = 'https://youtu.be/lmnopqrstuv';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftFocusSoundRepository(db);
  });
  tearDown(() => db.close());

  test('starts empty, which is silence', () async {
    expect(await repository.list(), isEmpty);
  });

  test('writes a sound down and reads it back', () async {
    await repository.add(FocusSoundDraft(name: 'Lluvia', url: rain));

    final stored = (await repository.list()).single;
    expect(stored.name, 'Lluvia');
    expect(stored.url, rain);
    expect(stored.isPlayable, isTrue);
  });

  test('keeps them in the order they were added', () async {
    // Not alphabetical: renaming one would reshuffle the list underneath
    // the user every time.
    await repository.add(FocusSoundDraft(name: 'Lluvia', url: rain));
    await repository.add(FocusSoundDraft(name: 'Blanco', url: noise));

    expect((await repository.list()).map((sound) => sound.name), [
      'Lluvia',
      'Blanco',
    ]);
  });

  test('edits one in place', () async {
    final stored = await repository.add(
      FocusSoundDraft(name: 'Lluvia', url: rain),
    );

    await repository.update(
      stored.id,
      FocusSoundDraft(name: 'Lluvia suave', url: noise),
    );

    final updated = (await repository.list()).single;
    expect(updated.id, stored.id);
    expect(updated.name, 'Lluvia suave');
    expect(updated.url, noise);
  });

  test('deletes one', () async {
    final stored = await repository.add(
      FocusSoundDraft(name: 'Lluvia', url: rain),
    );

    await repository.delete(stored.id);

    expect(await repository.list(), isEmpty);
  });
}
