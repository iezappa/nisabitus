import 'package:flutter_test/flutter_test.dart';
import 'package:nisabitus/features/backup/domain/csv_report.dart';

void main() {
  const bom = '﻿';

  test('writes one section per table: its name, a header and the rows', () {
    final csv = encodeCsvReport({
      'habits': [
        {'id': 1, 'name': 'Meditar'},
        {'id': 2, 'name': 'Leer'},
      ],
      'sleep_logs': [
        {'id': 1, 'hours': 7.5},
      ],
    });

    expect(
      csv,
      '${bom}habits\r\n'
      'id,name\r\n'
      '1,Meditar\r\n'
      '2,Leer\r\n'
      '\r\n'
      'sleep_logs\r\n'
      'id,hours\r\n'
      '1,7.5\r\n',
    );
  });

  test('skips tables with no rows', () {
    expect(
      encodeCsvReport({
        'empty': [],
        'habits': [
          {'id': 1},
        ],
      }),
      '${bom}habits\r\nid\r\n1\r\n',
    );
  });

  test('quotes commas, quotes and line breaks', () {
    final csv = encodeCsvReport({
      't': [
        {'note': 'uno, dos', 'quote': 'dijo "hola"', 'lines': 'a\nb'},
      ],
    });

    expect(csv, contains('"uno, dos","dijo ""hola""","a\nb"'));
  });

  test('writes null as an empty cell and booleans as words', () {
    final csv = encodeCsvReport({
      't': [
        {'a': null, 'b': true},
      ],
    });

    expect(csv, endsWith('a,b\r\n,true\r\n'));
  });

  test('defuses cells a spreadsheet would run as a formula', () {
    final csv = encodeCsvReport({
      't': [
        {'a': '=SUM(A1)', 'b': '+54 11', 'c': '-3', 'd': '@x'},
      ],
    });

    expect(csv, endsWith("'=SUM(A1),'+54 11,'-3,'@x\r\n"));
  });

  // Spreadsheets drop a leading tab or carriage return before deciding
  // whether a cell is a formula, so "\t=SUM(A1)" runs like "=SUM(A1)".
  test('defuses a formula hidden behind a leading tab or carriage return', () {
    final csv = encodeCsvReport({
      't': [
        {'a': '\t=SUM(A1)', 'b': '\r=SUM(A1)'},
      ],
    });

    expect(csv, endsWith('\'\t=SUM(A1),"\'\r=SUM(A1)"\r\n'));
  });

  test('uses every column that appears in any row, in first-seen order', () {
    final csv = encodeCsvReport({
      't': [
        {'a': 1},
        {'a': 2, 'b': 3},
      ],
    });

    expect(csv, endsWith('a,b\r\n1,\r\n2,3\r\n'));
  });
}
