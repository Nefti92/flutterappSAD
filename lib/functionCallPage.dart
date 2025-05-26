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
  final _formKey = GlobalKey<FormState>();

  List<FuncParameter> get _inputParams =>
      widget.params.where((p) => p.output == false).toList();

  @override
  void initState() {
    super.initState();
    for (var p in _inputParams) {
      _controllers[p.name] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final values = {
      for (var p in _inputParams) p.name: _controllers[p.name]!.text.trim(),
    };

    Navigator.pop(context, values);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Call ${widget.func.name}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              for (final param in _inputParams)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: TextFormField(
                    controller: _controllers[param.name],
                    decoration: InputDecoration(
                      labelText: '${param.name} (${param.type})',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                            ? 'Required'
                            : null,
                  ),
                ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('Call On-Chain Function'),
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
