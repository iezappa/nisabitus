import 'dart:math';

final _random = Random.secure();

/// A random (version 4) UUID, as lower-case text.
///
/// Every record is identified by one of these rather than by an
/// autoincrement number (STACK-APPS-DINAMICAS.md 1.1): two devices can create
/// records independently without ever handing out the same id, which is what
/// a later sync needs and what merging two backups would need today.
String newUuid() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant

  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
      '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
      '${hex.sublist(10).join()}';
}

final _uuidShape = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);

bool isUuid(String value) => _uuidShape.hasMatch(value);
