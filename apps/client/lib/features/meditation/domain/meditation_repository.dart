import '../../../core/time/date_range.dart';
import 'meditation.dart';
import 'meditation_stats.dart';

/// The user-editable fields of a session.
class MeditationDraft {
  const MeditationDraft({required this.minutes, this.note});

  final int minutes;
  final String? note;
}

/// The port the meditation module talks to.
abstract interface class MeditationRepository {
  /// What was sat on [day], in the order it was logged.
  Future<List<MeditationSession>> sessionsFor(DateTime day);

  /// The day's sessions together with their total.
  Future<DailyMeditation> dayFor(DateTime day);

  Future<MeditationSession> add(DateTime day, MeditationDraft draft);

  Future<MeditationSession> update(int id, MeditationDraft draft);

  Future<void> delete(int id);

  /// The figures the progress view shows for [range].
  Future<MeditationStats> statsFor(DateRange range);
}
