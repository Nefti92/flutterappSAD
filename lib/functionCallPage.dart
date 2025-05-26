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
      widget.params.where((p) => !p.output).toList();

  /// Whether the function can receive ETH
  bool get _isPayable => widget.func.payable;

  /// Whether the function changes state (needs gas)
  bool get _isStateChanging =>
      widget.func.stateMutability != 'view' &&
      widget.func.stateMutability != 'pure';

  @override
  void initState() {
    super.initState();
    // initialize controllers for each input param
    for (var p in _inputParams) {
      _controllers[p.name] = TextEditingController();
    }
    if (_isPayable) {
      _controllers['value'] = TextEditingController();
    }
    if (_isStateChanging) {
      _controllers['maxGas'] = TextEditingController();
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

    final values = <String, String>{
      for (var p in _inputParams)
        p.name: _controllers[p.name]!.text.trim(),
    };

    if (_isPayable) {
      values['value'] = _controllers['value']!.text.trim();
    }
    if (_isStateChanging) {
      values['maxGas'] = _controllers['maxGas']!.text.trim();
    }

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
              // input fields for function parameters
              for (final param in _inputParams) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: TextFormField(
                    controller: _controllers[param.name],
                    decoration: InputDecoration(
                      labelText: '${param.name} (${param.type})',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],

              // payable value input (wei)
              if (_isPayable) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['value'],
                  decoration: const InputDecoration(
                    labelText: 'Value (wei)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    if (BigInt.tryParse(value.trim()) == null) {
                      return 'Must be a number';
                    }
                    return null;
                  },
                ),
              ],

              // max gas input for state-changing
              if (_isStateChanging) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controllers['maxGas'],
                  decoration: const InputDecoration(
                    labelText: 'Max Gas',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(value.trim()) == null) {
                      return 'Must be an integer';
                    }
                    return null;
                  },
                ),
              ],

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
