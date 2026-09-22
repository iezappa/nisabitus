import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/pomodoro/domain/focus_sound.dart';

void main() {
  const youtube = 'https://www.youtube.com/watch?v=abcdefghijk';

  group('a draft', () {
    test('keeps the link exactly as it was pasted', () {
      final draft = FocusSoundDraft(name: 'Lluvia', url: ' $youtube ');

      expect(draft.url, youtube);
      expect(draft.name, 'Lluvia');
    });

    test('takes a short youtu.be link too', () {
      expect(
        FocusSoundDraft(
          name: 'Lluvia',
          url: 'https://youtu.be/abcdefghijk',
        ).url,
        isNotEmpty,
      );
    });

    test('refuses a link nothing here could play', () {
      // Said when it is pasted, not in the middle of a focus session.
      for (final url in [
        'no es un link',
        'http://www.youtube.com/watch?v=abcdefghijk',
        'https://example.com/a-page',
        '',
      ]) {
        expect(
          () => FocusSoundDraft(name: 'Lluvia', url: url),
          throwsArgumentError,
          reason: url,
        );
      }
    });

    test('demands a name', () {
      expect(
        () => FocusSoundDraft(name: '   ', url: youtube),
        throwsArgumentError,
      );
      expect(
        () => FocusSoundDraft(name: 'a' * 81, url: youtube),
        throwsArgumentError,
      );
    });
  });

  group('a stored sound', () {
    test('reads its link', () {
      final sound = const FocusSound(id: '1', name: 'Lluvia', url: youtube);

      expect(sound.isPlayable, isTrue);
      expect(sound.link?.playable, contains('youtube-nocookie.com/embed'));
    });

    test('is shown as unplayable rather than throwing', () {
      // A row from an older build, or from someone else's backup: the list
      // it lands in should still open.
      const sound = FocusSound(id: '1', name: 'Viejo', url: 'ftp://nope');

      expect(sound.link, isNull);
      expect(sound.isPlayable, isFalse);
    });
  });
}
