import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/task.dart';
import '../../domain/todo_repository.dart';
import '../todo_labels.dart';
import '../todo_providers.dart';

/// The task editor, with its progress notes underneath.
///
/// Comments only exist for a task that has been saved, so a brand new task
/// shows the fields alone.
Future<void> showTaskDialog(
  BuildContext context, {
  required int projectId,
  Task? existing,
}) => showDialog<void>(
  context: context,
  builder: (context) => _TaskDialog(projectId: projectId, existing: existing),
);

class _TaskDialog extends ConsumerStatefulWidget {
  const _TaskDialog({required this.projectId, this.existing});

  final int projectId;
  final Task? existing;

  @override
  ConsumerState<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends ConsumerState<_TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title ?? '');
  late final _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late final _category = TextEditingController(
    text: widget.existing?.category ?? '',
  );
  final _comment = TextEditingController();

  late TaskPriority _priority =
      widget.existing?.priority ?? TaskPriority.medium;
  late TaskStatus _status = widget.existing?.status ?? TaskStatus.todo;
  late DateTime? _due = widget.existing?.dueDate;

  @override
  void dispose() {
    for (final c in [_title, _description, _category, _comment]) {
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
      dueDate: _due,
      priority: _priority,
      status: _status,
    );

    final actions = ref.read(todoActionsProvider);
    if (widget.existing case final task?) {
      await actions.updateTask(task.id, draft);
    } else {
      await actions.createTask(draft);
    }
    if (mounted) Navigator.of(context).pop();
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
                const SizedBox(height: Gap.sm),
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
                DropdownButtonFormField<TaskStatus>(
                  initialValue: _status,
                  decoration: InputDecoration(labelText: l10n.todoFieldStatus),
                  items: [
                    for (final status in TaskStatus.values)
                      DropdownMenuItem(
                        value: status,
                        child: Text(l10n.statusName(status)),
                      ),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? _status),
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
                if (existing != null) ...[
                  const Divider(height: Gap.xl),
                  _Comments(task: existing, controller: _comment),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (existing != null)
          TextButton(
            onPressed: () async {
              if (await confirmDelete(context, existing.title)) {
                await ref.read(todoActionsProvider).deleteTask(existing.id);
                if (context.mounted) Navigator.of(context).pop();
              }
            },
            child: Text(l10n.actionDelete),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.actionSave)),
      ],
    );
  }
}

class _Comments extends ConsumerWidget {
  const _Comments({required this.task, required this.controller});

  final Task task;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final comments = ref.watch(commentsProvider(task.id));
    final actions = ref.read(todoActionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.todoComments.toUpperCase(), style: theme.textTheme.labelSmall),
        const SizedBox(height: Gap.sm),
        comments.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) => items.isEmpty
              ? Text(l10n.todoNoComments, style: theme.textTheme.bodySmall)
              : Column(
                  children: [
                    for (final comment in items)
                      ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          comment.content,
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(
                            comment.createdAt,
                          ),
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          tooltip: l10n.actionDelete,
                          onPressed: () async {
                            if (await confirmDelete(context, comment.content)) {
                              await actions.deleteComment(comment.id);
                            }
                          },
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: Gap.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(hintText: l10n.todoCommentHint),
                onSubmitted: (_) async {
                  if (controller.text.trim().isEmpty) return;
                  await actions.addComment(task.id, controller.text);
                  controller.clear();
                },
              ),
            ),
            const SizedBox(width: Gap.sm),
            IconButton.filled(
              icon: const Icon(Icons.send, size: 18),
              onPressed: () async {
                if (controller.text.trim().isEmpty) return;
                await actions.addComment(task.id, controller.text);
                controller.clear();
              },
            ),
          ],
        ),
      ],
    );
  }
}
