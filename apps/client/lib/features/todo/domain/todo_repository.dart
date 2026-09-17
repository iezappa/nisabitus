import '../../../core/time/date_range.dart';
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
    this.status = TaskStatus.todo,
  });

  final String title;
  final String projectId;
  final String? description;
  final String? category;
  final DateTime? startDate;
  final DateTime? dueDate;
  final TaskPriority priority;
  final TaskStatus status;
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

  Future<Task> setTaskStatus(String id, TaskStatus status);

  Future<List<TaskComment>> comments(String taskId);

  Future<TaskComment> addComment(String taskId, String content);

  Future<void> deleteComment(String id);

  /// The figures the progress view shows for [range].
  ///
  /// [today] decides what counts as overdue, so the caller can keep the app's
  /// idea of today in one place instead of each layer reading the clock.
  Future<TodoStats> statsFor(DateRange range, {DateTime? today});
}
