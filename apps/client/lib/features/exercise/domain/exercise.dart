import '../../../core/time/date_range.dart';

/// A movement the user performs, described once and logged many times.
class Exercise {
  Exercise({
    required this.id,
    required String name,
    this.description,
    this.muscleGroup,
  }) : name = _validateName(name);

  final int id;
  final String name;
  final String? description;

  /// Free text, so the user's own vocabulary works.
  final String? muscleGroup;

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    return trimmed;
  }
}

/// One set performed on one day.
class ExerciseSet {
  ExerciseSet({
    required this.id,
    required this.exerciseId,
    required DateTime date,
    required this.reps,
    this.weight,
    this.position = 0,
  }) : date = dateOnly(date) {
    if (reps < 1 || reps > 1000) {
      throw ArgumentError.value(reps, 'reps', 'Must be between 1 and 1000');
    }
    if (weight != null && (weight! < 0 || weight! > 1000)) {
      throw ArgumentError.value(weight, 'weight', 'Must be between 0 and 1000');
    }
  }

  final int id;
  final int exerciseId;
  final DateTime date;
  final int reps;

  /// Null for bodyweight work, which is not the same as zero.
  final double? weight;

  final int position;

  /// Reps times weight. Bodyweight sets contribute no load, only reps.
  double get volume => (weight ?? 0) * reps;
}

/// One exercise as it was worked on a given day.
class ExerciseBlock {
  const ExerciseBlock({required this.exercise, required this.sets});

  final Exercise exercise;

  /// In the order they were performed.
  final List<ExerciseSet> sets;

  int get totalReps => sets.fold(0, (sum, set) => sum + set.reps);
  double get volume => sets.fold(0, (sum, set) => sum + set.volume);

  /// The heaviest set of the block, which is what a lifter looks for first.
  double? get topWeight {
    final weights = sets.map((s) => s.weight).nonNulls;
    return weights.isEmpty ? null : weights.reduce((a, b) => a > b ? a : b);
  }
}

/// A day's training, grouped by exercise.
class WorkoutDay {
  const WorkoutDay({required this.blocks});

  /// Groups loose sets under the exercise they belong to, keeping the order
  /// in which each exercise first appears that day.
  factory WorkoutDay.from(
    List<ExerciseSet> sets,
    Map<int, Exercise> exercises,
  ) {
    final ordered = [...sets]..sort((a, b) => a.position.compareTo(b.position));

    final grouped = <int, List<ExerciseSet>>{};
    for (final set in ordered) {
      grouped.putIfAbsent(set.exerciseId, () => []).add(set);
    }

    return WorkoutDay(
      blocks: [
        for (final entry in grouped.entries)
          if (exercises[entry.key] case final exercise?)
            ExerciseBlock(exercise: exercise, sets: entry.value),
      ],
    );
  }

  final List<ExerciseBlock> blocks;

  bool get isEmpty => blocks.isEmpty;

  int get totalSets => blocks.fold(0, (sum, b) => sum + b.sets.length);
  int get totalReps => blocks.fold(0, (sum, b) => sum + b.totalReps);
  double get totalVolume => blocks.fold(0, (sum, b) => sum + b.volume);
}
