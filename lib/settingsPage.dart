import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'baseScaffold.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _publicController = TextEditingController();
  final TextEditingController _privateController = TextEditingController();
  Database? _database;

  @override
  void initState() {
    super.initState();
    _initDb();
  }

  Future<void> _initDb() async {
    final path = p.join(await getDatabasesPath(), 'wallet.db');
    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE wallet(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            passphrase TEXT,
            public TEXT,
            private TEXT
          )
        ''');
      },
    );
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    final data = await _database!.query('wallet', limit: 1);
    if (data.isNotEmpty) {
      _publicController.text = data.first['public'] as String? ?? '';
      _privateController.text = data.first['private'] as String? ?? '';
    }
  }

  Future<void> _saveWallet() async {
    final public = _publicController.text.trim();
    final private = _privateController.text.trim();

    final existing = await _database!.query('wallet', limit: 1);
    if (existing.isNotEmpty) {
      await _database!.update('wallet', {
        'public': public,
        'private': private,
      });
    } else {
      await _database!.insert('wallet', {
        'public': public,
        'private': private,
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wallet address saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 3,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 40),
            const Text('Public Address'),
            TextField(
              controller: _publicController,
              decoration: const InputDecoration(
                hintText: 'Enter your public address',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Private Address'),
            TextField(
              controller: _privateController,
              // obscureText: true,
              decoration: const InputDecoration(
                hintText: 'Enter your private address',
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveWallet,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
