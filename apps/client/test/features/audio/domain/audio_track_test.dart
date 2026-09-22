import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/audio/domain/audio_track.dart';

void main() {
  const youtube = 'https://www.youtube.com/watch?v=abcdefghijk';

  AudioTrackDraft draft({
    String name = 'Lluvia',
    String url = youtube,
    TrackUsage usage = TrackUsage.focus,
  }) => AudioTrackDraft(name: name, url: url, usage: usage);

  group('a draft', () {
    test('keeps the link exactly as it was pasted', () {
      expect(draft(url: ' $youtube ').url, youtube);
      expect(draft(name: '  Lluvia ').name, 'Lluvia');
    });

    test('takes a short youtu.be link too', () {
      expect(draft(url: 'https://youtu.be/abcdefghijk').url, isNotEmpty);
    });

    test('refuses a link nothing here could play', () {
      // Said when it is pasted, not in the middle of a sitting.
      for (final url in [
        'no es un link',
        'http://www.youtube.com/watch?v=abcdefghijk',
        'https://example.com/a-page',
        '',
      ]) {
        expect(() => draft(url: url), throwsArgumentError, reason: url);
      }
    });

    test('demands a name', () {
      expect(() => draft(name: '   '), throwsArgumentError);
      expect(() => draft(name: 'a' * 81), throwsArgumentError);
    });

    test('belongs to the library it was added in', () {
      expect(draft(usage: TrackUsage.meditation).usage, TrackUsage.meditation);
    });
  });

  group('the usage', () {
    test('survives a round trip through the column', () {
      for (final usage in TrackUsage.values) {
        expect(TrackUsage.parse(usage.wireName), usage);
      }
    });

    test('falls back to the focus library for anything unreadable', () {
      // The only library that existed when the column did not.
      expect(TrackUsage.parse(null), TrackUsage.focus);
      expect(TrackUsage.parse(''), TrackUsage.focus);
      expect(TrackUsage.parse('SOMETHING_ELSE'), TrackUsage.focus);
    });

    test('remembers the choice under the key it always used', () {
      // Changing it would silently unpick the sound someone had chosen.
      expect(TrackUsage.focus.preferenceKey, 'pomodoro');
    });
  });

  group('a stored track', () {
    test('reads its link', () {
      const track = AudioTrack(
        id: '1',
        name: 'Lluvia',
        url: youtube,
        usage: TrackUsage.focus,
      );

      expect(track.isPlayable, isTrue);
      expect(track.link?.playable, contains('youtube-nocookie.com/embed'));
    });

    test('is shown as unplayable rather than throwing', () {
      // A row from an older build, or from someone else's backup: the list
      // it lands in should still open.
      const track = AudioTrack(
        id: '1',
        name: 'Viejo',
        url: 'ftp://nope',
        usage: TrackUsage.meditation,
      );

      expect(track.link, isNull);
      expect(track.isPlayable, isFalse);
    });
  });
}
