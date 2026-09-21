import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/board_column.dart';
import '../todo_labels.dart';
import '../todo_providers.dart';

/// Where the user arranges one project's board.
///
/// The columns were an enum until v15, so this screen had nothing to show:
/// the board was a decision the code had made. Everything here writes
/// straight through — there is no Save, because a board half-applied is worse
/// than one the user can see changing as they go.
///
/// Scoped to [projectName]'s project since v16. A single board for the whole
/// app meant a column added for one piece of work turned up on every other.
Future<void> showBoardColumnsDialog(
  BuildContext context, {
  required String projectId,
  required String projectName,
}) => showDialog<void>(
  context: context,
  builder: (context) =>
      _BoardColumnsDialog(projectId: projectId, projectName: projectName),
);

class _BoardColumnsDialog extends ConsumerWidget {
  const _BoardColumnsDialog({
    required this.projectId,
    required this.projectName,
  });

  final String projectId;
  final String projectName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final board = ref.watch(boardProvider);
    final counts = ref.watch(columnTaskCountsProvider);

    return AlertDialog(
      // Named, so it is plain that this rearranges one board and not the app.
      title: Text('${l10n.todoEditColumns} · $projectName'),
      content: SizedBox(
        width: 460,
        child: board.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(Gap.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Text('$error'),
          data: (data) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, column) in data.columns.indexed)
                  _ColumnRow(
                    column: column,
                    board: data,
                    index: index,
                    taskCount: counts.valueOrNull?[column.id] ?? 0,
                  ),
                const SizedBox(height: Gap.sm),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(l10n.todoNewColumn),
                    onPressed: () async {
                      final result = await showColumnEditor(context);
                      if (result == null) return;
                      await ref
                          .read(todoActionsProvider)
                          .createColumn(
                            projectId,
                            result.name,
                            countsAsDone: result.countsAsDone,
                          );
                    },
                  ),
                ),
              ],
            ),
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

class _ColumnRow extends ConsumerWidget {
  const _ColumnRow({
    required this.column,
    required this.board,
    required this.index,
    required this.taskCount,
  });

  final BoardColumn column;
  final Board board;
  final int index;
  final int taskCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(todoActionsProvider);

    Future<void> move(int to) async {
      final ids = [for (final each in board.columns) each.id];
      ids.insert(to, ids.removeAt(index));
      await actions.reorderColumns(ids);
    }

    // Said before the attempt rather than after it: a delete button that
    // always looks available and then explains itself is a button that lies.
    final blocked = taskCount > 0
        ? l10n.todoColumnHoldsTasks(taskCount)
        : !board.canDelete(column.id)
        ? l10n.todoColumnLastOne
        : null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.columnName(column)),
      subtitle: Text(
        [
          if (column.countsAsDone) l10n.todoColumnCountsAsDone,
          l10n.todoTaskCount(taskCount),
        ].join(' · '),
        style: theme.textTheme.bodySmall,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_upward, size: 18),
            tooltip: l10n.todoColumnMoveLeft,
            onPressed: index == 0 ? null : () => move(index - 1),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward, size: 18),
            tooltip: l10n.todoColumnMoveRight,
            onPressed: index == board.columns.length - 1
                ? null
                : () => move(index + 1),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: l10n.actionEdit,
            onPressed: () async {
              final result = await showColumnEditor(
                context,
                // The stored name, not the translated one: editing a seeded
                // column should start from the word on screen, and for those
                // two the word on screen is the translation.
                initialName: l10n.columnName(column),
                initialCountsAsDone: column.countsAsDone,
              );
              if (result == null) return;
              await actions.updateColumn(
                column.id,
                name: result.name,
                countsAsDone: result.countsAsDone,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 18),
            tooltip: blocked ?? l10n.actionDelete,
            onPressed: blocked != null
                ? null
                : () async {
                    if (await confirmDelete(context, l10n.columnName(column))) {
                      await actions.deleteColumn(column.id);
                    }
                  },
          ),
        ],
      ),
    );
  }
}

/// What the editor hands back.
typedef ColumnEdit = ({String name, bool countsAsDone});

/// Asks for a column's name and whether landing there finishes the work.
Future<ColumnEdit?> showColumnEditor(
  BuildContext context, {
  String initialName = '',
  bool initialCountsAsDone = false,
}) => showDialog<ColumnEdit>(
  context: context,
  builder: (context) => _ColumnEditor(
    initialName: initialName,
    initialCountsAsDone: initialCountsAsDone,
  ),
);

class _ColumnEditor extends StatefulWidget {
  const _ColumnEditor({
    required this.initialName,
    required this.initialCountsAsDone,
  });

  final String initialName;
  final bool initialCountsAsDone;

  @override
  State<_ColumnEditor> createState() => _ColumnEditorState();
}

class _ColumnEditorState extends State<_ColumnEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  late bool _countsAsDone = widget.initialCountsAsDone;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(
        widget.initialName.isEmpty ? l10n.todoNewColumn : l10n.actionEdit,
      ),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                maxLength: BoardColumn.maxNameLength,
                decoration: InputDecoration(labelText: l10n.todoColumnName),
                validator: (value) => (value ?? '').trim().isEmpty
                    ? l10n.validationNameRequired
                    : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _countsAsDone,
                title: Text(l10n.todoColumnCountsAsDone),
                subtitle: Text(
                  l10n.todoColumnCountsAsDoneHint,
                  style: theme.textTheme.bodySmall,
                ),
                onChanged: (value) => setState(() => _countsAsDone = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context)
                .pop((name: _name.text.trim(), countsAsDone: _countsAsDone));
          },
          child: Text(l10n.actionSave),
        ),
      ],
    );
  }
}
