import 'dart:async';
import 'dart:js_interop';
// `has` and `[]=`: reading a property off the window to see whether the
// browser has the API at all, and building the plain option objects these
// calls take. Both are ordinary JavaScript, and neither has a typed
// binding because neither has a fixed shape.
import 'dart:js_interop_unsafe';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:web/web.dart' as web;

import '../domain/auto_backup.dart';
import '../domain/backup_folder.dart';

/// A folder the user granted this origin, for the browser build.
///
/// The File System Access API is the only way a page may write a file the
/// user can find afterwards, rather than pushing it through the download
/// bar. What it hands back is a handle, not a path: the page never learns
/// where the folder is, only that it may write there — which is the trade
/// that makes the whole thing safe to offer.
///
/// The handle is kept in IndexedDB, because a handle is one of the few
/// objects a browser will store and hand back intact. It cannot go in
/// preferences, which hold strings.
///
/// Permission is a separate question from the handle, and asked every time:
/// a browser may have narrowed it to this session, and the user may have
/// revoked it from the address bar. Re-granting needs a click, so the copy
/// is not written silently on the next launch — it waits and says so.
class WebBackupFolder implements BackupFolder {
  const WebBackupFolder();

  static const _databaseName = 'nisabitus-backup-folder';
  static const _storeName = 'folder';
  static const _key = 'chosen';

  /// Safari and Firefox have no directory picker. Asked of the window
  /// rather than of the user agent string, which lies.
  @override
  bool get isSupported => _window.has('showDirectoryPicker');

  @override
  Future<String?> choose() async {
    if (!isSupported) return null;

    final JSObject? handle;
    try {
      handle = await _showDirectoryPicker(
        _options(mode: 'readwrite', startIn: 'documents'),
      ).toDart;
    } on Object {
      // The only way out of the picker is cancelling, which throws an
      // AbortError. Backing out is not a failure.
      return null;
    }
    if (handle == null) return null;

    await _remember(handle);
    return _nameOf(handle);
  }

  @override
  Future<String?> remembered() async {
    if (!isSupported) return null;

    final handle = await _stored();
    if (handle == null) return null;

    final state = await _permission(handle, ask: false);
    if (state == 'granted') return _nameOf(handle);
    if (state == 'denied') {
      throw const BackupFolderException(AutoBackupProblem.folderGone);
    }
    throw const BackupFolderException(AutoBackupProblem.needsPermission);
  }

  @override
  Future<void> write(String fileName, String contents) async {
    final handle = await _stored();
    if (handle == null) {
      throw const BackupFolderException(AutoBackupProblem.folderGone);
    }

    // Asked for here, not only queried: this runs from something the user
    // pressed, which is the moment a browser will allow the prompt.
    if (await _permission(handle, ask: true) != 'granted') {
      throw const BackupFolderException(AutoBackupProblem.needsPermission);
    }

    try {
      final directory = handle as _Directory;
      final file = await directory
          .getFileHandle(fileName, _options(create: true))
          .toDart;
      final sink = await file.createWritable().toDart;
      await sink.write(contents.toJS).toDart;
      await sink.close().toDart;
    } on BackupFolderException {
      rethrow;
    } on Object {
      throw const BackupFolderException(AutoBackupProblem.failed);
    }
  }

  @override
  Future<void> forget() async {
    final database = await _open();
    final store = database
        .transaction(_storeName.toJS, 'readwrite')
        .objectStore(_storeName);
    await _awaited(store.delete(_key.toJS));
    database.close();
  }

  // --- the handle, and where it is kept -----------------------------------

  Future<void> _remember(JSObject handle) async {
    final database = await _open();
    final store = database
        .transaction(_storeName.toJS, 'readwrite')
        .objectStore(_storeName);
    await _awaited(store.put(handle, _key.toJS));
    database.close();
  }

  Future<JSObject?> _stored() async {
    final database = await _open();
    final store = database
        .transaction(_storeName.toJS, 'readonly')
        .objectStore(_storeName);
    final value = await _awaited(store.get(_key.toJS));
    database.close();

    return value as JSObject?;
  }

  Future<web.IDBDatabase> _open() {
    final done = Completer<web.IDBDatabase>();
    final request = web.window.indexedDB.open(_databaseName, 1);

    request.onupgradeneeded = ((web.Event _) {
      (request.result as web.IDBDatabase).createObjectStore(_storeName);
    }).toJS;
    request.onsuccess = ((web.Event _) {
      done.complete(request.result as web.IDBDatabase);
    }).toJS;
    request.onerror = ((web.Event _) {
      done.completeError(const BackupFolderException(AutoBackupProblem.failed));
    }).toJS;

    return done.future;
  }

  Future<JSAny?> _awaited(web.IDBRequest request) {
    final done = Completer<JSAny?>();
    request.onsuccess = ((web.Event _) => done.complete(request.result)).toJS;
    request.onerror = ((web.Event _) {
      done.completeError(const BackupFolderException(AutoBackupProblem.failed));
    }).toJS;

    return done.future;
  }

  /// 'granted', 'prompt' or 'denied'.
  ///
  /// Both methods are part of the File System Access proposal rather than of
  /// any shipped standard library, so they are declared here by hand. A
  /// browser that has the picker has these too.
  Future<String> _permission(JSObject handle, {required bool ask}) async {
    final permissioned = handle as _Permissioned;
    final descriptor = _options(mode: 'readwrite');
    final result = ask
        ? await permissioned.requestPermission(descriptor).toDart
        : await permissioned.queryPermission(descriptor).toDart;

    return result.toDart;
  }

  String _nameOf(JSObject handle) => (handle as _Directory).name;

  static JSObject get _window => web.window as JSObject;

  /// A plain object literal, which is what every one of these APIs takes.
  static JSObject _options({String? mode, String? startIn, bool? create}) {
    final options = JSObject();
    if (mode != null) options['mode'] = mode.toJS;
    if (startIn != null) options['startIn'] = startIn.toJS;
    if (create != null) options['create'] = create.toJS;

    return options;
  }
}

/// The folder for this build. See `backup_folder_platform.dart`.
///
/// The preferences are not read here: a browser hands back a handle, not a
/// path, and a handle cannot be written to preferences.
BackupFolder backupFolderFor(SharedPreferences prefs) =>
    const WebBackupFolder();

@JS('window.showDirectoryPicker')
external JSPromise<JSObject?> _showDirectoryPicker(JSObject options);

extension type _Directory._(JSObject _) implements JSObject {
  external String get name;
  external JSPromise<_File> getFileHandle(String name, JSObject options);
}

extension type _File._(JSObject _) implements JSObject {
  external JSPromise<_Writable> createWritable();
}

extension type _Writable._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> write(JSAny data);
  external JSPromise<JSAny?> close();
}

extension type _Permissioned._(JSObject _) implements JSObject {
  external JSPromise<JSString> queryPermission(JSObject descriptor);
  external JSPromise<JSString> requestPermission(JSObject descriptor);
}
