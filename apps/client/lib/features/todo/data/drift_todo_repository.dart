import 'package:drift/drift.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/record_columns.dart';
import '../../../core/database/uuid.dart';
import '../../../core/l10n/sort_key.dart';
import '../../../core/time/date_range.dart';
import '../domain/board_column.dart';
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
      id: newUuid(),
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

    await _db
        .into(_db.projects)
        .insert(
          ProjectsCompanion.insert(
            id: Value(validated.id),
            name: validated.name,
            description: Value(validated.description),
            parentId: Value(parentId),
          ),
        );
    // Its own board, seeded with the three the app ships. Without it the
    // project has nowhere to put its first task.
    await _db.seedBoardColumnsFor(validated.id);

    return (await _projectById(validated.id))!;
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
  Future<List<String>> owners() async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT "owner" AS owner FROM "todo_tasks" '
          'WHERE "owner" IS NOT NULL AND TRIM("owner") != \'\'',
          readsFrom: {_db.todoTasks},
        )
        .get();

    // Sorted the way Spanish reads, not the way bytes do: Ángela belongs
    // with the A's.
    final names = [for (final row in rows) row.read<String>('owner')]
      ..sort((a, b) => sortKey(a).compareTo(sortKey(b)));

    return names;
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

    final finishing = await _finishingColumns();
    final shown = await _columnsOnTheBoardOf(projectId, rows);

    return [
      for (final row in rows)
        _toTask(
          row,
          finishing: finishing,
          // Only a task pulled in from elsewhere needs to say where it came
          // from; on its own board the label would be noise.
          projectName: row.projectId == projectId ? null : names[row.projectId],
          boardColumnId: shown[row.columnId],
        ),
    ];
  }

  /// Which column of [projectId]'s board each task's column is drawn under.
  ///
  /// A task pulled in from a subproject sits in a column of its own
  /// project's board, and those are different rows: grouped by the id they
  /// carry, such a task belongs to no column on screen and is drawn nowhere
  /// — which is exactly what "include subprojects" used to do. Mapped to
  /// the column that means the same, it lands where a reader expects it.
  ///
  /// Keyed by the foreign column rather than by the task, because a board
  /// is three or four rows and the answer is the same for every task in one
  /// of them.
  Future<Map<String, String>> _columnsOnTheBoardOf(
    String projectId,
    List<TodoTaskRow> rows,
  ) async {
    final foreign = {
      for (final row in rows)
        if (row.projectId != projectId) row.columnId,
    };
    if (foreign.isEmpty) return const {};

    final board = Board(await boardColumns(projectId));
    final columns = await (_db.select(
      _db.boardColumns,
    )..where((c) => c.id.isIn(foreign))).get();

    final shown = <String, String>{};
    for (final column in columns) {
      final here = board.equivalentOf(_toColumn(column));
      // Null only when this project has no board at all, and then there is
      // nowhere to draw the task either way.
      if (here != null) shown[column.id] = here.id;
    }

    return shown;
  }

  @override
  Future<List<Task>> allTasks() async {
    final names = {
      for (final project in await projects()) project.id: project.name,
    };
    final rows = await (_db.select(
      _db.todoTasks,
    )..orderBy([(t) => OrderingTerm.asc(t.rowId)])).get();

    final finishing = await _finishingColumns();

    return [
      for (final row in rows)
        _toTask(row, finishing: finishing, projectName: names[row.projectId]),
    ];
  }

  @override
  Future<Task> createTask(TaskDraft draft) async {
    final column = await _columnFor(draft);
    final validated = _fromDraft(
      draft,
      id: newUuid(),
      columnId: column.id,
      countsAsDone: column.countsAsDone,
    );

    await _db
        .into(_db.todoTasks)
        .insert(
          TodoTasksCompanion.insert(
            id: Value(validated.id),
            title: validated.title,
            description: Value(validated.description),
            category: Value(validated.category),
            startDate: Value(validated.startDate),
            dueDate: Value(validated.dueDate),
            priority: validated.priority.wireName,
            columnId: validated.columnId,
            projectId: validated.projectId,
            owner: Value(validated.owner),
            completedAt: Value(column.countsAsDone ? DateTime.now() : null),
          ),
        );

    return (await _taskById(validated.id))!;
  }

  @override
  Future<Task> updateTask(String id, TaskDraft draft) async {
    final column = await _columnFor(draft);
    final validated = _fromDraft(
      draft,
      id: id,
      columnId: column.id,
      countsAsDone: column.countsAsDone,
    );
    // Editing a task that was already done keeps the original moment; only
    // moving it out of a finishing column clears it.
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
        columnId: Value(validated.columnId),
        projectId: Value(validated.projectId),
        owner: Value(validated.owner),
        completedAt: Value(
          column.countsAsDone
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
  Future<Task> moveTask(String id, String columnId) async {
    final target = await (_db.select(
      _db.boardColumns,
    )..where((c) => c.id.equals(columnId))).getSingleOrNull();
    if (target == null) {
      throw ArgumentError.value(columnId, 'columnId', 'No such board column');
    }

    final existing = await (_db.select(
      _db.todoTasks,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing == null) throw StateError('Task $id was not found');

    // The board on screen belongs to the selected project, and with
    // subprojects included it carries tasks that answer to another board. A
    // task always lands on its own.
    final own = Board(await boardColumns(existing.projectId));
    final column = own.byId(columnId) ?? own.equivalentOf(_toColumn(target));
    if (column == null) {
      throw StateError('Project ${existing.projectId} has no board to move to');
    }

    await (_db.update(
      _db.todoTasks,
    )..where((t) => t.id.equals(id))).writeTouched(
      TodoTasksCompanion(
        columnId: Value(column.id),
        // Stamped on the way into a finishing column and cleared on the way
        // out, so reopening a task takes it back off the chart it was
        // counted on. A move between two finishing columns keeps the moment
        // it was first finished: it was not finished twice.
        completedAt: Value(
          column.countsAsDone ? (existing.completedAt ?? DateTime.now()) : null,
        ),
      ),
    );

    return (await _taskById(id))!;
  }

  @override
  Future<List<BoardColumn>> boardColumns(String projectId) async {
    final rows =
        await (_db.select(_db.boardColumns)
              ..where((c) => c.projectId.equals(projectId))
              ..orderBy([(c) => OrderingTerm.asc(c.position)]))
            .get();

    return [for (final row in rows) _toColumn(row)];
  }

  @override
  Future<BoardColumn> createColumn(
    String projectId,
    String name, {
    bool countsAsDone = false,
  }) async {
    final existing = await boardColumns(projectId);
    // Appended rather than inserted: a new column goes where the user can
    // see it, and renumbering the board to squeeze one in would move columns
    // nobody asked to move.
    final validated = BoardColumn(
      id: newUuid(),
      projectId: projectId,
      name: name,
      position: existing.isEmpty ? 0 : existing.last.position + 1,
      countsAsDone: countsAsDone,
    );

    await _db
        .into(_db.boardColumns)
        .insert(
          BoardColumnsCompanion.insert(
            id: Value(validated.id),
            projectId: validated.projectId,
            name: validated.name,
            position: validated.position,
            countsAsDone: Value(validated.countsAsDone),
          ),
        );

    return validated;
  }

  @override
  Future<BoardColumn> updateColumn(
    String id, {
    required String name,
    required bool countsAsDone,
  }) async {
    final row = await (_db.select(
      _db.boardColumns,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (row == null) {
      throw StateError('Board column $id was not found');
    }
    final existing = _toColumn(row);

    // A rename hands the column to the user, key and all. Keeping the name
    // it already had leaves it built in: switching the app's language must
    // still translate a column nobody has touched.
    final validated = existing.name == name.trim()
        ? existing.copyWith(countsAsDone: countsAsDone)
        : existing.renamedTo(name).copyWith(countsAsDone: countsAsDone);

    await (_db.update(
      _db.boardColumns,
    )..where((c) => c.id.equals(id))).writeTouched(
      BoardColumnsCompanion(
        name: Value(validated.name),
        builtInKey: Value(validated.builtInKey),
        countsAsDone: Value(validated.countsAsDone),
      ),
    );

    // Leaving a finishing column stamps every task now sitting in it, and
    // leaving one clears them: `completedAt` is what the charts read, and a
    // column that changed meaning would otherwise leave the tasks inside it
    // counted the old way forever.
    await (_db.update(
      _db.todoTasks,
    )..where((t) => t.columnId.equals(id))).writeTouched(
      TodoTasksCompanion(
        completedAt: Value(validated.countsAsDone ? DateTime.now() : null),
      ),
    );

    return validated;
  }

  @override
  Future<void> deleteColumn(String id) async {
    final row = await (_db.select(
      _db.boardColumns,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (row == null) return;

    final board = Board(await boardColumns(row.projectId));
    if (!board.canDelete(id)) {
      throw StateError('The last column cannot be deleted');
    }

    final counts = await columnTaskCounts();
    if ((counts[id] ?? 0) > 0) {
      // The foreign key would refuse this anyway; saying it here is what
      // lets the UI explain it instead of showing a constraint error.
      throw StateError('The column still holds tasks');
    }

    await (_db.delete(_db.boardColumns)..where((c) => c.id.equals(id))).go();
  }

  @override
  Future<void> reorderColumns(List<String> ids) => _db.transaction(() async {
    // Written by position rather than by swapping rows: the caller hands over
    // the whole order it wants, so the board cannot end up half-rearranged.
    for (final (index, id) in ids.indexed) {
      await (_db.update(_db.boardColumns)..where((c) => c.id.equals(id)))
          .writeTouched(BoardColumnsCompanion(position: Value(index)));
    }
  });

  @override
  Future<Map<String, int>> columnTaskCounts() async {
    final counter = _db.todoTasks.id.count();
    final query = _db.selectOnly(_db.todoTasks)
      ..addColumns([_db.todoTasks.columnId, counter])
      ..groupBy([_db.todoTasks.columnId]);

    return {
      for (final row in await query.get())
        row.read(_db.todoTasks.columnId)!: row.read(counter) ?? 0,
    };
  }

  @override
  Future<List<ChecklistItem>> checklist(String taskId) async {
    final rows =
        await (_db.select(_db.taskChecklistItems)
              ..where((i) => i.taskId.equals(taskId))
              ..orderBy([(i) => OrderingTerm.asc(i.position)]))
            .get();

    return [for (final row in rows) _toChecklistItem(row)];
  }

  @override
  Future<ChecklistItem> addChecklistItem(String taskId, String content) async {
    final existing = await checklist(taskId);
    final validated = ChecklistItem(
      id: newUuid(),
      taskId: taskId,
      content: content,
      position: existing.isEmpty ? 0 : existing.last.position + 1,
    );

    await _db
        .into(_db.taskChecklistItems)
        .insert(
          TaskChecklistItemsCompanion.insert(
            id: Value(validated.id),
            taskId: validated.taskId,
            content: validated.content,
            position: validated.position,
          ),
        );

    return validated;
  }

  @override
  Future<ChecklistItem> updateChecklistItem(
    String id, {
    String? content,
    bool? done,
  }) async {
    final row = await (_db.select(
      _db.taskChecklistItems,
    )..where((i) => i.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('Checklist item $id was not found');

    // Built first so a blank line is refused before anything is written.
    final validated = ChecklistItem(
      id: row.id,
      taskId: row.taskId,
      content: content ?? row.content,
      done: done ?? row.done,
      position: row.position,
    );

    await (_db.update(
      _db.taskChecklistItems,
    )..where((i) => i.id.equals(id))).writeTouched(
      TaskChecklistItemsCompanion(
        content: Value(validated.content),
        done: Value(validated.done),
      ),
    );

    return validated;
  }

  @override
  Future<void> deleteChecklistItem(String id) async {
    await (_db.delete(
      _db.taskChecklistItems,
    )..where((i) => i.id.equals(id))).go();
  }

  ChecklistItem _toChecklistItem(TaskChecklistItemRow row) => ChecklistItem(
    id: row.id,
    taskId: row.taskId,
    content: row.content,
    done: row.done,
    position: row.position,
  );

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
    final id = newUuid();
    await _db
        .into(_db.taskComments)
        .insert(
          TaskCommentsCompanion.insert(
            id: Value(id),
            taskId: taskId,
            content: text,
            createdAt: now,
          ),
        );

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

    return row == null
        ? null
        : _toTask(row, finishing: await _finishingColumns());
  }

  Task _fromDraft(
    TaskDraft draft, {
    required String id,
    required String columnId,
    required bool countsAsDone,
  }) => Task(
    id: id,
    title: draft.title,
    description: draft.description,
    category: draft.category,
    startDate: draft.startDate,
    dueDate: draft.dueDate,
    priority: draft.priority,
    columnId: columnId,
    countsAsDone: countsAsDone,
    projectId: draft.projectId,
    owner: draft.owner,
  );

  /// Where a draft goes: the column it named, or the board's default.
  ///
  /// A draft naming a column that is not there is refused rather than moved
  /// somewhere plausible — it means the caller is working from a board that
  /// has changed underneath it, and guessing would file the task somewhere
  /// nobody chose.
  Future<BoardColumn> _columnFor(TaskDraft draft) async {
    final board = Board(await boardColumns(draft.projectId));
    if (draft.columnId case final id?) {
      final column = board.byId(id);
      if (column == null) {
        throw ArgumentError.value(id, 'columnId', 'No such board column');
      }
      return column;
    }

    final fallback = board.defaultColumn;
    if (fallback == null) {
      throw StateError('The board has no columns to put a task in');
    }
    return fallback;
  }

  Project _toProject(ProjectRow row) => Project(
    id: row.id,
    name: row.name,
    description: row.description,
    parentId: row.parentId,
  );

  Task _toTask(
    TodoTaskRow row, {
    required Set<String> finishing,
    String? projectName,
    String? boardColumnId,
  }) => Task(
    id: row.id,
    title: row.title,
    description: row.description,
    category: row.category,
    startDate: row.startDate,
    dueDate: row.dueDate,
    priority: TaskPriority.parse(row.priority),
    columnId: row.columnId,
    boardColumnId: boardColumnId,
    countsAsDone: finishing.contains(row.columnId),
    projectId: row.projectId,
    completedAt: row.completedAt,
    projectName: projectName,
    owner: row.owner,
  );

  /// The ids of the columns that mean the work is finished.
  ///
  /// Read once per query rather than joined onto every row: the board is
  /// three or four rows, and a join would put the column's name and order on
  /// a task that has no use for either.
  Future<Set<String>> _finishingColumns() async {
    final rows = await (_db.select(
      _db.boardColumns,
    )..where((c) => c.countsAsDone.equals(true))).get();

    return {for (final row in rows) row.id};
  }

  BoardColumn _toColumn(BoardColumnRow row) => BoardColumn(
    id: row.id,
    projectId: row.projectId,
    name: row.name,
    builtInKey: row.builtInKey,
    position: row.position,
    countsAsDone: row.countsAsDone,
  );
}
