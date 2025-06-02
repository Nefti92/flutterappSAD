import 'package:flutter/material.dart';
import 'package:cdapp/models/event_parameter_model.dart';

class EditEventPage extends StatefulWidget {
  final String initialName;
  final List<EventParameter> initialParams;
  final int eventId;
  final bool initialAnonymous;

  const EditEventPage({
    super.key,
    required this.initialName,
    required this.initialParams,
    required this.eventId,
    required this.initialAnonymous,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  late TextEditingController _nameController;
  late List<EventParameter> _params;
  late List<TextEditingController> _typeControllers;
  final List<int> _removedIds = [];

  final List<String> solidityTypes = [
    'uint256', 'uint', 'address', 'bool', 'string', 'bytes', 'int', 'uint8', 'int256'
  ];

  bool _anonymous = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _anonymous = widget.initialAnonymous;
    _params = widget.initialParams
        .map((p) => EventParameter(
              id: p.id,
              eventId: p.eventId,
              name: p.name,
              type: p.type,
              indexed: p.indexed,
            ))
        .toList();
    _typeControllers =
        _params.map((p) => TextEditingController(text: p.type)).toList();
  }

  void _addParameter() {
    setState(() {
      final newParam = EventParameter(
        eventId: widget.eventId,
        name: '',
        type: solidityTypes.first,
        indexed: false,
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
          flex: 3,
          child: TextFormField(
            initialValue: param.name,
            decoration: const InputDecoration(labelText: 'Param Name'),
            onChanged: (value) => param.name = value,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextFormField(
            controller: typeController,
            decoration: InputDecoration(
              labelText: 'Type',
              suffixIcon: PopupMenuButton<String>(
                icon: const Icon(Icons.arrow_drop_down),
                onSelected: (value) {
                  typeController.text = value;
                  param.type = value;
                },
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
        const SizedBox(width: 8),
        Column(
          children: [
            const Text('Indexed'),
            Checkbox(
              value: param.indexed,
              onChanged: (val) =>
                  setState(() => param.indexed = val ?? false),
            ),
          ],
        ),
        Padding(
              padding: const EdgeInsets.only(top: 18),
              child: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeParameter(index),
              ),
        )
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
      'anonymous': _anonymous,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edit Event ${_nameController.text}"),
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
              decoration: const InputDecoration(labelText: 'Event Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Anonymous Event:'),
                Switch(
                  value: _anonymous,
                  onChanged: (bool val) => setState(() => _anonymous = val),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Event Parameters'),
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
