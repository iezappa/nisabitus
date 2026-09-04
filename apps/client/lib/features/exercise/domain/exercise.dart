/// A movement the user performs, described once and logged many times.
class Exercise {
  Exercise({
    required this.id,
    required String name,
    this.description,
    this.muscleGroup,
    this.videoUrl,
  }) : name = _validateName(name);

  final int id;
  final String name;
  final String? description;

  /// Free text, so the user's own vocabulary works.
  final String? muscleGroup;

  /// A video showing how the movement is done.
  ///
  /// On the movement rather than on a routine or a day: a squat is performed
  /// the same way whoever prescribed it, so the link is right once instead of
  /// copied into every plan that ever asks for one.
  final String? videoUrl;

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    return trimmed;
  }
}
