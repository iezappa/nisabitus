import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/settings_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/domain/language_preference.dart';
import '../../settings/presentation/settings_providers.dart';
import '../domain/cheatsheet_note.dart';
import '../domain/markdown_speech.dart';
import 'cheatsheet_providers.dart';

class CheatsheetsScreen extends ConsumerWidget {
  const CheatsheetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final actions = ref.read(cheatsheetActionsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const SettingsButton(),
        title: Text(l10n.cheatsheetsTitle),
        actions: [
          IconButton(
            tooltip: l10n.cheatsheetsNewNote,
            icon: const Icon(Icons.post_add_outlined),
            onPressed: actions.startCreate,
          ),
          IconButton(
            tooltip: l10n.cheatsheetsImport,
            icon: const Icon(Icons.library_add_outlined),
            onPressed: actions.importFiles,
          ),
          const SizedBox(width: Gap.xs),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l10n.cheatsheetsNewNote,
        onPressed: actions.startCreate,
        child: const Icon(Icons.post_add_outlined),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 760;
          if (!wide) {
            return const Column(
              children: [
                Expanded(flex: 2, child: _CheatsheetBrowser()),
                Divider(height: 1),
                Expanded(flex: 3, child: _CheatsheetDetail()),
              ],
            );
          }

          return const Row(
            children: [
              Expanded(flex: 1, child: _CheatsheetBrowser()),
              VerticalDivider(width: 1),
              Expanded(flex: 2, child: _CheatsheetDetail()),
            ],
          );
        },
      ),
    );
  }
}

class _CheatsheetBrowser extends ConsumerStatefulWidget {
  const _CheatsheetBrowser();

  @override
  ConsumerState<_CheatsheetBrowser> createState() => _CheatsheetBrowserState();
}

class _CheatsheetBrowserState extends ConsumerState<_CheatsheetBrowser> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: ref.read(cheatsheetSearchProvider));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notes = ref.watch(cheatsheetsProvider);
    final query = ref.watch(cheatsheetSearchProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(Gap.md),
          child: TextField(
            controller: _search,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: l10n.actionClear,
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _search.clear();
                        ref.read(cheatsheetSearchProvider.notifier).state = '';
                      },
                    ),
              labelText: l10n.cheatsheetsSearch,
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) =>
                ref.read(cheatsheetSearchProvider.notifier).state = value,
          ),
        ),
        Expanded(
          child: notes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text(error.toString())),
            data: (items) => _CheatsheetTree(
              notes: items,
              searching: query.trim().isNotEmpty,
            ),
          ),
        ),
      ],
    );
  }
}

class _CheatsheetTree extends ConsumerWidget {
  const _CheatsheetTree({required this.notes, required this.searching});

  final List<CheatsheetNote> notes;
  final bool searching;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (notes.isEmpty) {
      return Center(
        child: EmptyState(
          icon: searching ? Icons.search_off_outlined : Icons.folder_open,
          title: searching ? l10n.cheatsheetsNoResults : l10n.cheatsheetsEmpty,
          hint: searching
              ? l10n.cheatsheetsNoResultsHint
              : l10n.cheatsheetsEmptyHint,
        ),
      );
    }

    final selectedId = ref.watch(selectedCheatsheetIdProvider);
    final byFolder = <String, List<CheatsheetNote>>{};
    for (final note in notes) {
      byFolder.putIfAbsent(note.folder, () => []).add(note);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(Gap.sm, 0, Gap.sm, Gap.xl * 4),
      children: [
        for (final entry in byFolder.entries)
          ExpansionTile(
            initiallyExpanded: true,
            leading: const Icon(Icons.folder_outlined),
            title: Text(entry.key),
            children: [
              for (final note in entry.value)
                ListTile(
                  selected: note.id == selectedId,
                  leading: Icon(
                    note.isImported
                        ? Icons.description_outlined
                        : Icons.edit_note_outlined,
                  ),
                  title: Text(note.title),
                  subtitle: Text(
                    note.sourceName ?? l10n.cheatsheetsCreatedInApp,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    ref.read(selectedCheatsheetIdProvider.notifier).state =
                        note.id;
                    ref.read(cheatsheetCreatingProvider.notifier).state = false;
                    ref.read(cheatsheetEditingProvider.notifier).state = false;
                  },
                ),
            ],
          ),
      ],
    );
  }
}

