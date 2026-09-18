import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads Roboto and the icon font from the Flutter SDK, so the screenshots
/// carry real text,
/// measured the way a device measures it, and real icons rather than Ahem's boxes.
Future<void> loadRealFonts() async {
  final fonts = _materialFontsDirectory();
  if (fonts == null) {
    fail(
      'Could not find the SDK material_fonts directory. '
      'Set FLUTTER_ROOT, or run these through `flutter test`.',
    );
  }

  await _load(fonts, 'Roboto', const [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]);
  await _load(fonts, 'MaterialIcons', const ['MaterialIcons-Regular.otf']);
}

Future<void> _load(Directory fonts, String family, List<String> faces) async {
  final loader = FontLoader(family);
  for (final face in faces) {
    final file = File('${fonts.path}/$face');
    if (file.existsSync()) {
      loader.addFont(
        file.readAsBytes().then((bytes) => ByteData.sublistView(bytes)),
      );
    }
  }
  await loader.load();
}

/// The SDK's bundled fonts, looked up the two ways that work in a test run.
Directory? _materialFontsDirectory() {
  const relative = 'bin/cache/artifacts/material_fonts';

  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final fromEnvironment = Directory('$root/$relative');
    if (fromEnvironment.existsSync()) return fromEnvironment;
  }

  // The test runs inside flutter_tester, which lives under the same cache.
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.path != directory.parent.path) {
    final candidate = Directory('${directory.path}/$relative');
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  return null;
}
