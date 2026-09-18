/// Renders tables as one CSV file a person can open in a spreadsheet.
///
/// One file with a section per table rather than one file per table: the
/// save dialog is a single step on every platform, including the web, where
/// several downloads or a zip would each need another dependency. Each
/// section is the table name on its own line, a header row, the rows, and a
/// blank line.
///
/// This is a reading copy, not a backup. It cannot be imported: the JSON
/// export is the file that restores.
///
/// RFC 4180 quoting with CRLF line ends, and a UTF-8 byte order mark so
/// spreadsheet software reads "Ñoquis" as written. A cell that starts with
/// `=`, `+`, `-`, `@`, a tab or a carriage return is prefixed with `'`, so a
/// note cannot run as a formula when the file is opened (spreadsheets skip a
/// leading tab or CR before deciding, so those hide a formula too).
String encodeCsvReport(Map<String, List<Map<String, Object?>>> tables) {
  final sections = <String>[];

  for (final MapEntry(key: name, value: rows) in tables.entries) {
    if (rows.isEmpty) continue;

    final columns = <String>{for (final row in rows) ...row.keys}.toList();
    final lines = [
      _cell(name),
      columns.map(_cell).join(','),
      for (final row in rows) columns.map((c) => _cell(row[c])).join(','),
    ];
    sections.add('${lines.join('\r\n')}\r\n');
  }

  return '﻿${sections.join('\r\n')}';
}

String _cell(Object? value) {
  if (value == null) return '';
  var text = '$value';
  if (value is String && text.isNotEmpty && '=+-@\t\r'.contains(text[0])) {
    text = "'$text";
  }
  if (text.contains(RegExp('[",\r\n]'))) {
    return '"${text.replaceAll('"', '""')}"';
  }
  return text;
}
