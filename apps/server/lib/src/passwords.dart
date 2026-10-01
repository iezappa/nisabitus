import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const _iterations = 120000;
const _saltBytes = 16;
const _keyBytes = 32;

final _random = Random.secure();

String newSalt() {
  final bytes = List<int>.generate(_saltBytes, (_) => _random.nextInt(256));
  return base64UrlEncode(bytes);
}

String hashPassword(String password, String salt) {
  final saltBytes = base64Url.decode(salt);
  var digest = sha256.convert([...utf8.encode(password), ...saltBytes]).bytes;
  for (var i = 1; i < _iterations; i++) {
    digest = sha256.convert([
      ...digest,
      ...utf8.encode(password),
      ...saltBytes,
    ]).bytes;
  }
  return base64UrlEncode(digest.take(_keyBytes).toList());
}

bool verifyPassword(String password, String salt, String expectedHash) {
  final actual = hashPassword(password, salt);
  return _constantTimeEquals(actual, expectedHash);
}

bool _constantTimeEquals(String a, String b) {
  final aBytes = utf8.encode(a);
  final bBytes = utf8.encode(b);
  var diff = aBytes.length ^ bBytes.length;
  for (var i = 0; i < aBytes.length && i < bBytes.length; i++) {
    diff |= aBytes[i] ^ bBytes[i];
  }
  return diff == 0;
}
