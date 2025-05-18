import 'package:flutter/material.dart';
import 'package:cdapp/models/function_parameter_model.dart';
import 'package:cdapp/models/contract_function_model.dart';

class FunctionCallPage extends StatefulWidget {
  final SCFunction func;
  final List<FuncParameter> params;

  const FunctionCallPage({
    super.key,
    required this.func,
    required this.params,
  });

  @override
  State<FunctionCallPage> createState() => _FunctionCallPageState();
}

class _FunctionCallPageState extends State<FunctionCallPage> {
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (var p in widget.params) {
      _controllers[p.name] = TextEditingController();
    }
  }

  void _submit() {
    final values = {
      for (var p in widget.params) p.name: _controllers[p.name]!.text.trim(),
    };
    Navigator.pop(context, values);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Call ${widget.func.name}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            for (final param in widget.params)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: _controllers[param.name],
                  decoration: InputDecoration(
                    labelText: '${param.name} (${param.type})',
                  ),
                ),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text('Call Function'),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
