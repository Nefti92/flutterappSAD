import 'dart:io';
import 'package:cdapp/models/contract_function_model.dart';
import 'package:cdapp/models/function_parameter_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cdapp/models/api_service_model.dart';

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
            address TEXT,
            title TEXT,
            description TEXT,
            icon TEXT,
            ip TEXT,
            port INTEGER,
            chainID INTEGER,
            lastAccess TEXT
          )
        ''');

        await db.execute('''
        CREATE TABLE contract_functions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            FOREIGN KEY(service_id) REFERENCES api_services(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE function_parameters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            function_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            FOREIGN KEY(function_id) REFERENCES contract_functions(id) ON DELETE CASCADE
          )
        ''');

      },
    );
    return _db!;
  }

  // Service Section

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


  static Future<List<Map<String, dynamic>>> getResponsesForService(int serviceId) async {
    final db = await database;
    return db.query(
      'api_responses',
      where: 'service_id = ?',
      whereArgs: [serviceId],
      orderBy: 'timestamp DESC',
    );
  }
  
  // Function Section

  static Future<int> insertFunction(ContractFunction func) async {
    final db = await database;
    return await db.insert('contract_functions', func.toMap());
  }

  static Future<List<ContractFunction>> getFunctionsForService(int serviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contract_functions',
      where: 'service_id = ?',
      whereArgs: [serviceId],
    );
    return maps.map((map) => ContractFunction.fromMap(map)).toList();
  }

  static Future<void> updateFunction(ContractFunction func) async {
    final db = await database;
    await db.update(
      'contract_functions',
      func.toMap(),
      where: 'id = ?',
      whereArgs: [func.id],
    );
  }

  static Future<void> deleteFunction(int id) async {
    final db = await database;
    await db.delete('contract_functions', where: 'id = ?', whereArgs: [id]);
  }

  // Parameter Section

  static Future<List<FunctionParameter>> getParametersForFunction(int functionId) async {
  final db = await database;
  final maps = await db.query(
    'function_parameters',
    where: 'function_id = ?',
    whereArgs: [functionId],
  );
    return maps.map((e) => FunctionParameter.fromMap(e)).toList();
  }

  static Future<void> insertParameter(FunctionParameter param) async {
    final db = await database;
    await db.insert('function_parameters', param.toMap());
  }

  static Future<void> updateParameter(FunctionParameter param) async {
    final db = await database;
    await db.update('function_parameters', param.toMap(),
        where: 'id = ?', whereArgs: [param.id]);
  }

  static Future<void> deleteParameter(int id) async {
    final db = await database;
    await db.delete('function_parameters', where: 'id = ?', whereArgs: [id]);
  }


}
