/// A key for sorting Spanish words the way a Spanish reader expects.
///
/// Dart compares strings by code point, so "Ávido" lands after "zapallo" and
/// "Ñandú" after every other word there is: the accented letters live above
/// `z` in Unicode. A list short enough to read is a list where that is
/// immediately, obviously wrong.
///
/// Accents are dropped for the comparison, because in Spanish they do not
/// change where a word files — "árbol" sorts under A. Ñ does change it: it is
/// its own letter, and it comes after every N word. It is mapped to `n~` so
/// it sorts after any `n` followed by a letter, and before `o`.
///
/// The folding only decides order. Nothing is stored folded and nothing is
/// shown folded — the word the user typed is the word that appears.
String sortKey(String value) {
  final buffer = StringBuffer();

  for (final rune in value.toLowerCase().runes) {
    buffer.write(
      _folded[String.fromCharCode(rune)] ?? String.fromCharCode(rune),
    );
  }

  return buffer.toString();
}

/// Only the letters Spanish actually uses. A table that tried to cover every
/// script would be a table nobody could check.
const _folded = <String, String>{
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ú': 'u',
  'ü': 'u',
  'ñ': 'n~',
};
