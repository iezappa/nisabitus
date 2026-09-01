import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/release_notes/data/asset_release_notes.dart';

void main() {
  String changelog(String highlight) => jsonEncode({
    'releases': [
      {
        'version': '1.0.0',
        'date': '2026-08-30',
        'highlights': [highlight],
      },
    ],
  });

  final bundle = _FakeBundle({
    'assets/release_notes/es.json': changelog('Novedad'),
    'assets/release_notes/en.json': changelog('Something new'),
  });

  test('reads the file of the language asked for', () async {
    final notes = await AssetReleaseNotes(bundle).load('en');

    expect(notes.all.single.highlights.single, 'Something new');
  });

  test(
    'falls back to the template language for one it does not ship',
    () async {
      final notes = await AssetReleaseNotes(bundle).load('fr');

      expect(notes.all.single.highlights.single, 'Novedad');
    },
  );
}

class _FakeBundle extends CachingAssetBundle {
  _FakeBundle(this._files);

  final Map<String, String> _files;

  @override
  Future<ByteData> load(String key) async {
    final file = _files[key];
    if (file == null) throw StateError('Asset not found: $key');

    return ByteData.sublistView(Uint8List.fromList(utf8.encode(file)));
  }
}
