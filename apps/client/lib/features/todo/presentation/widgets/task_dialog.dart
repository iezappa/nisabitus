import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/time/selected_day_provider.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/save_failure.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/board_column.dart';
import '../../domain/task.dart';
import '../../domain/todo_repository.dart';
import '../todo_labels.dart';
import '../todo_providers.dart';

/// Opens a task.
///
/// An existing task opens as something to read, with its updates beside it,
/// and turns into a form only when asked. Opening straight into the editor
/// made every glance at a task a chance to change it by accident, and put
/// the one thing worth seeing — what has happened to it — below the fold.
///
/// A new task has nothing to read, so it opens as the form.
Future<void> showTaskDialog(
  BuildContext context, {
  required String projectId,
  Task? existing,
}) => showDialog<void>(
  context: context,
  builder: (context) => _TaskDialog(projectId: projectId, existing: existing),
);

class _TaskDialog extends ConsumerStatefulWidget {
  const _TaskDialog({required this.projectId, this.existing});

  final String projectId;
  final Task? existing;

  @override
  ConsumerState<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends ConsumerState<_TaskDialog> {
  late bool _editing = widget.existing == null;

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    if (existing == null || _editing) {
      return _TaskForm(
        projectId: widget.projectId,
        existing: existing,
        // A cancelled edit goes back to the task, not out of it: the user
        // opened it to look at something.
        onDone: existing == null
            ? () => Navigator.of(context).pop()
            : () => setState(() => _editing = false),
      );
    }

    // Read from the store rather than from what was passed in, so an edit
    // made a moment ago is on screen when the form closes over it.
    final live = ref
        .watch(tasksProvider)
        .valueOrNull
        ?.where((task) => task.id == existing.id)
        .firstOrNull;

    return _TaskDetail(
      task: live ?? existing,
      onEdit: () => setState(() => _editing = true),
    );
  }
}

/// A task as something to read: its own details on the left, what has
/// happened to it on the right.
///
/// Laid out as labelled boxes rather than a run of fields. A card carries
/// several unrelated things — what it is, what is left to do, what people
/// have said — and a flat column makes the reader work out where one ends
/// and the next begins. Each section says what it is, so a glance finds the
/// part being looked for.
class _TaskDetail extends ConsumerWidget {
  const _TaskDetail({required this.task, required this.onEdit});

  final Task task;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(todayProvider);
    final column = ref.watch(boardProvider).valueOrNull?.byId(task.columnId);

    // Two columns side by side, and one above the other when the window
    // cannot hold them. The updates are half the reason this dialog is worth
    // opening, so on a wide screen they are never a thing to scroll down to.
    final wide = MediaQuery.sizeOf(context).width >= 860;

    final left = [
      _Section(
        icon: Icons.notes_outlined,
        title: l10n.todoFieldDescription,
        child: _Boxed(
          child: Text(
            task.description?.trim().isNotEmpty == true
                ? task.description!
                : l10n.todoNoDescription,
            style: task.description?.trim().isNotEmpty == true
                ? theme.textTheme.bodyMedium
                : theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
          ),
        ),
      ),
      _Section(
        icon: Icons.info_outline,
        title: l10n.todoDetails,
        child: _TaskFacts(task: task, today: today),
      ),
    ];

    final right = [
      _Section(
        icon: Icons.checklist_outlined,
        title: l10n.todoChecklist,
        child: _Checklist(task: task),
      ),
      _Section(
        icon: Icons.forum_outlined,
        title: l10n.todoUpdates,
        child: _Updates(task: task),
      ),
    ];

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(Gap.lg, Gap.lg, Gap.md, 0),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2, right: Gap.sm),
            child: Icon(
              Icons.crop_square_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: theme.textTheme.titleMedium),
                if (column case final column?)
                  Text(
                    '${l10n.todoInColumn} ${l10n.columnName(column)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: l10n.actionEdit,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: l10n.actionDelete,
            onPressed: () async {
              if (!await confirmDelete(context, task.title)) return;
              if (!context.mounted) return;
              final gone = await reportDeleteFailure(
                context,
                () => ref.read(todoActionsProvider).deleteTask(task.id),
              );
              // Only once it is gone: a delete that threw leaves the task in
              // place, and closing over it would say otherwise.
              if (gone && context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      content: SizedBox(
        width: wide ? 860 : 460,
        child: SingleChildScrollView(
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // The task's own side is the wider one: a description
                    // reads badly in a narrow column, and the updates are
                    // short lines.
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: left,
                      ),
                    ),
                    const SizedBox(width: Gap.lg),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: right,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [...left, ...right],
                ),
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionClose),
        ),
      ],
    );
  }
}

