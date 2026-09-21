import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/time/progress_range.dart';
import '../../../core/time/selected_day_provider.dart';
import '../data/drift_todo_repository.dart';
import '../domain/board_column.dart';
import '../domain/project.dart';
import '../domain/task.dart';
import '../domain/todo_repository.dart';
import '../domain/todo_stats.dart';

/// How the tasks of the selected project are laid out.
enum TodoViewMode { kanban, list }

/// The filters the board is showing through.
class TaskFilters {
  const TaskFilters({this.category = '', this.columnId, this.due});

  /// Matched as "contains", case-insensitively.
  final String category;

  /// The id of a board column, or null for every column.
  final String? columnId;
  final DueState? due;

  bool get isEmpty =>
      category.trim().isEmpty && columnId == null && due == null;

  TaskFilters copyWith({
    String? category,
    Object? columnId = _unset,
    Object? due = _unset,
  }) => TaskFilters(
    category: category ?? this.category,
    columnId: columnId == _unset ? this.columnId : columnId as String?,
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

final selectedProjectIdProvider = StateProvider<String?>((ref) => null);
final includeDescendantsProvider = StateProvider<bool>((ref) => true);
final todoViewModeProvider = StateProvider<TodoViewMode>(
  (ref) => TodoViewMode.kanban,
);
final taskFiltersProvider = StateProvider<TaskFilters>(
  (ref) => const TaskFilters(),
);

/// The selected project's board, left to right.
///
/// Empty while no project is selected: a board belongs to a project as of
/// v16, so there is no board to show until one is picked.
final boardProvider = FutureProvider<Board>((ref) async {
  ref.watch(todoRevisionProvider);

  final projectId = ref.watch(selectedProjectIdProvider);
  if (projectId == null) return Board(const []);

  return Board(await ref.watch(todoRepositoryProvider).boardColumns(projectId));
});

/// One task's checklist, top to bottom.
final checklistProvider = FutureProvider.family<List<ChecklistItem>, String>((
  ref,
  taskId,
) {
  ref.watch(todoRevisionProvider);

  return ref.watch(todoRepositoryProvider).checklist(taskId);
});

/// How many tasks sit in each column, for the column editor.
final columnTaskCountsProvider = FutureProvider<Map<String, int>>((ref) {
  ref.watch(todoRevisionProvider);

  return ref.watch(todoRepositoryProvider).columnTaskCounts();
});

/// The project tree plus the task counts the sidebar shows.
final projectTreeProvider =
    FutureProvider<
      ({
        ProjectTree tree,
        Map<String, TaskCount> counts,
        Map<String, ProjectTally> tallies,
      })
    >((ref) async {
      ref.watch(todoRevisionProvider);

      final today = ref.watch(todayProvider);
      final repository = ref.watch(todoRepositoryProvider);
      final (projects, direct, tasks) = await (
        repository.projects(),
        repository.directTaskCounts(),
        // Read whole rather than counted in SQL: the dot needs finished,
        // overdue and due-today per project, and `dueState` is a domain rule
        // about today rather than a column the database could group by.
        repository.allTasks(),
      ).wait;

      final perProject = <String, ProjectTally>{};
      for (final task in tasks) {
        final running =
            perProject[task.projectId] ??
            (total: 0, done: 0, overdue: 0, dueToday: 0);
        final due = task.dueState(today);
        perProject[task.projectId] = (
          total: running.total + 1,
          done: running.done + (task.countsAsDone ? 1 : 0),
          overdue: running.overdue + (due == DueState.overdue ? 1 : 0),
          dueToday: running.dueToday + (due == DueState.today ? 1 : 0),
        );
      }

      final tree = ProjectTree(projects);
      return (
        tree: tree,
        counts: tree.taskCounts(direct),
        tallies: tree.tallies(perProject),
      );
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
    if (filters.columnId != null && task.columnId != filters.columnId) {
      return false;
    }
    if (filters.due != null && task.dueState(today) != filters.due) {
      return false;
    }
    return true;
  }).toList();
});

final commentsProvider = FutureProvider.family<List<TaskComment>, String>((
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

  Future<void> createProject(String name, {String? parentId}) async {
    final project = await _repository.createProject(name, parentId: parentId);
    _ref.read(selectedProjectIdProvider.notifier).state = project.id;
    _invalidate();
  }

  Future<void> updateProject(
    String id, {
    required String name,
    String? parentId,
  }) async {
    await _repository.updateProject(id, name: name, parentId: parentId);
    _invalidate();
  }

  Future<void> deleteProject(String id) async {
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

  Future<void> updateTask(String id, TaskDraft draft) async {
    await _repository.updateTask(id, draft);
    _invalidate();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    _invalidate();
  }

  Future<void> moveTask(String id, String columnId) async {
    await _repository.moveTask(id, columnId);
    _invalidate();
  }

  Future<void> createColumn(
    String projectId,
    String name, {
    bool countsAsDone = false,
  }) async {
    await _repository.createColumn(projectId, name, countsAsDone: countsAsDone);
    _invalidate();
  }

  Future<void> addChecklistItem(String taskId, String content) async {
    await _repository.addChecklistItem(taskId, content);
    _invalidate();
  }

  Future<void> updateChecklistItem(
    String id, {
    String? content,
    bool? done,
  }) async {
    await _repository.updateChecklistItem(id, content: content, done: done);
    _invalidate();
  }

  Future<void> deleteChecklistItem(String id) async {
    await _repository.deleteChecklistItem(id);
    _invalidate();
  }

  Future<void> updateColumn(
    String id, {
    required String name,
    required bool countsAsDone,
  }) async {
    await _repository.updateColumn(id, name: name, countsAsDone: countsAsDone);
    _invalidate();
  }

  /// Drops a column, and clears a filter that was pointing at it.
  ///
  /// Throws [StateError] when the column still holds tasks or is the last
  /// one; the caller shows the reason.
  Future<void> deleteColumn(String id) async {
    await _repository.deleteColumn(id);
    if (_ref.read(taskFiltersProvider).columnId == id) {
      _ref
          .read(taskFiltersProvider.notifier)
          .update((filters) => filters.copyWith(columnId: null));
    }
    _invalidate();
  }

  Future<void> reorderColumns(List<String> ids) async {
    await _repository.reorderColumns(ids);
    _invalidate();
  }

  Future<void> addComment(String taskId, String content) async {
    await _repository.addComment(taskId, content);
    _invalidate();
  }

  Future<void> deleteComment(String id) async {
    await _repository.deleteComment(id);
    _invalidate();
  }

  void _invalidate() =>
      _ref.read(todoRevisionProvider.notifier).update((value) => value + 1);
}

final todoActionsProvider = Provider<TodoActions>(TodoActions.new);
