/// The user-editable fields of a focus session.
class PomodoroDraft {
  const PomodoroDraft({
    required this.name,
    this.category,
    this.purpose,
    this.cycles = 4,
    this.focusDuration = 25,
    this.breakDuration = 5,
  });

  final String name;
  final String? category;
  final String? purpose;
  final int cycles;
  final int focusDuration;
  final int breakDuration;
}