/// One labelled part of the card: an icon, a heading, and its contents.
class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: Gap.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          // Indented under the heading, the way the icon column sets it up.
          Padding(padding: const EdgeInsets.only(left: 26), child: child),
        ],
      ),
    );
  }
}

/// The grey box a section's contents sit in.
///
/// What makes the card read as parts rather than as one long column: the
/// boundary is drawn once, quietly, instead of by spacing the reader has to
/// interpret.
class _Boxed extends StatelessWidget {
  const _Boxed({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

/// What the task says about itself, as labelled rows inside one box.
class _TaskFacts extends StatelessWidget {
  const _TaskFacts({required this.task, required this.today});

  final Task task;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final due = task.dueState(today);

    return _Boxed(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: Gap.sm,
            runSpacing: Gap.xs,
            children: [
              Chip(
                label: Text(l10n.priorityName(task.priority)),
                avatar: Icon(
                  Icons.flag_outlined,
                  size: 16,
                  color: priorityColor(context, task.priority),
                ),
                visualDensity: VisualDensity.compact,
              ),
              if (task.category case final category? when category.isNotEmpty)
                Chip(
                  label: Text(category),
                  visualDensity: VisualDensity.compact,
                ),
              if (task.owner case final owner? when owner.isNotEmpty)
                Chip(
                  label: Text(owner),
                  avatar: const Icon(Icons.person_outline, size: 16),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: Gap.sm),
          _Fact(
            label: l10n.todoFieldDue,
            value: task.dueDate == null
                ? '—'
                : DateFormat('dd/MM/yyyy').format(task.dueDate!),
            color: dueColor(context, due),
            note: l10n.dueName(due),
          ),
          if (task.completedAt case final stamp?)
            _Fact(
              label: l10n.todoStatusDone,
              value: DateFormat('dd/MM/yyyy HH:mm').format(stamp),
            ),
          if (task.projectName case final name?)
            _Fact(label: l10n.todoPickProject, value: name),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({
    required this.label,
    required this.value,
    this.color,
    this.note,
  });

  final String label;
  final String value;
  final Color? color;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: theme.textTheme.labelSmall),
          Text(
            note == null ? value : '$value · $note',
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// What is left to do inside the task.
class _Checklist extends ConsumerStatefulWidget {
  const _Checklist({required this.task});

  final Task task;

  @override
  ConsumerState<_Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends ConsumerState<_Checklist> {
  final _line = TextEditingController();

  @override
  void dispose() {
    _line.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_line.text.trim().isEmpty) return;
    await ref
        .read(todoActionsProvider)
        .addChecklistItem(widget.task.id, _line.text);
    _line.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(checklistProvider(widget.task.id));
    final actions = ref.read(todoActionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        items.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('$error'),
          data: (lines) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (lines.isNotEmpty) ...[
                Row(
                  children: [
                    Text(
                      l10n.todoChecklistProgress(lines.doneCount, lines.length),
                      style: theme.textTheme.labelSmall,
                    ),
                    const SizedBox(width: Gap.sm),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: lines.checkedShare,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: Gap.xs),
              ],
              for (final item in lines)
                _ChecklistLine(item: item, actions: actions),
            ],
          ),
        ),
        const SizedBox(height: Gap.xs),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _line,
                // A label rather than a hint, and the difference is not
                // cosmetic: a hint is painted in the same place as what the
                // user types, so anything that stops it being cleared in time
                // leaves the two on top of each other. A label moves out to
                // the border as soon as there is text, so there is nothing
                // left to sit under.
                decoration: InputDecoration(
                  labelText: l10n.todoAddChecklistItem,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Gap.md,
                    vertical: Gap.sm,
                  ),
                ),
                onSubmitted: (_) => _add(),
              ),
            ),
            const SizedBox(width: Gap.sm),
            IconButton.filledTonal(
              icon: const Icon(Icons.add, size: 18),
              tooltip: l10n.todoAddChecklistItem,
              onPressed: _add,
            ),
          ],
        ),
      ],
    );
  }
}

