import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/name_prompt_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/project.dart';
import '../todo_providers.dart';

/// The project hierarchy, indented by depth.
class ProjectTreeView extends ConsumerWidget {
  const ProjectTreeView({
    required this.tree,
    required this.counts,
    super.key,
  });

  final ProjectTree tree;
  final Map<int, TaskCount> counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.only(bottom: Gap.xl),
      children: [
        for (final root in tree.childrenOf(null))
          _Node(project: root, tree: tree, counts: counts, depth: 1),
      ],
    );
  }
}

class _Node extends ConsumerWidget {
  const _Node({
    required this.project,
    required this.tree,
    required this.counts,
    required this.depth,
  });

  final Project project;
  final ProjectTree tree;
  final Map<int, TaskCount> counts;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(selectedProjectIdProvider) == project.id;
    final actions = ref.read(todoActionsProvider);
    final count = counts[project.id];
    final children = tree.childrenOf(project.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: (depth - 1) * Gap.lg),
          child: ListTile(
            dense: true,
            selected: selected,
            selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
            leading: Icon(
              children.isEmpty ? Icons.folder_outlined : Icons.folder_copy_outlined,
              size: 18,
            ),
            title: Text(project.name, overflow: TextOverflow.ellipsis),
            subtitle: count == null || count.total == 0
                ? null
                : Text(l10n.todoTaskCount(count.total)),
            onTap: () =>
                ref.read(selectedProjectIdProvider.notifier).state = project.id,
            trailing: MenuAnchor(
              menuChildren: [
                // Only offered while the branch has room, so the limit is
                // never explained after the fact.
                if (tree.canAddChild(project.id))
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.create_new_folder_outlined, size: 18),
                    onPressed: () async {
                      final name = await promptForName(
                        context,
                        title: l10n.todoNewSubproject,
                      );
                      if (name != null) {
                        await actions.createProject(name, parentId: project.id);
                      }
                    },
                    child: Text(l10n.todoNewSubproject),
                  ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () async {
                    final name = await promptForName(
                      context,
                      title: l10n.actionEdit,
                      initialValue: project.name,
                    );
                    if (name != null) {
                      await actions.updateProject(
                        project.id,
                        name: name,
                        parentId: project.parentId,
                      );
                    }
                  },
                  child: Text(l10n.actionEdit),
                ),
                MenuItemButton(
                  leadingIcon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () async {
                    if (await confirmDelete(context, project.name)) {
                      await actions.deleteProject(project.id);
                    }
                  },
                  child: Text(l10n.actionDelete),
                ),
              ],
              builder: (context, controller, _) => IconButton(
                icon: const Icon(Icons.more_vert, size: 18),
                onPressed: () =>
                    controller.isOpen ? controller.close() : controller.open(),
              ),
            ),
          ),
        ),
        for (final child in children)
          _Node(project: child, tree: tree, counts: counts, depth: depth + 1),
      ],
    );
  }
}
