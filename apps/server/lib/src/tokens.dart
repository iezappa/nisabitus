import 'dart:math';

const _alphabet =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_';
final _random = Random.secure();

String newToken({int length = 48}) => String.fromCharCodes(
  List<int>.generate(
    length,
    (_) => _alphabet.codeUnitAt(_random.nextInt(_alphabet.length)),
  ),
);
