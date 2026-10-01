import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import 'passwords.dart';
import 'tokens.dart';

class UserRecord {
  const UserRecord({required this.id, required this.username});

  final String id;
  final String username;
}

class ImportResult {
  const ImportResult({required this.rowCount, required this.updatedAt});

  final int rowCount;
  final DateTime updatedAt;
}

class ServerDatabase {
  ServerDatabase(String dataDir)
    : _db = sqlite3.open(p.join(dataDir, 'nisabitus-server.db')) {
    _migrate();
  }

  final Database _db;

  void close() => _db.dispose();

  void _migrate() {
    _db.execute('PRAGMA foreign_keys = ON');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        salt TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS sessions (
        token TEXT PRIMARY KEY,
        user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        created_at INTEGER NOT NULL,
        expires_at INTEGER NOT NULL
      )
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS user_documents (
        user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
        document_json TEXT NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }

  bool get hasUsers {
    final result = _db.select('SELECT COUNT(*) AS count FROM users');
    return (result.first['count'] as int) > 0;
  }

  UserRecord createUser({required String username, required String password}) {
    final trimmed = username.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(username, 'username');
    if (password.length < 8) {
      throw ArgumentError.value(
        password,
        'password',
        'must be at least 8 characters',
      );
    }

    final id = newToken(length: 24);
    final salt = newSalt();
    final hash = hashPassword(password, salt);
    _db.execute(
      'INSERT INTO users (id, username, password_hash, salt, created_at) VALUES (?, ?, ?, ?, ?)',
      [id, trimmed, hash, salt, _nowMillis()],
    );
    return UserRecord(id: id, username: trimmed);
  }

  void ensureBootstrapUser({
    required String username,
    required String password,
  }) {
    if (hasUsers) return;
    createUser(username: username, password: password);
  }

  String? login({required String username, required String password}) {
    final rows = _db.select(
      'SELECT id, password_hash, salt FROM users WHERE username = ?',
      [username.trim()],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    if (!verifyPassword(
      password,
      row['salt'] as String,
      row['password_hash'] as String,
    )) {
      return null;
    }

    final token = newToken();
    final now = _nowMillis();
    final expires = now + const Duration(days: 30).inMilliseconds;
    _db.execute(
      'INSERT INTO sessions (token, user_id, created_at, expires_at) VALUES (?, ?, ?, ?)',
      [token, row['id'] as String, now, expires],
    );
    return token;
  }

  void logout(String token) {
    _db.execute('DELETE FROM sessions WHERE token = ?', [token]);
  }

  UserRecord? userForToken(String token) {
    final now = _nowMillis();
    _db.execute('DELETE FROM sessions WHERE expires_at <= ?', [now]);
    final rows = _db.select(
      '''
      SELECT users.id, users.username
      FROM sessions
      JOIN users ON users.id = sessions.user_id
      WHERE sessions.token = ? AND sessions.expires_at > ?
    ''',
      [token, now],
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return UserRecord(
      id: row['id'] as String,
      username: row['username'] as String,
    );
  }

  String exportDocument(String userId) {
    final rows = _db.select(
      'SELECT document_json FROM user_documents WHERE user_id = ?',
      [userId],
    );
    if (rows.isNotEmpty) return rows.first['document_json'] as String;

    return jsonEncode({
      'app': 'nisabitus',
      'format': 2,
      'schemaVersion': 0,
      'exportedAt': DateTime.now().millisecondsSinceEpoch,
      'tables': <String, List<Object?>>{},
    });
  }

  ImportResult importDocument(String userId, Map<String, Object?> document) {
    final normalized = _validateDocument(document);
    final rowCount = _rowCount(normalized['tables'] as Map<String, Object?>);
    final encoded = jsonEncode(normalized);
    final now = _nowMillis();
    _db.execute(
      '''
      INSERT INTO user_documents (user_id, document_json, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(user_id) DO UPDATE SET
        document_json = excluded.document_json,
        updated_at = excluded.updated_at
    ''',
      [userId, encoded, now],
    );
    return ImportResult(
      rowCount: rowCount,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(now),
    );
  }

  int _rowCount(Map<String, Object?> tables) {
    var count = 0;
    for (final value in tables.values) {
      if (value is List) count += value.length;
    }
    return count;
  }

  Map<String, Object?> _validateDocument(Map<String, Object?> document) {
    if (document['app'] != 'nisabitus' && document['app'] != 'nisabit') {
      throw const FormatException('document does not belong to Nisabitus');
    }
    final format = document['format'];
    if (format is! int || format > 2) {
      throw const FormatException('unsupported backup format');
    }
    final schemaVersion = document['schemaVersion'];
    if (schemaVersion is! int) {
      throw const FormatException('missing schemaVersion');
    }
    final exportedAt = document['exportedAt'];
    if (exportedAt is! int) {
      throw const FormatException('missing exportedAt');
    }
    final tables = document['tables'];
    if (tables is! Map) throw const FormatException('missing tables');

    final normalizedTables = <String, Object?>{};
    for (final entry in tables.entries) {
      if (entry.key is! String || entry.value is! List) {
        throw const FormatException('invalid table payload');
      }
      normalizedTables[entry.key as String] = entry.value;
    }

    return {
      'app': 'nisabitus',
      'format': format,
      'schemaVersion': schemaVersion,
      'exportedAt': exportedAt,
      'tables': normalizedTables,
    };
  }

  int _nowMillis() => DateTime.now().millisecondsSinceEpoch;
}
