import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_todo_repository.dart';
import '../domain/project.dart';
import '../domain/task.dart';
import '../domain/todo_repository.dart';
import '../domain/todo_stats.dart';

/// How the tasks of the selected project are laid out.
enum TodoViewMode { kanban, list }

/// The filters the board is showing through.
class TaskFilters {
  const TaskFilters({this.category = '', this.status, this.due});

  /// Matched as "contains", case-insensitively.
  final String category;
  final TaskStatus? status;
  final DueState? due;

  bool get isEmpty => category.trim().isEmpty && status == null && due == null;

  TaskFilters copyWith({
    String? category,
    Object? status = _unset,
    Object? due = _unset,
  }) => TaskFilters(
    category: category ?? this.category,
    status: status == _unset ? this.status : status as TaskStatus?,
    due: due == _unset ? this.due : due as DueState?,
  );

  static const _unset = Object();
}

final todoRepositoryProvider = Provider<TodoRepository>(
  (ref) => DriftTodoRepository(ref.watch(databaseProvider)),
);

/// Incremented after every write so dependent queries refetch.
final todoRevisionProvider = StateProvider<int>((ref) => 0);

/// The window the progress view looks at.
final todoProgressRangeProvider = StateProvider<ProgressRange>(
  (ref) => ProgressRange.defaultRange,
);

/// The figures behind the progress view, for the chosen window.
final todoStatsProvider = FutureProvider<TodoStats>((ref) {
  ref.watch(todoRevisionProvider);

  final today = ref.watch(todayProvider);

  return ref
      .watch(todoRepositoryProvider)
      .statsFor(
        ref.watch(todoProgressRangeProvider).toDateRange(from: today),
        today: today,
      );
});

final selectedProjectIdProvider = StateProvider<int?>((ref) => null);
final includeDescendantsProvider = StateProvider<bool>((ref) => true);
final todoViewModeProvider = StateProvider<TodoViewMode>(
  (ref) => TodoViewMode.kanban,
);
final taskFiltersProvider = StateProvider<TaskFilters>(
  (ref) => const TaskFilters(),
);

/// The project tree plus the task counts the sidebar shows.
final projectTreeProvider = FutureProvider<({ProjectTree tree, Map<int, TaskCount> counts})>((
  ref,
) async {
  ref.watch(todoRevisionProvider);

  final repository = ref.watch(todoRepositoryProvider);
  final (projects, direct) = await (
    repository.projects(),
    repository.directTaskCounts(),
  ).wait;

  final tree = ProjectTree(projects);
  return (tree: tree, counts: tree.taskCounts(direct));
});

/// The tasks of the selected project, already filtered.
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  ref.watch(todoRevisionProvider);

  final projectId = ref.watch(selectedProjectIdProvider);
  if (projectId == null) return const [];

  final tasks = await ref
      .watch(todoRepositoryProvider)
      .tasks(
        projectId,
        includeDescendants: ref.watch(includeDescendantsProvider),
      );

  final filters = ref.watch(taskFiltersProvider);
  if (filters.isEmpty) return tasks;

  final today = ref.watch(todayProvider);
  final needle = filters.category.trim().toLowerCase();

  return tasks.where((task) {
    if (needle.isNotEmpty &&
        !(task.category ?? '').toLowerCase().contains(needle)) {
      return false;
    }
    if (filters.status != null && task.status != filters.status) return false;
    if (filters.due != null && task.dueState(today) != filters.due) {
      return false;
    }
    return true;
  }).toList();
});

final commentsProvider = FutureProvider.family<List<TaskComment>, int>((
  ref,
  taskId,
) {
  ref.watch(todoRevisionProvider);

  return ref.watch(todoRepositoryProvider).comments(taskId);
});

/// Write operations, kept out of the widgets.
class TodoActions {
  TodoActions(this._ref);

  final Ref _ref;

  TodoRepository get _repository => _ref.read(todoRepositoryProvider);

  Future<void> createProject(String name, {int? parentId}) async {
    final project = await _repository.createProject(name, parentId: parentId);
    _ref.read(selectedProjectIdProvider.notifier).state = project.id;
    _invalidate();
  }

  Future<void> updateProject(
    int id, {
    required String name,
    int? parentId,
  }) async {
    await _repository.updateProject(id, name: name, parentId: parentId);
    _invalidate();
  }

  Future<void> deleteProject(int id) async {
    // The selection may be the project itself or something under it, both of
    // which are about to stop existing.
    final tree = (await _ref.read(projectTreeProvider.future)).tree;
    final gone = {id, ...tree.descendantsOf(id).map((p) => p.id)};

    await _repository.deleteProject(id);
    if (gone.contains(_ref.read(selectedProjectIdProvider))) {
      _ref.read(selectedProjectIdProvider.notifier).state = null;
    }
    _invalidate();
  }

  Future<void> createTask(TaskDraft draft) async {
    await _repository.createTask(draft);
    _invalidate();
  }

  Future<void> updateTask(int id, TaskDraft draft) async {
    await _repository.updateTask(id, draft);
    _invalidate();
  }

  Future<void> deleteTask(int id) async {
    await _repository.deleteTask(id);
    _invalidate();
  }

  Future<void> setStatus(int id, TaskStatus status) async {
    await _repository.setTaskStatus(id, status);
    _invalidate();
  }

  Future<void> addComment(int taskId, String content) async {
    await _repository.addComment(taskId, content);
    _invalidate();
  }

  Future<void> deleteComment(int id) async {
    await _repository.deleteComment(id);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(todoRevisionProvider.notifier).update((value) => value + 1);
}

final todoActionsProvider = Provider<TodoActions>(TodoActions.new);
