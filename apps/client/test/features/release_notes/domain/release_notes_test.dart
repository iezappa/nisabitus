import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/release_notes/domain/app_version.dart';
import 'package:nisabitus/features/release_notes/domain/release_notes.dart';

void main() {
  String document(List<Map<String, Object?>> releases) =>
      jsonEncode({'releases': releases});

  Map<String, Object?> release(
    String version, {
    String date = '2026-08-30',
    List<String> highlights = const ['Something new'],
  }) => {'version': version, 'date': date, 'highlights': highlights};

  group('ReleaseNotes.parse', () {
    test('reads a release', () {
      final notes = ReleaseNotes.parse(
        document([
          release('1.1.0', date: '2026-08-30', highlights: ['A', 'B']),
        ]),
      );

      final note = notes.all.single;
      expect(note.version, AppVersion.parse('1.1.0'));
      expect(note.date, DateTime(2026, 8, 30));
      expect(note.highlights, ['A', 'B']);
    });

    test('orders the releases newest first, whatever the file says', () {
      final notes = ReleaseNotes.parse(
        document([release('1.0.0'), release('1.10.0'), release('1.9.0')]),
      );

      expect(notes.all.map((note) => '${note.version}'), [
        '1.10.0',
        '1.9.0',
        '1.0.0',
      ]);
    });

    test(
      'rejects a file with no releases, which would have no current version',
      () {
        expect(() => ReleaseNotes.parse(document([])), throwsFormatException);
      },
    );

    test('rejects the same version twice', () {
      expect(
        () =>
            ReleaseNotes.parse(document([release('1.0.0'), release('1.0.0')])),
        throwsFormatException,
      );
    });

    test('rejects a release with nothing to say', () {
      expect(
        () => ReleaseNotes.parse(document([release('1.0.0', highlights: [])])),
        throwsFormatException,
      );
    });

    test('rejects a blank highlight', () {
      expect(
        () => ReleaseNotes.parse(
          document([
            release('1.0.0', highlights: ['  ']),
          ]),
        ),
        throwsFormatException,
      );
    });

    test('rejects a malformed version', () {
      expect(
        () => ReleaseNotes.parse(document([release('1.0')])),
        throwsFormatException,
      );
    });

    test('rejects a malformed date', () {
      expect(
        () => ReleaseNotes.parse(document([release('1.0.0', date: 'ayer')])),
        throwsFormatException,
      );
    });

    test('rejects text that is not a JSON object', () {
      expect(() => ReleaseNotes.parse('[]'), throwsFormatException);
      expect(() => ReleaseNotes.parse('not json'), throwsFormatException);
    });
  });

  group('ReleaseNotes.current', () {
    test('is the newest version the file declares', () {
      final notes = ReleaseNotes.parse(
        document([release('1.0.0'), release('1.2.0')]),
      );

      expect(notes.current, AppVersion.parse('1.2.0'));
    });
  });

  group('ReleaseNotes.since', () {
    final notes = ReleaseNotes.parse(
      document([release('1.0.0'), release('1.1.0'), release('1.2.0')]),
    );

    test('hands over everything to someone who has seen nothing', () {
      expect(notes.since(null), hasLength(3));
    });

    test('hands over only what came after the version seen', () {
      final unseen = notes.since(AppVersion.parse('1.0.0'));

      expect(unseen.map((note) => '${note.version}'), ['1.2.0', '1.1.0']);
    });

    test('hands over nothing to someone already on the newest', () {
      expect(notes.since(AppVersion.parse('1.2.0')), isEmpty);
    });

    test('hands over nothing when the seen version is ahead of the file', () {
      // A downgrade. Nothing to announce, and nothing to crash over.
      expect(notes.since(AppVersion.parse('2.0.0')), isEmpty);
    });
  });
}
