@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/backup/data/backup_folder_io.dart';
import 'package:nisabitus/features/backup/domain/auto_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory folder;
  late SharedPreferences prefs;
  late IoBackupFolder target;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    folder = await Directory.systemTemp.createTemp('nisabitus-backup');
    await prefs.setString(IoBackupFolder.pathKey, folder.path);
    target = IoBackupFolder(prefs);
  });
  tearDown(() {
    if (folder.existsSync()) folder.deleteSync(recursive: true);
  });

  test('writes the copy into the folder it was given', () async {
    await target.write('nisabit-2026-09-07.json', '{"ok":true}');

    final file = File(
      '${folder.path}${Platform.pathSeparator}'
      'nisabit-2026-09-07.json',
    );
    expect(file.existsSync(), isTrue);
    expect(file.readAsStringSync(), '{"ok":true}');
  });

  test('replaces last week\'s copy of the same name', () async {
    await target.write('copy.json', 'old');
    await target.write('copy.json', 'new');

    expect(
      File('${folder.path}${Platform.pathSeparator}copy.json')
          .readAsStringSync(),
      'new',
    );
  });

  test('leaves nothing half written behind', () async {
    // Written beside its name and moved into place, so an interrupted copy
    // cannot wear the name of a good one. What is left is the file itself,
    // and nothing else.
    await target.write('copy.json', '{}');

    expect(
      folder.listSync().map(
        (entry) => entry.path.split(Platform.pathSeparator).last,
      ),
      ['copy.json'],
    );
  });

  test('says the folder is gone rather than throwing at the caller', () async {
    folder.deleteSync(recursive: true);

    expect(
      () => target.write('copy.json', '{}'),
      throwsA(
        isA<BackupFolderException>().having(
          (error) => error.problem,
          'problem',
          AutoBackupProblem.folderGone,
        ),
      ),
    );
  });

  test('remembers nothing when nothing was ever chosen', () async {
    SharedPreferences.setMockInitialValues({});
    final empty = IoBackupFolder(await SharedPreferences.getInstance());

    expect(await empty.remembered(), isNull);
  });

  test('tells a chosen folder that is gone from one never chosen', () async {
    folder.deleteSync(recursive: true);

    // Different answers: one is a feature switched off, the other is a
    // promise being broken.
    expect(target.remembered(), throwsA(isA<BackupFolderException>()));
  });

  test('forgets the folder without touching what is in it', () async {
    await target.write('copy.json', '{}');

    await target.forget();

    expect(await target.remembered(), isNull);
    expect(
      File('${folder.path}${Platform.pathSeparator}copy.json').existsSync(),
      isTrue,
    );
  });
}
