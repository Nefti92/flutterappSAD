import 'dart:io';
import 'package:cdapp/models/call_result_model.dart';
import 'package:cdapp/models/contract_event_model.dart';
import 'package:cdapp/models/contract_function_model.dart';
import 'package:cdapp/models/event_parameter_model.dart';
import 'package:cdapp/models/function_parameter_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:cdapp/models/contract_model.dart';

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
          CREATE TABLE user_pattern (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pattern_hash TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
        ''');
        
        await db.execute('''
          CREATE TABLE contracts (
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
            contract_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            is_view INTEGER NOT NULL DEFAULT 1,
            state_mutability TEXT NOT NULL DEFAULT 'view',
            payable INTEGER NOT NULL DEFAULT 0,
            FOREIGN KEY(contract_id) REFERENCES contracts(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE function_parameters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            function_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            output BOOLEAN NOT NULL,
            FOREIGN KEY(function_id) REFERENCES contract_functions(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE call_results (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            function_id INTEGER NOT NULL,
            contract_address TEXT NOT NULL,
            function_name TEXT NOT NULL,
            result TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            FOREIGN KEY(function_id) REFERENCES contract_functions(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE contract_events (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            contract_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            abi TEXT NOT NULL,
            anonymous BOOLEAN NOT NULL,
            subscribed BOOLEAN NOT NULL,
            FOREIGN KEY(contract_id) REFERENCES contracts(id) ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE event_parameters (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            event_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            indexed INTEGER NOT NULL,
            FOREIGN KEY(event_id) REFERENCES contract_events(id) ON DELETE CASCADE
          )
        ''');

      },
    );
    return _db!;

  }

  // Contract Section

  static Future<void> insertContract(Contract service) async {
    final db = await database;
    await db.insert(
      'contracts',
      service.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateContract(Contract contract) async {
    final db = await database;
    await db.update(
      'contracts',
      {
        'title': contract.title,
        'address': contract.address,
        'description': contract.description,
        'ip': contract.ip,
        'port': contract.port,
        'chainID': contract.chainID,
        'icon': contract.icon,
        'lastAccess': contract.lastAccess.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [contract.id],
    );
  }

  static Future<List<Contract>> getAllContracts() async {
    final db = await database;
    final List<Map<String, dynamic>> maps =
        await db.query('contracts', orderBy: 'lastAccess DESC');
    return maps.map((map) => Contract.fromMap(map)).toList();
  }

  static Future<Contract?> getContractById(int serviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contracts',
      where: 'id = ?',
      whereArgs: [serviceId],
    );
    if (maps.isNotEmpty) {
      return Contract.fromMap(maps.first);
    }
    return null;
  }

  
  // Function Section

  static Future<int> insertFunction(SCFunction func) async {
    final db = await database;
    return await db.insert('contract_functions', func.toMap());
  }

  static Future<List<SCFunction>> getFunctionsForContract(int serviceId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'contract_functions',
      where: 'contract_id = ?',
      whereArgs: [serviceId],
    );
    return maps.map((map) => SCFunction.fromMap(map)).toList();
  }

  static Future<void> updateFunction(SCFunction func) async {
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

  static Future<List<FuncParameter>> getParametersForFunction(int functionId) async {
  final db = await database;
  final maps = await db.query(
    'function_parameters',
    where: 'function_id = ?',
    whereArgs: [functionId],
  );
    return maps.map((e) => FuncParameter.fromMap(e)).toList();
  }

  static Future<void> insertParameter(FuncParameter param) async {
    final db = await database;
    await db.insert('function_parameters', param.toMap());
  }

  static Future<void> updateParameter(FuncParameter param) async {
    final db = await database;
    await db.update('function_parameters', param.toMap(),
        where: 'id = ?', whereArgs: [param.id]);
  }

  static Future<void> deleteParameter(int id) async {
    final db = await database;
    await db.delete('function_parameters', where: 'id = ?', whereArgs: [id]);
  }

  // Call Result Section

  static Future<int> insertCallResult(CallResult result) async {
    final db = await database;
    return await db.insert('call_results', result.toMap());
  }

  static Future<List<CallResult>> getResultsForFunction(int functionId) async {
    final db = await database;
    final maps = await db.query(
      'call_results',
      where: 'function_id = ?',
      whereArgs: [functionId],
      orderBy: 'timestamp DESC',
    );
    return maps.map((m) => CallResult.fromMap(m)).toList();
  }

  static Future<List<CallResult>> getResultsForContract(int serviceId) async {
    final db = await database;
    const query = '''
      SELECT cr.* FROM call_results cr
      JOIN contract_functions cf ON cf.id = cr.function_id
      WHERE cf.contract_id = ?
      ORDER BY cr.timestamp DESC
    ''';
    final maps = await db.rawQuery(query, [serviceId]);
    return maps.map((m) => CallResult.fromMap(m)).toList();
  }

  static Future<List<CallResult>> getAllCallResultsSorted() async {
    final db = await database;
    final results = await db.query(
      'call_results',
      orderBy: 'timestamp DESC',
    );
    return results.map((e) => CallResult.fromMap(e)).toList();
  }

  static Future<void> deleteCallResult(int id) async {
    final db = await database;
    await db.delete('call_results', where: 'id = ?', whereArgs: [id]);
  }
  

  // Events Section

  static Future<int> insertEvent(SCEvent event) async {
    final db = await database;
    return await db.insert('contract_events', event.toMap());
  }

  static Future<List<SCEvent>> getEventsForContract(int contractId) async {
    final db = await database;
    final maps = await db.query(
      'contract_events',
      where: 'contract_id = ?',
      whereArgs: [contractId],
    );
    return maps.map((map) => SCEvent.fromMap(map)).toList();
  }

  static Future<void> updateEvent(SCEvent event) async {
    final db = await database;
    await db.update(
      'contract_events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  static Future<void> deleteEvent(int id) async {
    final db = await database;
    await db.delete('contract_events', where: 'id = ?', whereArgs: [id]);
  }

  // Events Parameter Section
  
  static Future<void> insertEventParameter(EventParameter param) async {
    final db = await database;
    await db.insert('event_parameters', param.toMap());
  }

  static Future<List<EventParameter>> getParametersForEvent(int eventId) async {
    final db = await database;
    final maps = await db.query(
      'event_parameters',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
    return maps.map((m) => EventParameter.fromMap(m)).toList();
  }

  static Future<void> updateEventParameter(EventParameter param) async {
    final db = await database;
    await db.update('event_parameters', param.toMap(),
        where: 'id = ?', whereArgs: [param.id]);
  }

  static Future<void> deleteEventParameter(int id) async {
    final db = await database;
    await db.delete(
      'event_parameters',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<List<SCEvent>> getSubscribedEvents() async {
    final db = await database;
    final maps = await db.query(
      'contract_events',
      where: 'subscribed = ?',
      whereArgs: [1],
    );
    return maps.map((map) => SCEvent.fromMap(map)).toList();
  }


}