class _CheatsheetDetail extends ConsumerWidget {
  const _CheatsheetDetail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCheatsheetProvider);
    final creating = ref.watch(cheatsheetCreatingProvider);
    final editing = ref.watch(cheatsheetEditingProvider);

    if (creating || editing) {
      return selected.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (note) => _CheatsheetEditor(note: creating ? null : note),
      );
    }

    return selected.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (note) =>
          note == null ? const _NoSelection() : _CheatsheetViewer(note: note),
    );
  }
}

class _NoSelection extends StatelessWidget {
  const _NoSelection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: EmptyState(
        icon: Icons.menu_book_outlined,
        title: l10n.cheatsheetsDetailEmpty,
        hint: l10n.cheatsheetsDetailEmptyHint,
      ),
    );
  }
}

class _CheatsheetViewer extends ConsumerWidget {
  const _CheatsheetViewer({required this.note});

  final CheatsheetNote note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = Theme.of(context).colorScheme;
    final previewMarkdown = ref.watch(cheatsheetMarkdownPreviewProvider);
    final canPreviewMarkdown = note.format == CheatsheetFormat.markdown;
    final readingId = ref.watch(cheatsheetReadingProvider);
    final isReading = readingId == note.id;
    final speechSpeed = ref.watch(cheatsheetSpeechSpeedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: colors.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.lg, Gap.sm, Gap.sm, Gap.sm),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(note.title, style: textTheme.titleLarge),
                      Text(
                        '${note.folder} · ${note.sourceName ?? l10n.cheatsheetsCreatedInApp}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<double>(
                  tooltip: l10n.cheatsheetsSpeechSpeed,
                  icon: const Icon(Icons.speed_outlined),
                  initialValue: speechSpeed,
                  onSelected: (speed) =>
                      ref.read(cheatsheetSpeechSpeedProvider.notifier).state =
                          speed,
                  itemBuilder: (context) => [
                    for (final speed in const [0.75, 1.0, 1.5, 2.0])
                      PopupMenuItem(
                        value: speed,
                        child: Row(
                          children: [
                            if (speechSpeed == speed)
                              const Icon(Icons.check, size: 18)
                            else
                              const SizedBox(width: 18),
                            const SizedBox(width: Gap.sm),
                            Text(_speedLabel(speed)),
                          ],
                        ),
                      ),
                  ],
                ),
                IconButton(
                  tooltip: isReading
                      ? l10n.cheatsheetsStopReading
                      : l10n.cheatsheetsReadAloud,
                  icon: Icon(
                    isReading
                        ? Icons.stop_circle_outlined
                        : Icons.volume_up_outlined,
                  ),
                  onPressed: () => _toggleReadAloud(context, ref, isReading),
                ),
                if (canPreviewMarkdown)
                  IconButton(
                    tooltip: previewMarkdown
                        ? l10n.cheatsheetsShowPlainText
                        : l10n.cheatsheetsShowFormatted,
                    icon: Icon(
                      previewMarkdown
                          ? Icons.code_outlined
                          : Icons.article_outlined,
                    ),
                    onPressed: () =>
                        ref
                                .read(
                                  cheatsheetMarkdownPreviewProvider.notifier,
                                )
                                .state =
                            !previewMarkdown,
                  ),
                IconButton(
                  tooltip: l10n.cheatsheetsEdit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: ref.read(cheatsheetActionsProvider).startEdit,
                ),
                IconButton(
                  tooltip: l10n.actionDelete,
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context, ref),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Gap.lg),
            children: [
              if (canPreviewMarkdown && previewMarkdown)
                _MarkdownPreview(note.content)
              else
                SelectableText(note.content, style: textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _toggleReadAloud(
    BuildContext context,
    WidgetRef ref,
    bool isReading,
  ) async {
    final reading = ref.read(cheatsheetReadingProvider.notifier);
    final tts = ref.read(cheatsheetTtsProvider);
    if (isReading) {
      await tts.stop();
      reading.state = null;
      return;
    }

    final configuredLanguage = ref.read(languageChoiceProvider);
    final languageCode = switch (configuredLanguage) {
      LanguageChoice.spanish => 'es',
      LanguageChoice.english => 'en',
      LanguageChoice.system => Localizations.localeOf(context).languageCode,
    };

    reading.state = note.id;
    await tts.speak(
      text: speechTextFromMarkdown(note.content),
      languageCode: languageCode,
      speed: ref.read(cheatsheetSpeechSpeedProvider),
      onDone: () => reading.state = null,
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cheatsheetsDeleteTitle),
        content: Text(l10n.cheatsheetsDeleteMessage(note.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(cheatsheetActionsProvider).deleteSelected();
    }
  }
}

String _speedLabel(double speed) => switch (speed) {
  1.0 => '1x',
  _ => '${speed}x',
};

class _MarkdownPreview extends StatelessWidget {
  const _MarkdownPreview(this.markdown);

  final String markdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = markdown.split('\n');
    final widgets = <Widget>[];
    var inCode = false;
    final code = <String>[];

    void flushCode() {
      if (code.isEmpty) return;
      widgets.add(
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: Gap.sm),
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            code.join('\n'),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
        ),
      );
      code.clear();
    }

    for (final line in lines) {
      if (line.trim().startsWith('```')) {
        if (inCode) flushCode();
        inCode = !inCode;
        continue;
      }
      if (inCode) {
        code.add(line);
        continue;
      }

      final trimmed = line.trimRight();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: Gap.sm));
      } else if (trimmed.startsWith('# ')) {
        widgets.add(
          _MarkdownText(trimmed.substring(2), theme.textTheme.headlineSmall),
        );
      } else if (trimmed.startsWith('## ')) {
        widgets.add(
          _MarkdownText(trimmed.substring(3), theme.textTheme.titleLarge),
        );
      } else if (trimmed.startsWith('### ')) {
        widgets.add(
          _MarkdownText(trimmed.substring(4), theme.textTheme.titleMedium),
        );
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: Gap.sm, bottom: Gap.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(
                  child: _MarkdownText(
                    trimmed.substring(2),
                    theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(_MarkdownText(trimmed, theme.textTheme.bodyLarge));
      }
    }
    flushCode();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: widgets,
    );
  }
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText(this.text, this.style);

  final String text;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.xs),
      child: SelectableText(text, style: style),
    );
  }
}

