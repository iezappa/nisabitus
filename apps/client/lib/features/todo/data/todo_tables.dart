import 'package:drift/drift.dart';

import '../../../core/database/record_columns.dart';

/// A node of the project tree, limited to three levels deep.
@DataClassName('ProjectRow')
class Projects extends Table with RecordColumns {
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().withLength(max: 5000).nullable()();

  /// The parent project, or null for a root project.
  TextColumn get parentId => text().nullable().references(
    Projects,
    #id,
    onDelete: KeyAction.cascade,
  )();
}

/// A unit of work belonging to a project.
@TableIndex(name: 'task_project_lookup', columns: {#projectId, #status})
@DataClassName('TodoTaskRow')
class TodoTasks extends Table with RecordColumns {
  @override
  String get tableName => 'todo_tasks';

  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().withLength(max: 5000).nullable()();
  TextColumn get category => text().withLength(max: 255).nullable()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// Stored as the canonical wire name of TaskPriority.
  TextColumn get priority => text().withLength(max: 16)();

  /// Stored as the canonical wire name of TaskStatus.
  TextColumn get status => text().withLength(max: 16)();

  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();

  /// When the task reached DONE.
  ///
  /// Status alone cannot answer "what did I finish last week": it says where
  /// a task is, not when it got there. Cleared if the task is reopened.
  DateTimeColumn get completedAt => dateTime().nullable()();
}

/// A progress note attached to a task.
@TableIndex(name: 'task_comment_lookup', columns: {#taskId, #createdAt})
@DataClassName('TaskCommentRow')
class TaskComments extends Table with RecordColumns {
  TextColumn get taskId =>
      text().references(TodoTasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text().withLength(max: 5000)();
  DateTimeColumn get createdAt => dateTime()();
}
