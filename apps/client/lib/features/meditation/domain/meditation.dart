import '../../../core/time/date_range.dart';

/// One sat session.
///
/// Minutes and a day, and optionally a word about how it went. Deliberately
/// not a timer's output: the app records that you sat, it does not sit with
/// you. Someone who meditated with their eyes shut for twenty minutes should
/// be able to write that down afterwards without having asked the app first.
class MeditationSession {
  MeditationSession({
    required this.id,
    required DateTime date,
    required this.minutes,
    String? note,
  }) : date = dateOnly(date),
       note = _clean(note) {
    if (minutes <= 0 || minutes > maxMinutes) {
      throw ArgumentError.value(
        minutes,
        'minutes',
        'A session must be between 1 and $maxMinutes minutes',
      );
    }
  }

  /// Eight hours. Past that it is not a sitting, it is a typo.
  static const maxMinutes = 480;

  final int id;
  final DateTime date;
  final int minutes;

  /// How it went, in the user's own words. Blank reads as nothing written
  /// rather than as an empty note.
  final String? note;

  static String? _clean(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  MeditationSession copyWith({int? id}) => MeditationSession(
    id: id ?? this.id,
    date: date,
    minutes: minutes,
    note: note,
  );
}

/// What was sat on one day.
class DailyMeditation {
  const DailyMeditation({required this.sessions, required this.minutes});

  factory DailyMeditation.from(List<MeditationSession> sessions) =>
      DailyMeditation(
        sessions: sessions,
        minutes: sessions.fold(0, (sum, session) => sum + session.minutes),
      );

  final List<MeditationSession> sessions;

  /// Everything sat that day, added up. Two ten-minute sittings are twenty
  /// minutes of practice, not two separate days of it.
  final int minutes;

  bool get isEmpty => sessions.isEmpty;
}
