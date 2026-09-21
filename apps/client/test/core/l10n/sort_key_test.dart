import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/core/l10n/sort_key.dart';

void main() {
  List<String> sorted(List<String> words) =>
      [...words]..sort((a, b) => sortKey(a).compareTo(sortKey(b)));

  test('an accent does not move a word to the end of the alphabet', () {
    // Dart compares by code point, so the accented letters live above `z`
    // and "Ávido" files after "zapallo" without this.
    expect(sorted(['zapallo', 'Ávido']), ['Ávido', 'zapallo']);
  });

  test('an accent files a word where its plain letter does', () {
    expect(sorted(['azul', 'árbol', 'bota']), ['árbol', 'azul', 'bota']);
  });

  test('case does not decide the order', () {
    expect(sorted(['banana', 'Ananá']), ['Ananá', 'banana']);
  });

  test('ñ is its own letter, after every n word', () {
    // Not folded to `n`: in Spanish it files between N and O.
    expect(sorted(['nube', 'ñandú', 'orden']), ['nube', 'ñandú', 'orden']);
  });

  test('a diaeresis folds like the plain vowel', () {
    expect(sorted(['pingüino', 'pingue']), ['pingue', 'pingüino']);
  });

  test('leaves alone what it does not know', () {
    expect(sortKey('Orden 2'), 'orden 2');
  });
}
