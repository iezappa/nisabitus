/// A column of the to-do board.
///
/// Until v15 these were an enum, so the board was a decision the code had
/// made for everybody. They are rows the user owns now: add one, rename one,
/// reorder them, drop one that is not useful.
class BoardColumn {
  BoardColumn({
    required this.id,
    required this.projectId,
    required String name,
    required this.position,
    this.builtInKey,
    this.countsAsDone = false,
  }) : name = _validateName(name);

  /// The keys the app seeds the board with.
  ///
  /// A column carrying one of these is shown under its translation rather
  /// than its stored name, so the three a fresh install has read in the
  /// user's language. Renaming clears the key — see [renamedTo].
  static const todoKey = 'TODO';
  static const inProgressKey = 'IN_PROGRESS';
  static const doneKey = 'DONE';

  /// The longest a column name may be.
  ///
  /// Short on purpose: it is a heading over a narrow column, and a name that
  /// does not fit is a name nobody can read.
  static const maxNameLength = 60;

  final String id;

  /// The project whose board this column belongs to.
  ///
  /// One board per project as of v16: a column added for one piece of work
  /// used to turn up on every other project's board.
  final String projectId;

  /// What the user called it, or the seeded word while [builtInKey] is set.
  ///
  /// Read [displayName] rather than this for anything the user sees.
  final String name;

  /// Set only on the columns the app seeded, and cleared the moment the user
  /// renames one.
  final String? builtInKey;

  /// Left to right on the board.
  final int position;

  /// Whether a task landing here is finished.
  ///
  /// What stamps `completedAt`, what keeps a finished task from reading as
  /// overdue, and what every figure that counts finished work reads. It is a
  /// property of the column rather than of its name: a board whose last
  /// column is called "Entregado" finishes work there, and one with no such
  /// column simply never finishes anything.
  final bool countsAsDone;

  /// Whether the app put this column there and the user has not touched it.
  bool get isBuiltIn => builtInKey != null;

  /// The same column under a new name, owned by the user from now on.
  ///
  /// The key goes with the rename. Keeping it would mean the app translating
  /// over the word the user just typed on the next language switch, which
  /// reads as the app throwing their name away.
  BoardColumn renamedTo(String value) => BoardColumn(
    id: id,
    projectId: projectId,
    name: value,
    position: position,
    countsAsDone: countsAsDone,
  );

  BoardColumn copyWith({String? name, int? position, bool? countsAsDone}) =>
      BoardColumn(
        id: id,
        projectId: projectId,
        name: name ?? this.name,
        builtInKey: builtInKey,
        position: position ?? this.position,
        countsAsDone: countsAsDone ?? this.countsAsDone,
      );

  static String _validateName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'name', 'The name is required');
    }
    if (trimmed.length > maxNameLength) {
      throw ArgumentError.value(
        value,
        'name',
        'The name must be at most $maxNameLength characters',
      );
    }
    return trimmed;
  }
}

/// The board as a whole, and the questions the UI asks about it.
class Board {
  Board(List<BoardColumn> columns)
    : columns = [...columns]..sort((a, b) => a.position.compareTo(b.position));

  final List<BoardColumn> columns;

  bool get isEmpty => columns.isEmpty;

  BoardColumn? byId(String id) {
    for (final column in columns) {
      if (column.id == id) return column;
    }
    return null;
  }

  /// Where a new task goes when nobody said: the leftmost column that does
  /// not already mean "finished".
  BoardColumn? get defaultColumn {
    for (final column in columns) {
      if (!column.countsAsDone) return column;
    }
    return columns.isEmpty ? null : columns.first;
  }

  /// Whether [id] may be dropped.
  ///
  /// The last column cannot go: a board with no columns has nowhere to put a
  /// task, and `todo_tasks.columnId` is not nullable. Whether it still holds
  /// tasks is a separate question the repository answers, because only the
  /// store knows.
  bool canDelete(String id) => columns.length > 1 && byId(id) != null;

  /// The column of this board that means the same as [other].
  ///
  /// Needed because "include subprojects" puts tasks from other projects on
  /// this board, and each of those tasks sits in a column of its own
  /// project's board. A shipped column matches a shipped column by key; the
  /// rest match on the folded name, which is the only thing two boards can
  /// have in common once the user has written their own. Nothing matching
  /// falls to the first column, so a foreign task is always somewhere
  /// visible rather than dropped.
  BoardColumn? equivalentOf(BoardColumn other) {
    if (other.builtInKey case final key?) {
      for (final column in columns) {
        if (column.builtInKey == key) return column;
      }
    }
    final folded = other.name.toLowerCase();
    for (final column in columns) {
      if (column.name.toLowerCase() == folded) return column;
    }
    return columns.isEmpty ? null : columns.first;
  }
}

/// One line of a task's checklist.
class ChecklistItem {
  ChecklistItem({
    required this.id,
    required this.taskId,
    required String content,
    required this.position,
    this.done = false,
  }) : content = _validateContent(content);

  static const maxContentLength = 1000;

  final String id;
  final String taskId;
  final String content;
  final bool done;

  /// Top to bottom. A checklist is a sequence, not a set.
  final int position;

  static String _validateContent(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError.value(value, 'content', 'The line is empty');
    }
    if (trimmed.length > maxContentLength) {
      throw ArgumentError.value(
        value,
        'content',
        'The line must be at most $maxContentLength characters',
      );
    }
    return trimmed;
  }
}

/// A task's checklist, and what it adds up to.
extension ChecklistReading on List<ChecklistItem> {
  int get doneCount => where((item) => item.done).length;

  /// Ticked share, 0 to 1. Zero for an empty checklist, which the bar draws
  /// as empty rather than full.
  double get checkedShare => isEmpty ? 0 : doneCount / length;
}
