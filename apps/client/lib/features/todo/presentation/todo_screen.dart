import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/time/selected_day_provider.dart';
import '../../../core/widgets/async_section.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/module_scaffold.dart';
import '../../../core/widgets/name_prompt_dialog.dart';
import '../../../core/widgets/section_header.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/board_column.dart';
import '../domain/project.dart';
import '../domain/task.dart';
import 'todo_labels.dart';
import 'todo_progress_view.dart';
import 'todo_providers.dart';
import 'widgets/board_columns_dialog.dart';
import 'widgets/project_tree_view.dart';
import 'widgets/task_card.dart';
import 'widgets/task_dialog.dart';

/// The To-Do tab: a project tree beside a board of its tasks.
class TodoScreen extends ConsumerWidget {
  const TodoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final projects = ref.watch(projectTreeProvider);
    final selectedId = ref.watch(selectedProjectIdProvider);
    final mode = ref.watch(todoViewModeProvider);
    final wide = MediaQuery.sizeOf(context).width >= 900;

    Future<void> newProject() async {
      final name = await promptForName(context, title: l10n.todoNewProject);
      if (name != null) await ref.read(todoActionsProvider).createProject(name);
    }

    return ModuleScaffold(
      title: l10n.todoTitle,
      // The tree and the board are two panes, not a column of cards: the
      // reading measure would leave neither of them room.
      listMaxWidth: double.infinity,
      actions: [
        IconButton(
          icon: Icon(
            mode == TodoViewMode.kanban
                ? Icons.view_list_outlined
                : Icons.view_kanban_outlined,
          ),
          tooltip: mode == TodoViewMode.kanban
              ? l10n.todoViewList
              : l10n.todoViewKanban,
          onPressed: () => ref.read(todoViewModeProvider.notifier).state =
              mode == TodoViewMode.kanban
              ? TodoViewMode.list
              : TodoViewMode.kanban,
        ),
        IconButton(
          icon: const Icon(Icons.view_column_outlined),
          tooltip: l10n.todoEditColumns,
          // A board belongs to a project, so there is nothing to arrange
          // until one is picked.
          onPressed: selectedId == null
              ? null
              : () => showBoardColumnsDialog(
                  context,
                  projectId: selectedId,
                  projectName:
                      projects.valueOrNull?.tree.all
                          .where((project) => project.id == selectedId)
                          .firstOrNull
                          ?.name ??
                      '',
                ),
        ),
        IconButton(
          icon: const Icon(Icons.create_new_folder_outlined),
          tooltip: l10n.todoNewProject,
          onPressed: newProject,
        ),
      ],
      progress: const TodoProgressView(),
      floatingActionButton: selectedId == null
          ? null
          : FloatingActionButton(
              onPressed: () => showTaskDialog(context, projectId: selectedId),
              tooltip: l10n.todoNewTask,
              child: const Icon(Icons.add),
            ),
      list: AsyncSection(
        value: projects,
        builder: (data) {
          if (data.tree.all.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.folder_off_outlined,
                title: l10n.todoNoProjects,
                hint: l10n.todoNoProjectsHint,
              ),
            );
          }

          final sidebar = ProjectTreeView(
            tree: data.tree,
            counts: data.counts,
            tallies: data.tallies,
          );

          if (!wide) {
            // On a narrow window the tree becomes a sheet: a permanent
            // sidebar would leave nothing for the board.
            return Column(
              children: [
                _ProjectStrip(tree: data.tree),
                const Divider(height: 1),
                Expanded(child: _Board()),
              ],
            );
          }

          return Row(
            children: [
              SizedBox(width: 280, child: sidebar),
              const VerticalDivider(width: 1),
              Expanded(child: _Board()),
            ],
          );
        },
      ),
    );
  }
}

/// The projects as a scrolling row, for narrow windows.
class _ProjectStrip extends ConsumerWidget {
  const _ProjectStrip({required this.tree});

  final ProjectTree tree;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedProjectIdProvider);

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Gap.lg),
        children: [
          for (final project in tree.all)
            Padding(
              padding: const EdgeInsets.only(right: Gap.sm, top: Gap.sm),
              child: ChoiceChip(
                label: Text(project.name),
                selected: selected == project.id,
                onSelected: (_) =>
                    ref.read(selectedProjectIdProvider.notifier).state =
                        project.id,
              ),
            ),
        ],
      ),
    );
  }
}

class _Board extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedId = ref.watch(selectedProjectIdProvider);
    final tasks = ref.watch(tasksProvider);

    if (selectedId == null) {
      return Center(
        child: EmptyState(
          icon: Icons.touch_app_outlined,
          title: l10n.todoPickProject,
          hint: l10n.todoPickProjectHint,
        ),
      );
    }

    return Column(
      // Stretched, so the filter bar starts at the board's own left edge.
      // A column centres its children by default, which left a bar that
      // sizes to its content floating in the middle of the window.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FilterBar(),
        const Divider(height: 1),
        Expanded(
          child: tasks.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('$error')),
            data: (items) => items.isEmpty
                ? Center(
                    child: EmptyState(
                      icon: Icons.check_circle_outline,
                      title: l10n.todoNoTasks,
                      hint: l10n.todoNoTasksHint,
                    ),
                  )
                : ref.watch(todoViewModeProvider) == TodoViewMode.kanban
                ? _Kanban(tasks: items, projectId: selectedId)
                : _TaskList(tasks: items, projectId: selectedId),
          ),
        ),
      ],
    );
  }
}

