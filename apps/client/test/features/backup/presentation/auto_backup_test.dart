import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/database/app_database.dart';
import 'package:nisabitus/core/database/database_provider.dart';
import 'package:nisabitus/core/preferences/preferences.dart';
import 'package:nisabitus/core/time/clock.dart';
import 'package:nisabitus/features/backup/domain/auto_backup.dart';
import 'package:nisabitus/features/backup/domain/backup_folder.dart';
import 'package:nisabitus/features/backup/presentation/auto_backup_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A folder that keeps what it was handed, and can be made to fail.
class _FakeFolder implements BackupFolder {
  String? chosen = 'Documentos';
  AutoBackupProblem? broken;
  final written = <String, String>{};

  @override
  bool get isSupported => true;

  @override
  Future<String?> choose() async => chosen;

  @override
  Future<String?> remembered() async {
    if (broken case final problem?) throw BackupFolderException(problem);
    return chosen;
  }

  @override
  Future<void> write(String fileName, String contents) async {
    if (broken case final problem?) throw BackupFolderException(problem);
    written[fileName] = contents;
  }

  @override
  Future<void> forget() async => chosen = null;
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late _FakeFolder folder;
  var now = DateTime(2026, 9, 7, 9);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    folder = _FakeFolder();
    now = DateTime(2026, 9, 7, 9);
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
        backupFolderProvider.overrideWithValue(folder),
        clockProvider.overrideWithValue(() => now),
      ],
    );
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  AutoBackupActions actions() => container.read(autoBackupActionsProvider);
  AutoBackupHistory history() => container.read(autoBackupHistoryProvider);

  group('switching it on', () {
    test('asks for a folder and writes one straight away', () async {
      // Not a week from now: someone switching this on wants to know it
      // works while they are still looking at the screen.
      expect(await actions().chooseFolder(), isTrue);

      expect(folder.written.keys, ['nisabit-2026-09-07.json']);
      expect(history().folderLabel, 'Documentos');
      expect(history().lastRunAt, now);
    });

    test('changes nothing when the picker is backed out of', () async {
      folder.chosen = null;

      expect(await actions().chooseFolder(), isFalse);

      expect(container.read(autoBackupEnabledProvider), isFalse);
      expect(history().folderLabel, isNull);
      expect(folder.written, isEmpty);
    });

    test('forgets the folder when switched off, keeping the files', () async {
      await actions().chooseFolder();

      await actions().turnOff();

      expect(container.read(autoBackupEnabledProvider), isFalse);
      expect(history().folderLabel, isNull);
      expect(history().lastRunAt, isNull);
      expect(folder.written, isNotEmpty, reason: 'what was written stays');
    });
  });

  group('the week', () {
    test('writes nothing while it is not up', () async {
      await actions().chooseFolder();
      folder.written.clear();

      now = now.add(const Duration(days: 3));
      await actions().runIfDue();

      expect(folder.written, isEmpty);
    });

    test('writes one once it is', () async {
      await actions().chooseFolder();

      now = now.add(const Duration(days: 7));
      await actions().runIfDue();

      expect(folder.written.keys, contains('nisabit-2026-09-14.json'));
      expect(history().lastRunAt, now);
    });

    test('writes nothing at all while it is switched off', () async {
      now = now.add(const Duration(days: 30));

      await actions().runIfDue();

      expect(folder.written, isEmpty);
    });
  });

  group('when it cannot be written', () {
    test('says which problem it was, and does not throw', () async {
      await actions().chooseFolder();
      folder.broken = AutoBackupProblem.needsPermission;

      final result = await actions().runNow();

      expect(
        result,
        isA<AutoBackupBroken>().having(
          (state) => state.reason,
          'reason',
          AutoBackupProblem.needsPermission,
        ),
      );
    });

    test('leaves the last good copy\'s date alone', () async {
      await actions().chooseFolder();
      final good = history().lastRunAt;
      folder.broken = AutoBackupProblem.folderGone;

      now = now.add(const Duration(days: 7));
      await actions().runIfDue();

      // Otherwise a folder that has gone missing would quietly hold the
      // next attempt off for another week.
      expect(history().lastRunAt, good);
    });

    test('surfaces on the card rather than being retried in silence', () async {
      await actions().chooseFolder();
      folder.broken = AutoBackupProblem.folderGone;

      expect(
        await container.read(autoBackupStateProvider.future),
        isA<AutoBackupBroken>(),
      );
    });
  });

  test('is silent about a copy that was never asked for', () async {
    // The banner reads this: nothing was promised, so nothing is broken.
    now = now.add(const Duration(days: 30));
    await actions().runIfDue();

    expect(
      await container.read(autoBackupStateProvider.future),
      isA<AutoBackupOff>(),
    );
  });

  test('says it is off before a folder has been chosen', () async {
    expect(
      await container.read(autoBackupStateProvider.future),
      isA<AutoBackupOff>(),
    );
  });

  test('writes a file that restores', () async {
    // The copy is the same document the export button produces, so what
    // lands in the folder is something Import can read.
    await db.into(db.projects).insert(ProjectsCompanion.insert(name: 'Casa'));
    await actions().chooseFolder();

    expect(folder.written.values.single, contains('"name":"Casa"'));
  });
}
