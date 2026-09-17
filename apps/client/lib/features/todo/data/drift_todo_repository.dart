import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/record_columns.dart';
import '../../../core/time/date_range.dart';
import '../domain/project.dart';
import '../domain/task.dart';
import '../domain/todo_repository.dart';
import '../domain/todo_stats.dart';

/// Drift-backed implementation of [TodoRepository].
class DriftTodoRepository implements TodoRepository {
  DriftTodoRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Project>> projects() async {
    final rows = await (_db.select(
      _db.projects,
    )..orderBy([(p) => OrderingTerm.asc(p.rowId)])).get();

    return rows.map(_toProject).toList();
  }

  @override
  Future<Map<String, int>> directTaskCounts() async {
    final counter = _db.todoTasks.id.count();
    final query = _db.selectOnly(_db.todoTasks)
      ..addColumns([_db.todoTasks.projectId, counter])
      ..groupBy([_db.todoTasks.projectId]);

    return {
      for (final row in await query.get())
        row.read(_db.todoTasks.projectId)!: row.read(counter) ?? 0,
    };
  }

  @override
  Future<Project> createProject(
    String name, {
    String? parentId,
    String? description,
  }) async {
    // Validating through the entity keeps the rule in one place.
    final validated = Project(
      id: '',
      name: name,
      parentId: parentId,
      description: description,
    );

    if (parentId != null) {
      final tree = ProjectTree(await projects());
      if (!tree.canAddChild(parentId)) {
        throw ArgumentError.value(
          parentId,
          'parentId',
          'A project cannot be more than ${ProjectTree.maxDepth} levels deep',
        );
      }
    }

    final id =
        (await _db
                .into(_db.projects)
                .insertReturning(
                  ProjectsCompanion.insert(
                    name: validated.name,
                    description: Value(validated.description),
                    parentId: Value(parentId),
                  ),
                ))
            .id;

    return (await _projectById(id))!;
  }

  @override
  Future<Project> updateProject(
    String id, {
    required String name,
    String? description,
    String? parentId,
  }) async {
    final validated = Project(
      id: id,
      name: name,
      parentId: parentId,
      description: description,
    );

    final existing = await _projectById(id);
    if (existing == null) throw StateError('Project $id was not found');

    // Only a real move needs checking; renaming in place always holds.
    if (parentId != existing.parentId) {
      final tree = ProjectTree(await projects());
      if (!tree.canMove(id, under: parentId)) {
        throw ArgumentError.value(
          parentId,
          'parentId',
          'That move would break the project tree',
        );
      }
    }

    await (_db.update(
      _db.projects,
    )..where((p) => p.id.equals(id))).writeTouched(
      ProjectsCompanion(
        name: Value(validated.name),
        description: Value(validated.description),
        parentId: Value(parentId),
      ),
    );

    return (await _projectById(id))!;
  }

  @override
  Future<void> deleteProject(String id) async {
    // The cascade in the schema takes the subprojects and their tasks.
    await (_db.delete(_db.projects)..where((p) => p.id.equals(id))).go();
  }

  @override
  Future<List<Task>> tasks(
    String projectId, {
    bool includeDescendants = false,
  }) async {
    final all = await projects();
    final tree = ProjectTree(all);
    final names = {for (final project in all) project.id: project.name};

    final ids = <String>{
      projectId,
      if (includeDescendants)
        ...tree.descendantsOf(projectId).map((project) => project.id),
    };

    final rows =
        await (_db.select(_db.todoTasks)
              ..where((t) => t.projectId.isIn(ids))
              ..orderBy([(t) => OrderingTerm.asc(t.rowId)]))
            .get();

    return [
      for (final row in rows)
        _toTask(
          row,
          // Only a task pulled in from elsewhere needs to say where it came
          // from; on its own board the label would be noise.
          projectName: row.projectId == projectId ? null : names[row.projectId],
        ),
    ];
  }

  @override
  Future<List<Task>> allTasks() async {
    final names = {
      for (final project in await projects()) project.id: project.name,
    };
    final rows = await (_db.select(
      _db.todoTasks,
    )..orderBy([(t) => OrderingTerm.asc(t.rowId)])).get();

    return [
      for (final row in rows) _toTask(row, projectName: names[row.projectId]),
    ];
  }

