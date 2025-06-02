import 'package:flutter/material.dart';
import 'package:cdapp/models/function_parameter_model.dart';

class EditFunctionPage extends StatefulWidget {
  final String initialName;
  final List<FuncParameter> initialParams;
  final int functionId;
  final String initialStateMutability;
  final bool initialPayable;

  const EditFunctionPage({
    super.key,
    required this.initialName,
    required this.initialParams,
    required this.functionId,
    required this.initialStateMutability,
    required this.initialPayable,
  });

  @override
  State<EditFunctionPage> createState() => _EditFunctionPageState();
}

class _EditFunctionPageState extends State<EditFunctionPage> {
  late TextEditingController _nameController;
  late List<FuncParameter> _params;
  late List<TextEditingController> _typeControllers = [];
  final List<int> _removedIds = [];

  final List<String> solidityTypes = [
    'uint256', 'uint', 'address', 'bool', 'string', 'bytes', 'int', 'uint8', 'int256'
  ];

  final List<String> mutabilityOptions = [
    'view', 'pure', 'empty'
  ];

  bool _isView = true;
  String _stateMutability = 'view';
  bool _payable = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _stateMutability = widget.initialStateMutability;
    _payable = widget.initialPayable;
    _params = widget.initialParams
        .map((p) => FuncParameter(
              id: p.id,
              functionId: p.functionId,
              name: p.name,
              type: p.type,
              output: p.output,
            ))
        .toList();
    _typeControllers = _params.map((p) => TextEditingController(text: p.type)).toList();
  }

  void _addParameter(bool isOutput) {
    setState(() {
      final newParam = FuncParameter(
        functionId: widget.functionId,
        name: '',
        type: solidityTypes.first,
        output: isOutput,
      );
      _params.add(newParam);
      _typeControllers.add(TextEditingController(text: newParam.type));
    });
  }

  void _removeParameter(int index) {
    final param = _params[index];
    if (param.id != null) _removedIds.add(param.id!);
    setState(() {
      _params.removeAt(index);
      _typeControllers.removeAt(index);
    });
  }

  Widget _buildParameterEditor(int index) {
    final param = _params[index];
    final typeController = _typeControllers[index];

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: TextFormField(
            initialValue: param.name,
            decoration: const InputDecoration(labelText: 'Param Name'),
            onChanged: (value) => param.name = value,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 4,
          child: TextFormField(
            controller: typeController,
            decoration: InputDecoration(
              labelText: 'Param Type',
              suffixIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.arrow_drop_down),
                onSelected: (value) {
                  typeController.text = value;
                  param.type = value;
                },
                itemBuilder: (context) {
                  return solidityTypes
                      .map((type) =>
                          PopupMenuItem<String>(value: type, child: Text(type)))
                      .toList();
                },
              ),
            ),
            onChanged: (value) => param.type = value,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeParameter(index),
        ),
      ],
    );
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.pop(context, {
      'name': name,
      'params': _params,
      'removed': _removedIds,
      'isView': _isView,
      'stateMutability': _stateMutability,
      'payable': _payable,
    });
  }

  @override
  Widget build(BuildContext context) {
    final inputIndexes = List.generate(_params.length, (i) => i).where((i) => !_params[i].output).toList();
    final outputIndexes = List.generate(_params.length, (i) => i).where((i) => _params[i].output).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Function ${_nameController.text}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Function Name'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Payable:'),
                Switch(
                  value: _payable,
                  onChanged: (val) => setState(() => _payable = val),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _stateMutability,
                    items: mutabilityOptions
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _stateMutability = val);
                    },
                    decoration: const InputDecoration(labelText: 'State Mutability'),
                  ),
                ),
              ],
            ),
            Divider(
              color: Colors.black,
              thickness: 1,
              height: 30,
            ),
            const SizedBox(height: 24),
            const Text('Input Parameters:'),
            const SizedBox(height: 8),
            ...inputIndexes.map(_buildParameterEditor),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Input Parameter'),
              onPressed: () => _addParameter(false),
            ),
            const SizedBox(height: 24),
            Divider(
              color: Colors.black,
              thickness: 1,
              height: 30,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text('Output Parameters:'),
            ),
            const SizedBox(height: 8),
            ...outputIndexes.map(_buildParameterEditor),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Output Parameter'),
              onPressed: () => _addParameter(true),
            ),
          ],
        ),
      ),
    );
  }
}
