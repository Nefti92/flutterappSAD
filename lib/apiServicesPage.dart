import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'baseScaffold.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class ApiService {
  final int? id;
  final String title;
  final String description;
  final String icon;
  final String ip;
  final int port;
  final DateTime lastAccess;

  ApiService({
    this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.ip,
    required this.port,
    required this.lastAccess,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'icon': icon,
      'ip': ip,
      'port': port,
      'lastAccess': lastAccess.toIso8601String(),
    };
  }

  static ApiService fromMap(Map<String, dynamic> map) {
    return ApiService(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      icon: map['icon'],
      ip: map['ip'],
      port: map['port'],
      lastAccess: DateTime.parse(map['lastAccess']),
    );
  }
}

class ApiDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    Directory dir = await getApplicationDocumentsDirectory();
    String path = '${dir.path}apis.db';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute('''
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
      },
    );
    return _db!;
  }

  static Future<void> insert(ApiService service) async {
    final db = await database;
    await db.insert('api_services', service.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<List<ApiService>> getAll() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('api_services', orderBy: 'lastAccess DESC');
    return maps.map((map) => ApiService.fromMap(map)).toList();
  }
}


class ApiServicesPage extends StatefulWidget {
  const ApiServicesPage({super.key});

  @override
  State<ApiServicesPage> createState() => _ApiServicesPageState();
}

class _ApiServicesPageState extends State<ApiServicesPage> {
  List<ApiService> services = [];
  final _searchController = TextEditingController();
  String query = '';

  final List<IconData> availableIcons = [
    Icons.cloud,
    Icons.http,
    Icons.api,
    Icons.bolt,
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices() async {
    final data = await ApiDatabase.getAll();
    setState(() {
      services = data;
    });
  }

  void _showAddDialog() {
  final titleController = TextEditingController();
  final descController = TextEditingController();
  final ipController = TextEditingController();
  final portController = TextEditingController();
  IconData? selectedIcon;
    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            title: const Text('Create API Service'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                  TextField(controller: ipController, decoration: const InputDecoration(labelText: 'IP Address')),
                  TextField(controller: portController, decoration: const InputDecoration(labelText: 'Port'), keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    children: availableIcons.map((icon) {
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = icon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: selectedIcon == icon ? Colors.deepOrange : Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: selectedIcon == icon ? Colors.deepOrange.withOpacity(0.1) : null,
                          ),
                          child: Icon(icon, size: 30),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedIcon != null) {
                    final newService = ApiService(
                      title: titleController.text,
                      description: descController.text,
                      ip: ipController.text,
                      port: int.tryParse(portController.text) ?? 0,
                      icon: selectedIcon!.codePoint.toString(),
                      lastAccess: DateTime.now(),
                    );
                    await ApiDatabase.insert(newService);
                    _loadServices();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final filtered = services.where((s) =>
      s.title.toLowerCase().contains(query.toLowerCase()) ||
      s.description.toLowerCase().contains(query.toLowerCase())).toList();

    return BaseScaffold(
      currentIndex: 2,
      body: Column(
        children: [
          AppBar(
            title: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => query = val),
              decoration: const InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.deepOrange),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                          Icon(IconData(int.parse(item.icon), fontFamily: 'MaterialIcons')),
                        ],
                      ),
                      const Divider(),
                      Text(item.description),
                      const SizedBox(height: 4),
                      Text('IP: ${item.ip}:${item.port}'),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Last Access: ${DateFormat('yyyy-MM-dd HH:mm').format(item.lastAccess.toLocal())}',
                          style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
