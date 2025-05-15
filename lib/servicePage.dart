import 'package:cdapp/editFunctionPage.dart';
import 'package:cdapp/models/contract_function_model.dart';
import 'package:flutter/material.dart';
import 'package:cdapp/models/api_service_model.dart';
import 'package:cdapp/models/api_service_database.dart';

class ApiDetailPage extends StatefulWidget {
  final ApiService apiService;

  const ApiDetailPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<ApiDetailPage> createState() => _ApiDetailPageState();
}

class _ApiDetailPageState extends State<ApiDetailPage> with SingleTickerProviderStateMixin {
  final TextEditingController _functionNameController = TextEditingController();
  List<ContractFunction> _functions = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadFunctions();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _loadFunctions() async {
    final functions = await ApiDatabase.getFunctionsForService(widget.apiService.id!);
    setState(() => _functions = functions);
  }

  Future<void> _addFunction(String functionName) async {
    final newFunc = ContractFunction(serviceId: widget.apiService.id!, name: functionName.trim());
    final newId = await ApiDatabase.insertFunction(newFunc);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditFunctionPage(
          initialName: newFunc.name,
          initialParams: [],
          functionId: newId,
        ),
      ),
    );

    await _loadFunctions();
  }


  Future<void> _editFunction(ContractFunction func) async {
    final existing = await ApiDatabase.getParametersForFunction(func.id!);
    final success = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditFunctionPage(
          initialName: func.name,
          initialParams: existing,
          functionId: func.id!,
        ),
      ),
    );
    if (success == true) await _loadFunctions();
  }


  Future<void> _deleteFunction(int id) async {
    await ApiDatabase.deleteFunction(id);
    _loadFunctions();
  }

  Future<String?> _showEditDialog(String currentName) {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Function Name'),
        content: TextField(controller: controller),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
  }

  Widget _buildFunctionList() {
    return Column(
      children: [
        for (final func in _functions)
          ListTile(
            title: Text(func.name),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(icon: const Icon(Icons.edit), onPressed: () => _editFunction(func)),
                IconButton(icon: const Icon(Icons.delete), onPressed: () => _deleteFunction(func.id!)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildAddFunctionField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _functionNameController,
            decoration: const InputDecoration(labelText: 'Function Name'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            final name = _functionNameController.text.trim();
            if (name.isNotEmpty) {
              _addFunction(name);
            }
          },
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.apiService.title),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Functions'),
            Tab(text: 'Data'),
            Tab(text: 'Events'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAddFunctionField(),
                const SizedBox(height: 12),
                Expanded(child: SingleChildScrollView(child: _buildFunctionList())),
              ],
            ),
          ),
          const Center(child: Text('Tab 2 content')),
          const Center(child: Text('Tab 3 content')),
        ],
      ),
    );
  }
}
