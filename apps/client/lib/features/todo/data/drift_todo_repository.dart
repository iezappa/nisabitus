import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../domain/project.dart';
import '../domain/task.dart';
import '../domain/todo_repository.dart';

/// Drift-backed implementation of [TodoRepository].
class DriftTodoRepository implements TodoRepository {
  DriftTodoRepository(this._db);

  final AppDatabase _db;

  @override
  Future<List<Project>> projects() async {
    final rows = await (_db.select(
      _db.projects,
    )..orderBy([(p) => OrderingTerm.asc(p.id)])).get();

    return rows.map(_toProject).toList();
  }

  @override
  Future<Map<int, int>> directTaskCounts() async {
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
    int? parentId,
    String? description,
  }) async {
    // Validating through the entity keeps the rule in one place.
    final validated = Project(
      id: 0,
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

    final id = await _db
        .into(_db.projects)
        .insert(
          ProjectsCompanion.insert(
            name: validated.name,
            description: Value(validated.description),
            parentId: Value(parentId),
          ),
        );

    return (await _projectById(id))!;
  }

  @override
  Future<Project> updateProject(
    int id, {
    required String name,
    String? description,
    int? parentId,
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

    await (_db.update(_db.projects)..where((p) => p.id.equals(id))).write(
      ProjectsCompanion(
        name: Value(validated.name),
        description: Value(validated.description),
        parentId: Value(parentId),
      ),
    );

    return (await _projectById(id))!;
  }

  @override
  Future<void> deleteProject(int id) async {
    // The cascade in the schema takes the subprojects and their tasks.
    await (_db.delete(_db.projects)..where((p) => p.id.equals(id))).go();
  }

  @override
  Future<List<Task>> tasks(
    int projectId, {
    bool includeDescendants = false,
  }) async {
    final all = await projects();
    final tree = ProjectTree(all);
    final names = {for (final project in all) project.id: project.name};

    final ids = <int>{
      projectId,
      if (includeDescendants)
        ...tree.descendantsOf(projectId).map((project) => project.id),
    };

    final rows =
        await (_db.select(_db.todoTasks)
              ..where((t) => t.projectId.isIn(ids))
              ..orderBy([(t) => OrderingTerm.asc(t.id)]))
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
  Future<Task> createTask(TaskDraft draft) async {
    final validated = _fromDraft(draft, id: 0);

    final id = await _db
        .into(_db.todoTasks)
        .insert(
          TodoTasksCompanion.insert(
            title: validated.title,
            description: Value(validated.description),
            category: Value(validated.category),
            startDate: Value(validated.startDate),
            dueDate: Value(validated.dueDate),
            priority: validated.priority.wireName,
            status: validated.status.wireName,
            projectId: validated.projectId,
          ),
        );

    return (await _taskById(id))!;
  }

  @override
  Future<Task> updateTask(int id, TaskDraft draft) async {
    final validated = _fromDraft(draft, id: id);

    await (_db.update(_db.todoTasks)..where((t) => t.id.equals(id))).write(
      TodoTasksCompanion(
        title: Value(validated.title),
        description: Value(validated.description),
        category: Value(validated.category),
        startDate: Value(validated.startDate),
        dueDate: Value(validated.dueDate),
        priority: Value(validated.priority.wireName),
        status: Value(validated.status.wireName),
        projectId: Value(validated.projectId),
      ),
    );

    return (await _taskById(id))!;
  }

  @override
  Future<void> deleteTask(int id) async {
    await (_db.delete(_db.todoTasks)..where((t) => t.id.equals(id))).go();
  }

  @override
  Future<Task> setTaskStatus(int id, TaskStatus status) async {
    await (_db.update(_db.todoTasks)..where((t) => t.id.equals(id))).write(
      TodoTasksCompanion(status: Value(status.wireName)),
    );

    return (await _taskById(id))!;
  }

  @override
  Future<List<TaskComment>> comments(int taskId) async {
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
  Future<TaskComment> addComment(int taskId, String content) async {
    final text = content.trim();
    if (text.isEmpty) {
      throw ArgumentError.value(content, 'content', 'The comment is empty');
    }

    final now = DateTime.now();
    final id = await _db
        .into(_db.taskComments)
        .insert(
          TaskCommentsCompanion.insert(
            taskId: taskId,
            content: text,
            createdAt: now,
          ),
        );

    return TaskComment(
      id: id,
      taskId: taskId,
      content: text,
      createdAt: now,
    );
  }

  @override
  Future<void> deleteComment(int id) async {
    await (_db.delete(_db.taskComments)..where((c) => c.id.equals(id))).go();
  }

  Future<Project?> _projectById(int id) async {
    final row = await (_db.select(
      _db.projects,
    )..where((p) => p.id.equals(id))).getSingleOrNull();

    return row == null ? null : _toProject(row);
  }

  Future<Task?> _taskById(int id) async {
    final row = await (_db.select(
      _db.todoTasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    return row == null ? null : _toTask(row);
  }

  Task _fromDraft(TaskDraft draft, {required int id}) => Task(
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
    projectName: projectName,
  );
}
