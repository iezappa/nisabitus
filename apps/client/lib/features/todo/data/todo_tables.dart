import 'package:drift/drift.dart';

/// A node of the project tree, limited to three levels deep.
@DataClassName('ProjectRow')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().withLength(max: 5000).nullable()();

  /// The parent project, or null for a root project.
  IntColumn get parentId => integer()
      .nullable()
      .references(Projects, #id, onDelete: KeyAction.cascade)();
}

/// A unit of work belonging to a project.
@TableIndex(name: 'task_project_lookup', columns: {#projectId, #status})
@DataClassName('TodoTaskRow')
class TodoTasks extends Table {
  @override
  String get tableName => 'todo_tasks';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().withLength(max: 5000).nullable()();
  TextColumn get category => text().withLength(max: 255).nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Stored as the canonical wire name of TaskPriority.
  TextColumn get priority => text().withLength(max: 16)();

  /// Stored as the canonical wire name of TaskStatus.
  TextColumn get status => text().withLength(max: 16)();

  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
}

/// A progress note attached to a task.
@TableIndex(name: 'task_comment_lookup', columns: {#taskId, #createdAt})
@DataClassName('TaskCommentRow')
class TaskComments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(TodoTasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text().withLength(max: 5000)();
  DateTimeColumn get createdAt => dateTime()();
}
