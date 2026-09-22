import 'vacation.dart';

/// Reads and writes the breaks the user has taken.
abstract interface class VacationRepository {
  /// Every break, oldest first.
  Future<List<VacationPeriod>> list();

  /// Every break as one calendar, for the code that asks about a day.
  Future<VacationCalendar> calendar();

  /// Writes a break down. Returns the stored period.
  Future<VacationPeriod> add(VacationDraft draft);

  Future<VacationPeriod> update(String id, VacationDraft draft);

  Future<void> delete(String id);

  /// Starts an open-ended break on [day], if one is not already running.
  ///
  /// Returns the break the user is now on — the one that was already going,
  /// if there was one, so turning the switch on twice cannot file two.
  Future<VacationPeriod> start(DateTime day);

  /// Closes the break that is still going, on [day].
  ///
  /// Does nothing when no break is open. A break that started after [day] is
  /// closed on its own start date rather than before it began.
  Future<void> end(DateTime day);
}
