/// Whether an entry is something prescribed or something taken by choice.
///
/// The app draws no conclusion from this; it only groups the list so the two
/// are not read as the same thing.
enum MedicationKind {
  medication('MEDICATION'),
  supplement('SUPPLEMENT');

  const MedicationKind(this.wireName);

  final String wireName;

  static const fallback = MedicationKind.supplement;

  static MedicationKind parse(String? value) {
    final normalized = value?.trim().toUpperCase() ?? '';
    if (normalized.isEmpty) return fallback;

    for (final kind in MedicationKind.values) {
      if (kind.wireName == normalized) return kind;
    }
    throw ArgumentError.value(value, 'value', 'Unknown medication kind');
  }
}

/// Something the user takes.
///
/// Dose and schedule are free text on purpose: the app records what the
/// user was told, it does not compute or validate a regimen.
class Medication {
  Medication({
    required this.id,
    required String name,
    required this.kind,
    this.dose,
    this.schedule,
    this.notes,
    this.active = true,
    this.activeFrom,
  }) : name = _validateName(name);

  final int id;
  final String name;
  final MedicationKind kind;
  final String? dose;
  final String? schedule;
  final String? notes;

  /// Paused entries stay in the list but leave the day alone.
  final bool active;

  /// The day this entry started counting, or null when it predates the app
  /// recording that — in which case it counts for as far back as anyone asks.
  final DateTime? activeFrom;

  /// Whether this entry was part of the regimen on [day].
  bool startedBy(DateTime day) =>
      activeFrom == null || !activeFrom!.isAfter(day);

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    return trimmed;
  }

  /// The dose and schedule on one line, for the list.
  String get summary =>
      [dose, schedule].where((v) => (v ?? '').trim().isNotEmpty).join(' · ');
}

/// One entry as it stands on a given day.
typedef MedicationStatus = ({Medication medication, bool taken});

/// What is due on a day, and how much of it is done.
class MedicationDay {
  const MedicationDay({required this.statuses});

  /// Only what was active and already started reaches [day]; the rest is
  /// history or has not begun, and neither is a task for that day.
  factory MedicationDay.from(
    List<Medication> medications,
    Set<int> takenIds, {
    required DateTime day,
  }) => MedicationDay(
    statuses: [
      for (final medication in medications)
        if (medication.active && medication.startedBy(day))
          (medication: medication, taken: takenIds.contains(medication.id)),
    ],
  );

  final List<MedicationStatus> statuses;

  bool get isEmpty => statuses.isEmpty;

  int get total => statuses.length;
  int get taken => statuses.where((s) => s.taken).length;

  bool get isComplete => total > 0 && taken == total;
}
