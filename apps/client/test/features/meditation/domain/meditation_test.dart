import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/meditation/domain/meditation.dart';

void main() {
  final day = DateTime(2026, 3, 11);

  MeditationSession sat(int minutes, {int id = 1, String? note}) =>
      MeditationSession(id: id, date: day, minutes: minutes, note: note);

  group('MeditationSession', () {
    test('keeps the day it was sat on, without its time', () {
      final session = MeditationSession(
        id: 1,
        date: DateTime(2026, 3, 11, 6, 30),
        minutes: 20,
      );

      expect(session.date, day);
    });

    test('refuses a session of no time at all', () {
      expect(() => sat(0), throwsArgumentError);
    });

    test('refuses a session nobody sat', () {
      expect(() => sat(481), throwsArgumentError);
    });

    test('trims the note it was given', () {
      expect(sat(20, note: '  Costó arrancar  ').note, 'Costó arrancar');
    });

    test('reads a blank note as nothing written', () {
      // Not an empty note: a note that says nothing and a note nobody wrote
      // are the same thing, and only one of them should reach the screen.
      expect(sat(20, note: '   ').note, isNull);
      expect(sat(20).note, isNull);
    });

    test('carries everything through a copy', () {
      final copy = sat(20, note: 'Bien').copyWith(id: 9);

      expect(copy.id, 9);
      expect(copy.minutes, 20);
      expect(copy.note, 'Bien');
    });
  });

  group('DailyMeditation', () {
    test('is empty before anything was sat', () {
      expect(DailyMeditation.from(const []).isEmpty, isTrue);
    });

    test('adds the sittings of a day together', () {
      // Two ten-minute sittings are twenty minutes of practice, not two
      // separate days of it.
      final today = DailyMeditation.from([sat(10, id: 1), sat(10, id: 2)]);

      expect(today.minutes, 20);
      expect(today.sessions, hasLength(2));
    });
  });
}
