import '../../../core/time/date_range.dart';
import 'board_column.dart';
import 'project.dart';
import 'task.dart';
import 'todo_stats.dart';

/// The user-editable fields of a task.
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.projectId,
    this.description,
    this.category,
    this.startDate,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.columnId,
  });

  final String title;
  final String projectId;
  final String? description;
  final String? category;
  final DateTime? startDate;
  final DateTime? dueDate;
  final TaskPriority priority;

  /// Where on the board it goes. Null lets the repository choose — the
  /// leftmost column that does not already mean finished.
  final String? columnId;
}

/// The port the to-do module talks to.
abstract interface class TodoRepository {
  Future<List<Project>> projects();

  /// How many tasks sit directly on each project, keyed by project id.
  Future<Map<String, int>> directTaskCounts();

  Future<Project> createProject(
    String name, {
    String? parentId,
    String? description,
  });

  /// Renames, re-describes and optionally reparents a project.
  ///
  /// Throws when the move would break the tree; ask [ProjectTree.canMove]
  /// first if you want to disable the control instead.
  Future<Project> updateProject(
    String id, {
    required String name,
    String? description,
    String? parentId,
  });

  Future<void> deleteProject(String id);

  /// Tasks of a project, optionally including everything filed under its
  /// subprojects.
  Future<List<Task>> tasks(String projectId, {bool includeDescendants});

  /// Every task in the store, whatever project it belongs to.
  ///
  /// The dashboard summarises across projects, so it cannot go project by
  /// project without knowing them all first.
  Future<List<Task>> allTasks();

  Future<Task> createTask(TaskDraft draft);

  Future<Task> updateTask(String id, TaskDraft draft);

  Future<void> deleteTask(String id);

  /// Moves a task to another column, which is what a drag across the board
  /// and the picker in the editor both do.
  ///
  /// [columnId] may name a column of another project's board: the board on
  /// screen is the selected project's, and "include subprojects" puts other
  /// projects' tasks on it. The task lands in the column of its **own**
  /// board that means the same — see [Board.equivalentOf].
  Future<Task> moveTask(String id, String columnId);

  /// One project's board, left to right.
  Future<List<BoardColumn>> boardColumns(String projectId);

  /// Appends a column to the right of a project's board.
  Future<BoardColumn> createColumn(
    String projectId,
    String name, {
    bool countsAsDone = false,
  });

  /// Renames a column, changes whether it means finished, or both.
  ///
  /// Renaming a column the app seeded makes it the user's: see
  /// [BoardColumn.renamedTo].
  Future<BoardColumn> updateColumn(
    String id, {
    required String name,
    required bool countsAsDone,
  });

  /// Drops a column.
  ///
  /// Throws [StateError] when it still holds tasks, or when it is the last
  /// column left — a task has to sit somewhere.
  Future<void> deleteColumn(String id);

  /// Writes the board's left-to-right order, [ids] being the new one.
  Future<void> reorderColumns(List<String> ids);

  /// How many tasks sit in each column, keyed by column id.
  ///
  /// What the editor needs to say why a column cannot be dropped.
  Future<Map<String, int>> columnTaskCounts();

  /// One task's checklist, top to bottom.
  Future<List<ChecklistItem>> checklist(String taskId);

  /// Appends a line to the bottom of a task's checklist.
  Future<ChecklistItem> addChecklistItem(String taskId, String content);

  /// Ticks a line, unticks it, or rewrites it.
  Future<ChecklistItem> updateChecklistItem(
    String id, {
    String? content,
    bool? done,
  });

  Future<void> deleteChecklistItem(String id);

  Future<List<TaskComment>> comments(String taskId);

  Future<TaskComment> addComment(String taskId, String content);

  Future<void> deleteComment(String id);

  /// The figures the progress view shows for [range].
  ///
  /// [today] decides what counts as overdue, so the caller can keep the app's
  /// idea of today in one place instead of each layer reading the clock.
  Future<TodoStats> statsFor(DateRange range, {DateTime? today});
}
