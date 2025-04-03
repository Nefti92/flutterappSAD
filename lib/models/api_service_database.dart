import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cdapp/models/api_service_model.dart';
import 'package:cdapp/models/api_response_model.dart';

class ApiDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    Directory dir = await getApplicationDocumentsDirectory();
    String path = '${dir.path}/apis.db';

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE api_services (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            icon TEXT,
            ip TEXT,
            port INTEGER,
            lastAccess TEXT
          )
        ''');

        await db.execute('''
          CREATE TABLE api_responses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service_id INTEGER,
            uri TEXT,
            type TEXT,
            response TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  static Future<void> insertService(ApiService service) async {
    final db = await database;
    await db.insert(
      'api_services',
      service.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<ApiService>> getAllServices() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('api_services', orderBy: 'lastAccess DESC');
    return maps.map((map) => ApiService.fromMap(map)).toList();
  }

  static Future<void> insertResponseModel(ApiResponse response) async {
    final db = await database;
    await db.insert(
      'api_responses',
      response.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }


  static Future<List<Map<String, dynamic>>> getResponsesForService(int serviceId) async {
    final db = await database;
    return db.query(
      'api_responses',
      where: 'service_id = ?',
      whereArgs: [serviceId],
      orderBy: 'timestamp DESC',
    );
  }
}
