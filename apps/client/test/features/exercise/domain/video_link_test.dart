import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/exercise/domain/video_link.dart';

void main() {
  group('YouTube, in whichever shape the browser gave it', () {
    // The same video, four ways. The user pastes whatever was in the address
    // bar, and a watch page cannot be put in a frame.
    const id = 'dQw4w9WgXcQ';
    const embed = 'https://www.youtube-nocookie.com/embed/$id';

    test('a watch page', () {
      expect(
        VideoLink.parse('https://www.youtube.com/watch?v=$id')?.playable,
        embed,
      );
    });

    test('a share link', () {
      expect(VideoLink.parse('https://youtu.be/$id')?.playable, embed);
    });

    test('a short', () {
      expect(
        VideoLink.parse('https://www.youtube.com/shorts/$id')?.playable,
        embed,
      );
    });

    test('an embed link already', () {
      expect(
        VideoLink.parse('https://www.youtube.com/embed/$id')?.playable,
        embed,
      );
    });

    test('a watch page with a timestamp and a playlist on it', () {
      expect(
        VideoLink.parse('https://www.youtube.com/watch?v=$id&t=42s&list=PL123')
            ?.playable,
        embed,
      );
    });

    test('the no-cookie host, not the tracking one', () {
      // The app tells the user it does not track them. Embedding the ordinary
      // player would quietly make that less true the moment a card opened.
      expect(
        VideoLink.parse('https://www.youtube.com/watch?v=$id')?.playable,
        contains('youtube-nocookie.com'),
      );
    });

    test('a channel page is not a video', () {
      final link = VideoLink.parse('https://www.youtube.com/@alguien');

      expect(link?.kind, VideoKind.external);
      expect(link?.canPlayInline, isFalse);
    });
  });

  group('Vimeo', () {
    test('a video is embeddable', () {
      expect(
        VideoLink.parse('https://vimeo.com/123456789')?.playable,
        'https://player.vimeo.com/video/123456789',
      );
    });

    test('a user page is not', () {
      expect(
        VideoLink.parse('https://vimeo.com/alguien')?.kind,
        VideoKind.external,
      );
    });
  });

  group('a file a browser can play on its own', () {
    test('is played where it is', () {
      final link = VideoLink.parse('https://ejemplo.com/sentadilla.mp4');

      expect(link?.kind, VideoKind.file);
      expect(link?.playable, 'https://ejemplo.com/sentadilla.mp4');
    });

    test('is recognised whatever the case of the extension', () {
      expect(
        VideoLink.parse('https://ejemplo.com/Sentadilla.WEBM')?.kind,
        VideoKind.file,
      );
    });
  });

  group('what is not a link at all', () {
    test('nothing written down', () {
      expect(VideoLink.parse(null), isNull);
      expect(VideoLink.parse('   '), isNull);
    });

    test('a note the user typed into the field', () {
      expect(VideoLink.parse('mirar el video de siempre'), isNull);
    });

    test('an http page, which no https page may frame', () {
      // Accepting it would only produce a viewer that is permanently blank.
      expect(VideoLink.parse('http://ejemplo.com/video.mp4'), isNull);
    });

    test('a youtube link whose id is not an id', () {
      expect(
        VideoLink.parse('https://www.youtube.com/watch?v=a b c')?.kind,
        VideoKind.external,
      );
    });
  });

  test('the link the user saved is what gets opened outside', () {
    // The embed page is for the frame. Sending someone to it in their browser
    // would drop them on a bare player with no title and no way back.
    const original = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';

    expect(VideoLink.parse(original)?.original, original);
  });
}