class _CheatsheetEditor extends ConsumerStatefulWidget {
  const _CheatsheetEditor({required this.note});

  final CheatsheetNote? note;

  @override
  ConsumerState<_CheatsheetEditor> createState() => _CheatsheetEditorState();
}

class _CheatsheetEditorState extends ConsumerState<_CheatsheetEditor> {
  late final TextEditingController _title;
  late final TextEditingController _folder;
  late final TextEditingController _content;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.note?.title ?? '');
    _folder = TextEditingController(
      text: widget.note?.folder ?? CheatsheetFolders.appNotes,
    );
    _content = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _folder.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editingExisting = widget.note != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          child: Padding(
            padding: const EdgeInsets.all(Gap.md),
            child: Wrap(
              spacing: Gap.md,
              runSpacing: Gap.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  editingExisting
                      ? l10n.cheatsheetsEditNote
                      : l10n.cheatsheetsNewNote,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(l10n.actionSave),
                ),
                TextButton(
                  onPressed: ref.read(cheatsheetActionsProvider).cancelEdit,
                  child: Text(l10n.actionCancel),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(Gap.lg),
            children: [
              TextField(
                controller: _title,
                decoration: InputDecoration(
                  labelText: l10n.cheatsheetsTitleField,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Gap.md),
              TextField(
                controller: _folder,
                decoration: InputDecoration(
                  labelText: l10n.cheatsheetsFolderField,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: Gap.md),
              TextField(
                controller: _content,
                minLines: 14,
                maxLines: null,
                decoration: InputDecoration(
                  alignLabelWithHint: true,
                  labelText: l10n.cheatsheetsContentField,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() => ref
      .read(cheatsheetActionsProvider)
      .save(
        title: _title.text,
        folder: _folder.text,
        content: _content.text,
        format: widget.note?.format ?? CheatsheetFormat.markdown,
      );
}