  @override
  Future<Task> createTask(TaskDraft draft) async {
    final validated = _fromDraft(draft, id: '');

    final id =
        (await _db
                .into(_db.todoTasks)
                .insertReturning(
                  TodoTasksCompanion.insert(
                    title: validated.title,
                    description: Value(validated.description),
                    category: Value(validated.category),
                    startDate: Value(validated.startDate),
                    dueDate: Value(validated.dueDate),
                    priority: validated.priority.wireName,
                    status: validated.status.wireName,
                    projectId: validated.projectId,
                    completedAt: Value(
                      validated.status == TaskStatus.done
                          ? DateTime.now()
                          : null,
                    ),
                  ),
                ))
            .id;

    return (await _taskById(id))!;
  }

  @override
  Future<Task> updateTask(String id, TaskDraft draft) async {
    final validated = _fromDraft(draft, id: id);
    // Editing a task that was already done keeps the original moment; only
    // a change of status moves it.
    final existing = await (_db.select(
      _db.todoTasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    await (_db.update(
      _db.todoTasks,
    )..where((t) => t.id.equals(id))).writeTouched(
      TodoTasksCompanion(
        title: Value(validated.title),
        description: Value(validated.description),
        category: Value(validated.category),
        startDate: Value(validated.startDate),
        dueDate: Value(validated.dueDate),
        priority: Value(validated.priority.wireName),
        status: Value(validated.status.wireName),
        projectId: Value(validated.projectId),
        completedAt: Value(
          validated.status == TaskStatus.done
              ? (existing?.completedAt ?? DateTime.now())
              : null,
        ),
      ),
    );

    return (await _taskById(id))!;
  }

  @override
  Future<void> deleteTask(String id) async {
    await (_db.delete(_db.todoTasks)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<Task> setTaskStatus(String id, TaskStatus status) async {
    await (_db.update(
      _db.todoTasks,
    )..where((t) => t.id.equals(id))).writeTouched(
      TodoTasksCompanion(
        status: Value(status.wireName),
        // Stamped on the way into DONE and cleared on the way out, so
        // reopening a task takes it back off the chart it was counted on.
        completedAt: Value(status == TaskStatus.done ? DateTime.now() : null),
      ),
    );

    return (await _taskById(id))!;
  }

  @override
  Future<List<TaskComment>> comments(String taskId) async {
    final rows =
        await (_db.select(_db.taskComments)
              ..where((c) => c.taskId.equals(taskId))
              ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
            .get();

    return [
      for (final row in rows)
        TaskComment(
          id: row.id,
          taskId: row.taskId,
          content: row.content,
          createdAt: row.createdAt,
        ),
    ];
  }

  @override
  Future<TaskComment> addComment(String taskId, String content) async {
    final text = content.trim();
    if (text.isEmpty) {
      throw ArgumentError.value(content, 'content', 'The comment is empty');
    }

    final now = DateTime.now();
    final id =
        (await _db
                .into(_db.taskComments)
                .insertReturning(
                  TaskCommentsCompanion.insert(
                    taskId: taskId,
                    content: text,
                    createdAt: now,
                  ),
                ))
            .id;

    return TaskComment(id: id, taskId: taskId, content: text, createdAt: now);
  }

  @override
  Future<void> deleteComment(String id) async {
    await (_db.delete(_db.taskComments)..where((c) => c.id.equals(id))).go();
  }

  Future<Project?> _projectById(String id) async {
    final row = await (_db.select(
      _db.projects,
    )..where((p) => p.id.equals(id))).getSingleOrNull();

    return row == null ? null : _toProject(row);
  }

  @override
  Future<TodoStats> statsFor(DateRange range, {DateTime? today}) async =>
      TodoStats.from(range, await allTasks(), today ?? DateTime.now());

  Future<Task?> _taskById(String id) async {
    final row = await (_db.select(
      _db.todoTasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    return row == null ? null : _toTask(row);
  }

  Task _fromDraft(TaskDraft draft, {required String id}) => Task(
    id: id,
    title: draft.title,
    description: draft.description,
    category: draft.category,
    startDate: draft.startDate,
    dueDate: draft.dueDate,
    priority: draft.priority,
    status: draft.status,
    projectId: draft.projectId,
  );

  Project _toProject(ProjectRow row) => Project(
    id: row.id,
    name: row.name,
    description: row.description,
    parentId: row.parentId,
  );

  Task _toTask(TodoTaskRow row, {String? projectName}) => Task(
    id: row.id,
    title: row.title,
    description: row.description,
    category: row.category,
    startDate: row.startDate,
    dueDate: row.dueDate,
    priority: TaskPriority.parse(row.priority),
    status: TaskStatus.parse(row.status),
    projectId: row.projectId,
    completedAt: row.completedAt,
    projectName: projectName,
  );
}
