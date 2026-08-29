import 'project.dart';
import 'task.dart';

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
  final int projectId;
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
  Future<Map<int, int>> directTaskCounts();

  Future<Project> createProject(String name, {int? parentId, String? description});

  /// Renames, re-describes and optionally reparents a project.
  ///
  /// Throws when the move would break the tree; ask [ProjectTree.canMove]
  /// first if you want to disable the control instead.
  Future<Project> updateProject(
    int id, {
    required String name,
    String? description,
    int? parentId,
  });

  Future<void> deleteProject(int id);

  /// Tasks of a project, optionally including everything filed under its
  /// subprojects.
  Future<List<Task>> tasks(int projectId, {bool includeDescendants});

  Future<Task> createTask(TaskDraft draft);

  Future<Task> updateTask(int id, TaskDraft draft);

  Future<void> deleteTask(int id);

  Future<Task> setTaskStatus(int id, TaskStatus status);

  Future<List<TaskComment>> comments(int taskId);

  Future<TaskComment> addComment(int taskId, String content);

  Future<void> deleteComment(int id);
}
