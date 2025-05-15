import 'package:cdapp/models/api_service_database.dart';
import 'package:cdapp/models/contract_function_model.dart';
import 'package:cdapp/models/function_parameter_model.dart';
import 'package:flutter/material.dart';

class EditFunctionPage extends StatefulWidget {
  final String initialName;
  final List<FunctionParameter> initialParams;
  final int functionId;

  const EditFunctionPage({
    super.key,
    required this.initialName,
    required this.initialParams,
    required this.functionId,
  });

  @override
  State<EditFunctionPage> createState() => _EditFunctionPageState();
}

class _EditFunctionPageState extends State<EditFunctionPage> {
  late TextEditingController _nameController;
  late List<FunctionParameter> _params;
  final List<int> _removedIds = [];

  final List<String> solidityTypes = [
    'uint256', 'uint', 'address', 'bool', 'string', 'bytes', 'int', 'uint8', 'int256'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _params = widget.initialParams
        .map((p) => FunctionParameter(
              id: p.id,
              functionId: p.functionId,
              name: p.name,
              type: p.type,
            ))
        .toList();
  }

  void _addParameter() {
    setState(() {
      _params.add(FunctionParameter(
        functionId: widget.functionId,
        name: '',
        type: solidityTypes.first,
      ));
    });
  }

  void _removeParameter(int index) {
    final param = _params[index];
    if (param.id != null) _removedIds.add(param.id!);
    setState(() {
      _params.removeAt(index);
    });
  }

  Widget _buildParameterEditor(int index) {
    final param = _params[index];
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
            initialValue: param.type,
            decoration: InputDecoration(
              labelText: 'Param Type',
              suffixIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.arrow_drop_down),
                onSelected: (value) => setState(() => param.type = value),
                itemBuilder: (context) {
                  return solidityTypes
                      .map((type) => PopupMenuItem<String>(
                          value: type, child: Text(type)))
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

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    await ApiDatabase.updateFunction(
      ContractFunction(id: widget.functionId, serviceId: widget.functionId, name: name),
    );

    for (final rid in _removedIds) {
      await ApiDatabase.deleteParameter(rid);
    }

    for (final p in _params) {
      if (p.name.trim().isEmpty || p.type.trim().isEmpty) continue;
      if (p.id == null) {
        await ApiDatabase.insertParameter(p);
      } else {
        await ApiDatabase.updateParameter(p);
      }
    }

    Navigator.pop(context, true);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Function'),
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
            const Text('Parameters:'),
            const SizedBox(height: 8),
            ...List.generate(_params.length, _buildParameterEditor),
            TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Parameter'),
              onPressed: _addParameter,
            ),
          ],
        ),
      ),
    );
  }
}
