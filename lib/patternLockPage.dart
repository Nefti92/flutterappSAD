import 'package:cdapp/homePage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pattern_lock/pattern_lock.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class PatternLockScreen extends StatefulWidget {
  final bool isSettingPattern;

  const PatternLockScreen({Key? key, required this.isSettingPattern}) : super(key: key);

  @override
  _PatternLockScreenState createState() => _PatternLockScreenState();
}

class _PatternLockScreenState extends State<PatternLockScreen> {
  final _storage = const FlutterSecureStorage();
  List<int> _firstPattern = [];

  Future<void> _handlePatternInput(List<int> input) async {
    final inputHash = sha256.convert(utf8.encode(input.join(','))).toString();

    if (widget.isSettingPattern) {
      if (_firstPattern.isEmpty) {
        setState(() {
          _firstPattern = input;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please confirm your pattern')),
        );
      } else {
        if (listEquals(_firstPattern, input)) {
          final inputHash = sha256.convert(utf8.encode(input.join(','))).toString();
          await _storage.write(key: 'pattern_hash', value: inputHash);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pattern set successfully')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Patterns do not match. Re-input pattern.')),
          );
          setState(() {
            _firstPattern = [];
          });
        }
      }
    } else {
      final storedHash = await _storage.read(key: 'pattern_hash');
      if (storedHash == inputHash) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect pattern')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isSettingPattern ? 'Welcome to sadAPP!\nSet your Pattern' : 'Enter Pattern', style: const TextStyle(fontWeight: FontWeight.bold),),
      ),
      body: Center(
        child: PatternLock(
          selectedColor: Colors.deepOrange,
          notSelectedColor: Colors.grey,
          dimension: 3,
          relativePadding: 0.7,
          selectThreshold: 25,
          fillPoints: true,
          onInputComplete: _handlePatternInput,
        ),
      ),
    );
  }
}
