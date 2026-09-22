import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/features/audio/data/drift_audio_track_repository.dart';
import 'package:nisabitus/features/audio/domain/audio_track.dart';
import 'package:nisabitus/features/audio/domain/audio_track_repository.dart';

void main() {
  late AppDatabase db;
  late AudioTrackRepository repository;

  const rain = 'https://www.youtube.com/watch?v=abcdefghijk';
  const bell = 'https://youtu.be/lmnopqrstuv';

  AudioTrackDraft draft(String name, String url, TrackUsage usage) =>
      AudioTrackDraft(name: name, url: url, usage: usage);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftAudioTrackRepository(db);
  });
  tearDown(() => db.close());

  test('starts empty, which is silence', () async {
    expect(await repository.list(TrackUsage.focus), isEmpty);
    expect(await repository.list(TrackUsage.meditation), isEmpty);
  });

  test('writes a track down and reads it back', () async {
    await repository.add(draft('Lluvia', rain, TrackUsage.focus));

    final stored = (await repository.list(TrackUsage.focus)).single;
    expect(stored.name, 'Lluvia');
    expect(stored.url, rain);
    expect(stored.isPlayable, isTrue);
  });

  test('keeps the two libraries apart', () async {
    // A twenty-minute guided sitting offered as background for a work
    // sprint is a line the user has to read past, not a shortcut.
    await repository.add(draft('Lluvia', rain, TrackUsage.focus));
    await repository.add(draft('Campana', bell, TrackUsage.meditation));

    expect((await repository.list(TrackUsage.focus)).map((t) => t.name), [
      'Lluvia',
    ]);
    expect((await repository.list(TrackUsage.meditation)).map((t) => t.name), [
      'Campana',
    ]);
  });

  test('keeps them in the order they were added', () async {
    // Not alphabetical: renaming one would reshuffle the list underneath
    // the user every time.
    await repository.add(draft('Lluvia', rain, TrackUsage.focus));
    await repository.add(draft('Blanco', bell, TrackUsage.focus));

    expect(
      (await repository.list(TrackUsage.focus)).map((track) => track.name),
      ['Lluvia', 'Blanco'],
    );
  });

  test('edits one in place, library and all', () async {
    final stored = await repository.add(
      draft('Lluvia', rain, TrackUsage.focus),
    );

    await repository.update(
      stored.id,
      draft('Campana', bell, TrackUsage.meditation),
    );

    expect(await repository.list(TrackUsage.focus), isEmpty);
    final moved = (await repository.list(TrackUsage.meditation)).single;
    expect(moved.id, stored.id);
    expect(moved.name, 'Campana');
    expect(moved.url, bell);
  });

  test('deletes one', () async {
    final stored = await repository.add(
      draft('Lluvia', rain, TrackUsage.focus),
    );

    await repository.delete(stored.id);

    expect(await repository.list(TrackUsage.focus), isEmpty);
  });
}
