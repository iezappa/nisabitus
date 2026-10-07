import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/database/database_provider.dart';
import '../data/drift_cheatsheet_repository.dart';
import '../data/picker_cheatsheet_files.dart';
import '../domain/cheatsheet_files.dart';
import '../domain/cheatsheet_note.dart';
import '../domain/cheatsheet_repository.dart';

final cheatsheetRepositoryProvider = Provider<CheatsheetRepository>(
  (ref) => DriftCheatsheetRepository(ref.watch(databaseProvider)),
);

final cheatsheetFilesProvider = Provider<CheatsheetFiles>(
  (ref) => const PickerCheatsheetFiles(),
);

final cheatsheetsRevisionProvider = StateProvider<int>((ref) => 0);

final cheatsheetSearchProvider = StateProvider<String>((ref) => '');

final cheatsheetsProvider = FutureProvider<List<CheatsheetNote>>((ref) async {
  ref.watch(cheatsheetsRevisionProvider);
  final query = ref.watch(cheatsheetSearchProvider).trim().toLowerCase();
  final notes = await ref.watch(cheatsheetRepositoryProvider).list();
  if (query.isEmpty) return notes;

  return [
    for (final note in notes)
      if (note.title.toLowerCase().contains(query) ||
          note.content.toLowerCase().contains(query) ||
          note.folder.toLowerCase().contains(query) ||
          (note.sourceName?.toLowerCase().contains(query) ?? false))
        note,
  ];
});

final cheatsheetMarkdownPreviewProvider = StateProvider<bool>((ref) => true);

final cheatsheetReadingProvider = StateProvider<String?>((ref) => null);

final cheatsheetSpeechSpeedProvider = StateProvider<double>((ref) => 1);

final cheatsheetTtsProvider = Provider<CheatsheetTts>((ref) {
  final tts = CheatsheetTts(FlutterTts());
  ref.onDispose(tts.stop);
  return tts;
});

final selectedCheatsheetIdProvider = StateProvider<String?>((ref) => null);

final cheatsheetEditingProvider = StateProvider<bool>((ref) => false);

final cheatsheetCreatingProvider = StateProvider<bool>((ref) => false);

final selectedCheatsheetProvider = FutureProvider<CheatsheetNote?>((ref) {
  ref.watch(cheatsheetsRevisionProvider);
  final id = ref.watch(selectedCheatsheetIdProvider);
  if (id == null) return Future.value();

  return ref.watch(cheatsheetRepositoryProvider).byId(id);
});

class CheatsheetActions {
  CheatsheetActions(this._ref);

  final Ref _ref;

  Future<int> importFiles() async {
    final imported = await CheatsheetImportAction(
      files: _ref.read(cheatsheetFilesProvider),
      repository: _ref.read(cheatsheetRepositoryProvider),
    ).importPicked();
    if (imported.isNotEmpty) {
      _refresh();
      _ref.read(selectedCheatsheetIdProvider.notifier).state =
          imported.first.id;
      _ref.read(cheatsheetCreatingProvider.notifier).state = false;
      _ref.read(cheatsheetEditingProvider.notifier).state = false;
    }
    return imported.length;
  }

  void startCreate() {
    _ref.read(selectedCheatsheetIdProvider.notifier).state = null;
    _ref.read(cheatsheetCreatingProvider.notifier).state = true;
    _ref.read(cheatsheetEditingProvider.notifier).state = true;
  }

  void startEdit() {
    _ref.read(cheatsheetCreatingProvider.notifier).state = false;
    _ref.read(cheatsheetEditingProvider.notifier).state = true;
  }

  void cancelEdit() {
    _ref.read(cheatsheetCreatingProvider.notifier).state = false;
    _ref.read(cheatsheetEditingProvider.notifier).state = false;
  }