class _ChecklistLine extends StatelessWidget {
  const _ChecklistLine({required this.item, required this.actions});

  final ChecklistItem item;
  final TodoActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        SizedBox(
          width: 32,
          child: Checkbox(
            value: item.done,
            visualDensity: VisualDensity.compact,
            onChanged: (value) =>
                actions.updateChecklistItem(item.id, done: value ?? false),
          ),
        ),
        Expanded(
          child: Text(
            item.content,
            style: theme.textTheme.bodyMedium?.copyWith(
              decoration: item.done ? TextDecoration.lineThrough : null,
              color: item.done ? theme.colorScheme.onSurfaceVariant : null,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          tooltip: l10n.actionDelete,
          visualDensity: VisualDensity.compact,
          onPressed: () => actions.deleteChecklistItem(item.id),
        ),
      ],
    );
  }
}

/// What has happened to the task since it was written down.
class _Updates extends ConsumerStatefulWidget {
  const _Updates({required this.task});

  final Task task;

  @override
  ConsumerState<_Updates> createState() => _UpdatesState();
}

class _UpdatesState extends ConsumerState<_Updates> {
  final _comment = TextEditingController();

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_comment.text.trim().isEmpty) return;
    await ref
        .read(todoActionsProvider)
        .addComment(widget.task.id, _comment.text);
    _comment.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final comments = ref.watch(commentsProvider(widget.task.id));
    final actions = ref.read(todoActionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _comment,
                minLines: 1,
                maxLines: 4,
                // A label rather than a hint: see the checklist composer.
                // `alignLabelWithHint` keeps it on the first line of a field
                // that grows, instead of centred against four lines of text.
                decoration: InputDecoration(
                  labelText: l10n.todoAddUpdate,
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Gap.md,
                    vertical: Gap.sm,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: Gap.sm),
            IconButton.filledTonal(
              icon: const Icon(Icons.send, size: 18),
              tooltip: l10n.todoAddUpdate,
              onPressed: _send,
            ),
          ],
        ),
        const SizedBox(height: Gap.sm),
        comments.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.md),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('$error'),
          data: (items) => items.isEmpty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l10n.todoNoUpdates,
                    style: theme.textTheme.bodySmall,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Newest first, because the composer is at the top and
                    // what was just written should land next to it.
                    for (final comment in items.reversed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: Gap.sm),
                        child: _Boxed(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      DateFormat('dd/MM/yyyy HH:mm')
                                          .format(comment.createdAt),
                                      style: theme.textTheme.labelSmall,
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () async {
                                      if (await confirmDelete(
                                        context,
                                        comment.content,
                                      )) {
                                        await actions.deleteComment(comment.id);
                                      }
                                    },
                                    child: Icon(
                                      Icons.close,
                                      size: 14,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                comment.content,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// The task as a form.
class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({
    required this.projectId,
    required this.onDone,
    this.existing,
  });

  final String projectId;
  final Task? existing;

  /// Called after a save, and on cancel.
  final VoidCallback onDone;

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late final _category = TextEditingController(
    text: widget.existing?.category ?? '',
  );
  late final _owner = TextEditingController(text: widget.existing?.owner ?? '');

  late TaskPriority _priority =
      widget.existing?.priority ?? TaskPriority.medium;
  late String? _columnId = widget.existing?.columnId;
  late DateTime? _due = widget.existing?.dueDate;

  @override
  void dispose() {
    for (final c in [_title, _description, _category, _owner]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _text(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final draft = TaskDraft(
      title: _title.text,
      projectId: widget.existing?.projectId ?? widget.projectId,
      description: _text(_description),
      category: _text(_category),
      owner: _text(_owner),
      dueDate: _due,
      priority: _priority,
      columnId: _columnId,
    );

    final actions = ref.read(todoActionsProvider);
    if (widget.existing case final task?) {
      await actions.updateTask(task.id, draft);
    } else {
      await actions.createTask(draft);
    }
    widget.onDone();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _due = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final existing = widget.existing;
    final board = ref.watch(boardProvider).valueOrNull;
    // Falls back to the board's own default, which is what the repository
    // would pick anyway; showing it selected means the form and the store
    // agree before anything is saved.
    final selected = _columnId ?? board?.defaultColumn?.id;

    return AlertDialog(
      title: Text(existing == null ? l10n.todoNewTask : l10n.todoEditTask),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  autofocus: true,
                  maxLength: 255,
                  decoration: InputDecoration(labelText: l10n.todoFieldTitle),
                  validator: (v) => (v ?? '').trim().isEmpty
                      ? l10n.validationNameRequired
                      : null,
                ),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: l10n.todoFieldDescription,
                  ),
                ),
                TextFormField(
                  controller: _category,
                  maxLength: 255,
                  decoration: InputDecoration(labelText: l10n.fieldCategory),
                ),
                _OwnerField(controller: _owner),
                const SizedBox(height: Gap.md),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: _priority,
                  decoration: InputDecoration(
                    labelText: l10n.todoFieldPriority,
                  ),
                  items: [
                    for (final priority in TaskPriority.values)
                      DropdownMenuItem(
                        value: priority,
                        child: Text(l10n.priorityName(priority)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _priority = v ?? _priority),
                ),
                const SizedBox(height: Gap.md),
                if (board != null && !board.isEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selected,
                    decoration: InputDecoration(
                      labelText: l10n.todoFieldColumn,
                    ),
                    items: [
                      for (final column in board.columns)
                        DropdownMenuItem(
                          value: column.id,
                          child: Text(l10n.columnName(column)),
                        ),
                    ],
                    onChanged: (v) => setState(() => _columnId = v ?? selected),
                  ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.todoFieldDue),
                  subtitle: Text(
                    _due == null ? '—' : DateFormat('dd/MM/yyyy').format(_due!),
                  ),
                  trailing: _due == null
                      ? const Icon(Icons.calendar_today_outlined, size: 18)
                      : IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _due = null),
                        ),
                  onTap: _pickDue,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: widget.onDone, child: Text(l10n.actionCancel)),
        FilledButton(onPressed: _save, child: Text(l10n.actionSave)),
      ],
    );
  }
}

/// Whose task it is, with the names already used offered underneath.
///
/// Typed rather than picked from a list of people, because there is no list
/// of people: this app has no accounts. The suggestions are simply the names
/// the user has assigned before, so the second task for the same person does
/// not have to be spelled the same way twice by hand.
class _OwnerField extends ConsumerWidget {
  const _OwnerField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final known = ref.watch(taskOwnersProvider).valueOrNull ?? const [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          maxLength: 80,
          decoration: InputDecoration(
            labelText: l10n.todoFieldOwner,
            // Helper, not hint: a hint is painted where the user types and
            // overlaps what they write.
            helperText: l10n.todoOwnerHint,
            prefixIcon: const Icon(Icons.person_outline, size: 18),
          ),
        ),
        if (known.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: Gap.sm),
            child: Wrap(
              spacing: Gap.sm,
              runSpacing: Gap.xs,
              children: [
                for (final owner in known)
                  ActionChip(
                    label: Text(owner),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => controller.text = owner,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
