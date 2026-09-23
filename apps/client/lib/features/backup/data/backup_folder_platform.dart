// The folder this build can keep: a real path off the web, a handle the
// user granted on it.
//
// The two implementations have nothing in common but the port. One needs
// `dart:io` and cannot be compiled for a browser; the other needs
// `dart:js_interop` and cannot be compiled anywhere else.
export 'backup_folder_io.dart'
    if (dart.library.js_interop) 'backup_folder_web.dart';