class _FilterBar extends ConsumerWidget {
  const _FilterBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final filters = ref.watch(taskFiltersProvider);
    final notifier = ref.read(taskFiltersProvider.notifier);

    // Everything flush left, in one group. The filter used to be pushed to
    // the far edge by a spacer, which left the bar reading as two unrelated
    // controls with a gulf between them — and put the box the user types in
    // as far from the board's first column as the window allowed.
    return Padding(
      padding: const EdgeInsets.all(Gap.md),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Gap.md,
        runSpacing: Gap.sm,
        children: [
          SizedBox(
            width: 220,
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.todoFilterCategory,
                prefixIcon: const Icon(Icons.filter_alt_outlined, size: 18),
              ),
              onChanged: (value) =>
                  notifier.state = filters.copyWith(category: value),
            ),
          ),
          SizedBox(
            width: 220,
            child: TextField(
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.todoFilterOwner,
                prefixIcon: const Icon(Icons.person_outline, size: 18),
              ),
              onChanged: (value) =>
                  notifier.state = filters.copyWith(owner: value),
            ),
          ),
          // The scope of the board rather than a filter on it, so it sits
          // after the two boxes rather than among them.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchScope(
                child: Switch(
                  value: ref.watch(includeDescendantsProvider),
                  onChanged: (value) =>
                      ref.read(includeDescendantsProvider.notifier).state =
                          value,
                ),
              ),
              const SizedBox(width: Gap.sm),
              Text(
                l10n.todoIncludeSubprojects,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (!filters.isEmpty)
            TextButton(
              onPressed: () => notifier.state = const TaskFilters(),
              child: Text(l10n.todoFilterClear),
            ),
        ],
      ),
    );
  }
}

/// Keeps the switch from stretching the row it lives in.
class SwitchScope extends StatelessWidget {
  const SwitchScope({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 52, child: FittedBox(child: child));
}

class _Kanban extends ConsumerWidget {
  const _Kanban({required this.tasks, required this.projectId});

  final List<Task> tasks;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final board = ref.watch(boardProvider);

    return board.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('$error')),
      data: (data) => data.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.view_column_outlined,
                title: l10n.todoColumns,
                hint: l10n.todoColumnLastOne,
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // The columns used to be 280 wide whatever the window was, so
                // a board of three left most of a desktop page empty and the
                // work looked huddled in a corner. They share the width when
                // it is there, and go back to scrolling sideways once there
                // are more columns than fit — which is the only case where a
                // fixed width was ever the right answer.
                const gap = Gap.md;
                const minWidth = 260.0;
                final available = constraints.maxWidth - gap * 2;
                final share =
                    (available - gap * (data.columns.length - 1)) /
                    data.columns.length;
                final width = share >= minWidth ? share : minWidth;
                final fits = share >= minWidth;

                final row = Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final (index, column) in data.columns.indexed)
                      Padding(
                        padding: EdgeInsets.only(
                          right: index == data.columns.length - 1 ? 0 : gap,
                        ),
                        child: _Column(
                          column: column,
                          width: width,
                          // By the column it is drawn under, not the one it
                          // sits in: a task pulled in from a subproject
                          // answers to its own project's board, and those
                          // are other rows entirely.
                          tasks: tasks
                              .where((task) => task.boardColumnId == column.id)
                              .toList(),
                          projectId: projectId,
                        ),
                      ),
                  ],
                );

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(gap),
                  // Without this the row inside a horizontal scroll view is
                  // free to be as narrow as its children, and the columns
                  // would hug the left however wide they were told to be.
                  physics: fits ? const NeverScrollableScrollPhysics() : null,
                  child: row,
                );
              },
            ),
    );
  }
}

class _Column extends ConsumerWidget {
  const _Column({
    required this.column,
    required this.width,
    required this.tasks,
    required this.projectId,
  });

  final BoardColumn column;
  final double width;
  final List<Task> tasks;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayProvider);

    return DragTarget<Task>(
      // Dropping a task where it already is would be a pointless write.
      onWillAcceptWithDetails: (details) => details.data.columnId != column.id,
      onAcceptWithDetails: (details) =>
          ref.read(todoActionsProvider).moveTask(details.data.id, column.id),
      builder: (context, candidate, _) => Container(
        width: width,
        padding: const EdgeInsets.all(Gap.sm),
        decoration: BoxDecoration(
          color: candidate.isEmpty
              ? Colors.transparent
              : theme.colorScheme.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: candidate.isEmpty
                ? Colors.transparent
                : theme.colorScheme.primary,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(
              label: '${l10n.columnName(column)} · ${tasks.length}',
            ),
            for (final task in tasks)
              Padding(
                padding: const EdgeInsets.only(bottom: Gap.sm),
                child: Draggable<Task>(
                  data: task,
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: width - Gap.md,
                      child: TaskCard(task: task, today: today, onTap: () {}),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.3,
                    child: TaskCard(task: task, today: today, onTap: () {}),
                  ),
                  child: TaskCard(
                    task: task,
                    today: today,
                    onTap: () => showTaskDialog(
                      context,
                      projectId: projectId,
                      existing: task,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks, required this.projectId});

  final List<Task> tasks;
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayProvider);

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.md, Gap.lg, 96),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: Gap.sm),
      itemBuilder: (context, index) => TaskCard(
        task: tasks[index],
        today: today,
        onTap: () => showTaskDialog(
          context,
          projectId: projectId,
          existing: tasks[index],
        ),
      ),
    );
  }
}
