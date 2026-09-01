/// How much energy the day carried.
enum EnergyLevel {
  low('Baja'),
  medium('Media'),
  high('Alta');

  const EnergyLevel(this.storedName);

  /// The exact word written into the serialized entry.
  final String storedName;

  static EnergyLevel? parse(String? value) {
    final normalized = value?.trim() ?? '';
    for (final level in EnergyLevel.values) {
      if (level.storedName == normalized) return level;
    }
    return null;
  }
}

/// The six fields of a journal entry.
///
/// They are stored inside a single text column as markdown-style sections,
/// so the schema never has to change when a field is added, and an entry
/// written by an older version can still be read.
class JournalContent {
  const JournalContent({
    this.mood = '',
    this.energy,
    this.gratitude = '',
    this.focus = '',
    this.reflection = '',
    this.intention = '',
  });

  /// Reads the six fields back out of a stored entry.
  ///
  /// Content with no `## ` heading comes from an earlier version that had a
  /// single free-text field, so all of it is taken as the reflection.
  factory JournalContent.parse(String content) {
    final text = content.trim();
    if (text.isEmpty) return const JournalContent();
    if (!text.contains('$_heading ')) {
      return JournalContent(reflection: text);
    }

    final sections = <String, String>{};
    String? current;
    final buffer = <String>[];

    void flush() {
      if (current case final label?) {
        sections[label] = buffer.join('\n').trim();
      }
      buffer.clear();
    }

    for (final line in text.split('\n')) {
      if (line.startsWith('$_heading ')) {
        flush();
        current = line.substring(_heading.length + 1).trim();
      } else if (current != null) {
        buffer.add(line);
      }
    }
    flush();

    String read(String key) {
      final value = sections[key] ?? '';
      return value == _empty ? '' : value;
    }

    return JournalContent(
      mood: read(_moodLabel),
      energy: EnergyLevel.parse(read(_energyLabel)),
      gratitude: read(_gratitudeLabel),
      focus: read(_focusLabel),
      reflection: read(_reflectionLabel),
      intention: read(_intentionLabel),
    );
  }

  final String mood;
  final EnergyLevel? energy;
  final String gratitude;
  final String focus;
  final String reflection;
  final String intention;

  static const _heading = '##';

  /// What an untouched field looks like once written, so the section survives
  /// the round trip instead of collapsing.
  static const _empty = '-';

  // These labels are part of the stored format, not UI copy: renaming one
  // would make every existing entry unreadable.
  static const _moodLabel = 'Estado emocional';
  static const _energyLabel = 'Energía';
  static const _gratitudeLabel = 'Gratitud';
  static const _focusLabel = 'Foco del día';
  static const _reflectionLabel = 'Reflexión';
  static const _intentionLabel = 'Intención para mañana';

  bool get isEmpty =>
      mood.isEmpty &&
      energy == null &&
      gratitude.isEmpty &&
      focus.isEmpty &&
      reflection.isEmpty &&
      intention.isEmpty;

  String serialize() => [
    _section(_moodLabel, mood),
    _section(_energyLabel, energy?.storedName ?? ''),
    _section(_gratitudeLabel, gratitude),
    _section(_focusLabel, focus),
    _section(_reflectionLabel, reflection),
    _section(_intentionLabel, intention),
  ].join('\n\n');

  static String _section(String label, String value) {
    final body = value.trim().isEmpty ? _empty : value.trim();
    return '$_heading $label\n$body';
  }

  /// The line the journal history shows: the first section that says
  /// something, in the order the user is most likely to recognise.
  String get journalPreview {
    for (final candidate in [reflection, gratitude, focus, mood]) {
      if (candidate.trim().isNotEmpty) return candidate.trim();
    }
    return '';
  }

  /// Value equality matters: the form compares the entry it was given
  /// against the previous one to decide whether the day changed. With
  /// identity comparison every rebuild would look like a new day and wipe
  /// whatever the user was typing.
  @override
  bool operator ==(Object other) =>
      other is JournalContent &&
      other.mood == mood &&
      other.energy == energy &&
      other.gratitude == gratitude &&
      other.focus == focus &&
      other.reflection == reflection &&
      other.intention == intention;

  @override
  int get hashCode =>
      Object.hash(mood, energy, gratitude, focus, reflection, intention);

  /// The line the dashboard shows.
  ///
  /// Deliberately different from [journalPreview]: the dashboard has one
  /// line for the whole day, so it flattens everything rather than choosing.
  static String dashboardPreview(String content) {
    final joined = content
        .split('\n')
        .map(
          (line) => line.startsWith('$_heading ')
              ? line.substring(_heading.length + 1).trim()
              : line.trim(),
        )
        .where((line) => line.isNotEmpty && line != _empty)
        .join(' · ');

    if (joined.length <= _previewLength) return joined;

    // Cut back to the last space so a word is never left half written, and
    // say that it was cut: a preview that simply stops reads as the whole
    // entry, and the user has no way to tell there is more to read.
    final cut = joined.substring(0, _previewLength);
    final lastSpace = cut.lastIndexOf(' ');
    final kept = lastSpace <= 0 ? cut : cut.substring(0, lastSpace);

    return '${kept.trimRight()}…';
  }

  /// How much of an entry the dashboard shows before it says "there is more".
  static const _previewLength = 120;
}