  Future<void> save({
    required String title,
    required String content,
    required String folder,
    CheatsheetFormat format = CheatsheetFormat.markdown,
  }) async {
    final repository = _ref.read(cheatsheetRepositoryProvider);
    final draft = CheatsheetSaveDraft(
      title: title,
      content: content,
      folder: folder,
      format: format,
    );
    final selectedId = _ref.read(selectedCheatsheetIdProvider);
    final creating = _ref.read(cheatsheetCreatingProvider);
    final saved = creating || selectedId == null
        ? await repository.create(draft)
        : await repository.update(selectedId, draft);

    if (saved != null) {
      _ref.read(selectedCheatsheetIdProvider.notifier).state = saved.id;
    }
    _ref.read(cheatsheetCreatingProvider.notifier).state = false;
    _ref.read(cheatsheetEditingProvider.notifier).state = false;
    _refresh();
  }

  Future<void> deleteSelected() async {
    final selectedId = _ref.read(selectedCheatsheetIdProvider);
    if (selectedId == null) return;

    await _ref.read(cheatsheetRepositoryProvider).delete(selectedId);
    _ref.read(selectedCheatsheetIdProvider.notifier).state = null;
    _ref.read(cheatsheetCreatingProvider.notifier).state = false;
    _ref.read(cheatsheetEditingProvider.notifier).state = false;
    _refresh();
  }

  void _refresh() {
    _ref
        .read(cheatsheetsRevisionProvider.notifier)
        .update((value) => value + 1);
  }
}

final cheatsheetActionsProvider = Provider<CheatsheetActions>(
  CheatsheetActions.new,
);

class CheatsheetTts {
  CheatsheetTts(this._tts);

  final FlutterTts _tts;

  Future<void> speak({
    required String text,
    required String languageCode,
    required double speed,
    required VoidCallback onDone,
  }) async {
    await stop();
    _tts.setCompletionHandler(onDone);
    _tts.setCancelHandler(onDone);
    _tts.setErrorHandler((_) => onDone());
    final languagePrefix = languageCode == 'es' ? 'es' : 'en';
    final selectedLocale = await _selectVoice(languagePrefix);
    await _tts.setLanguage(
      selectedLocale ?? (languagePrefix == 'es' ? 'es' : 'en-US'),
    );
    await _tts.setSpeechRate(kIsWeb ? speed : (speed / 2).clamp(0.1, 1.0));
    await _tts.setPitch(1);
    await _tts.speak(text);
  }

  Future<String?> _selectVoice(String languagePrefix) async {
    final voices = await _voicesWithRetry();
    if (voices.isEmpty) return null;

    final lowerPrefix = languagePrefix.toLowerCase();
    final candidates = voices.where((voice) {
      final locale = voice['locale']?.toLowerCase() ?? '';
      return locale == lowerPrefix || locale.startsWith('$lowerPrefix-');
    }).toList();
    if (candidates.isEmpty) return null;

    final preferred = candidates.firstWhere((voice) {
      final name = voice['name']?.toLowerCase() ?? '';
      final locale = voice['locale']?.toLowerCase() ?? '';
      if (lowerPrefix == 'es') {
        return locale == 'es-es' ||
            name.contains('spanish') ||
            name.contains('español');
      }
      return locale == 'en-us' || name.contains('english');
    }, orElse: () => candidates.first);

    await _tts.setVoice(preferred);
    return preferred['locale'];
  }

  Future<List<Map<String, String>>> _voicesWithRetry() async {
    for (var attempt = 0; attempt < 3; attempt += 1) {
      final rawVoices = await _tts.getVoices;
      final voices = <Map<String, String>>[
        if (rawVoices is List)
          for (final voice in rawVoices.whereType<Map>())
            {
              for (final entry in voice.entries)
                entry.key.toString(): entry.value.toString(),
            },
      ];
      if (voices.isNotEmpty || !kIsWeb) return voices;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return const [];
  }

  Future<void> stop() => _tts.stop();
}
