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

/// A column of one project's board.
///
/// The three the app ships with used to be an enum, which is why the board
/// could not be rearranged: a column was a value in the code, so adding one
/// meant a release. They are rows now, and the user owns them.
///
/// One board per project. A single board for the whole app meant that a
/// column added for one piece of work appeared on every other, and projects
/// do not run the same way: a reading list has no "in review".
///
/// [builtInKey] is what keeps the shipped three bilingual. A name typed by
/// the user is data and cannot be translated, but "Pendiente" was a label
/// until these became rows and would freeze into whichever language happened
/// to be on when the migration ran. So the shipped columns keep a key, the UI
/// shows the translation for it, and renaming one clears the key — from then
/// on it is the user's word, in the user's language.
@DataClassName('BoardColumnRow')
@TableIndex(name: 'board_column_order', columns: {#projectId, #position})
class BoardColumns extends Table with RecordColumns {
  /// The project whose board this column belongs to.
  ///
  /// Cascades: a board is part of a project, not a thing that outlives it.
  TextColumn get projectId =>
      text().references(Projects, #id, onDelete: KeyAction.cascade)();

  /// What the user calls it. Ignored for display while [builtInKey] is set.
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// `TODO`, `IN_PROGRESS`, `DONE` for the columns the app seeded, null once
  /// the user renames one or writes their own.
  TextColumn get builtInKey => text().withLength(max: 16).nullable()();

  /// Left to right on the board.
  IntColumn get position => integer()();

  /// Whether landing here means the work is finished.
  ///
  /// Not decoration and not derived from the name: it is what stamps
  /// `completedAt`, what keeps a finished task from reading as overdue, and
  /// what the dashboard counts. A board with no such column is allowed — it
  /// just never finishes anything, which is the user's business.
  BoolColumn get countsAsDone => boolean().withDefault(const Constant(false))();
}

/// A unit of work belonging to a project.
@TableIndex(name: 'task_project_lookup', columns: {#projectId, #columnId})
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

  /// The column of the board the task sits in.
  ///
  /// `ON DELETE RESTRICT`, unlike every other reference in this store: a
  /// column is a place tasks are kept, and deleting one has to move them
  /// rather than take them with it. The UI refuses while the column still
  /// holds tasks; the constraint is what makes that true even if the UI
  /// forgets.
  TextColumn get columnId =>
      text().references(BoardColumns, #id, onDelete: KeyAction.restrict)();

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

/// One line of a task's checklist.
///
/// Kept apart from the task rather than serialised into its description: a
/// checklist is ticked one line at a time, and a blob of text cannot record
/// which line was done without rewriting the whole thing on every tick.
@DataClassName('TaskChecklistItemRow')
@TableIndex(name: 'checklist_by_task', columns: {#taskId, #position})
class TaskChecklistItems extends Table with RecordColumns {
  TextColumn get taskId =>
      text().references(TodoTasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text().withLength(min: 1, max: 1000)();
  BoolColumn get done => boolean().withDefault(const Constant(false))();

  /// Top to bottom. A checklist is a sequence, not a set.
  IntColumn get position => integer()();
}
