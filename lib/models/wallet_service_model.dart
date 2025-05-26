import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// A service class to manage the wallet entity in the SQLite database.
class WalletService {
  static const _dbName = 'wallet.db';
  static const _tableName = 'wallet';
  static const _dbVersion = 1;

  /// Opens (and creates if necessary) the database.
  static Future<Database> _openDb() async {
    final path = p.join(await getDatabasesPath(), _dbName);
    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            passphrase TEXT,
            public TEXT,
            private TEXT
          )
        ''');
      },
    );
  }

  /// Retrieves the first saved wallet row as a map, or null if none saved.
  static Future<Map<String, dynamic>?> getWallet() async {
    final db = await _openDb();
    final rows = await db.query(_tableName, limit: 1);
    if (rows.isEmpty) return null;
    return rows.first;
  }

  /// Returns the private key, or null if not set.
  static Future<String?> getPrivateKey() async {
    final wallet = await getWallet();
    return wallet?['private'] as String?;
  }

  /// Returns the public address, or null if not set.
  static Future<String?> getPublicAddress() async {
    final wallet = await getWallet();
    return wallet?['public'] as String?;
  }

  /// Inserts or updates the wallet record with [publicAddress] and [privateKey].
  static Future<void> saveWallet({
    required String publicAddress,
    required String privateKey,
    String? passphrase,
  }) async {
    final db = await _openDb();
    final existing = await db.query(_tableName, limit: 1);
    final data = {
      'public': publicAddress,
      'private': privateKey,
      if (passphrase != null) 'passphrase': passphrase,
    };
    if (existing.isNotEmpty) {
      await db.update(_tableName, data);
    } else {
      await db.insert(_tableName, data);
    }
  }

  /// Clears all stored wallet data (for logout/reset).
  static Future<void> clearWallet() async {
    final db = await _openDb();
    await db.delete(_tableName);
  }
}
