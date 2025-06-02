import 'package:cdapp/editFunctionPage.dart';
import 'package:cdapp/eventContractsPage.dart';
import 'package:cdapp/functionCallPage.dart';
import 'package:cdapp/models/call_result_model.dart';
import 'package:cdapp/models/contract_function_model.dart';
import 'package:cdapp/models/function_parameter_model.dart';
import 'package:flutter/material.dart';
import 'package:cdapp/models/contract_model.dart';
import 'package:cdapp/models/api_database.dart';
import 'package:intl/intl.dart';

class SmartContractPage extends StatefulWidget {
  final Contract apiService;

  const SmartContractPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<SmartContractPage> createState() => _SmartContractPageState();
}

class _SmartContractPageState extends State<SmartContractPage> with SingleTickerProviderStateMixin {
  final TextEditingController _functionNameController = TextEditingController();
  List<SCFunction> _functions = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadFunctions();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1 && _tabController.indexIsChanging == false) {
        setState(() {});
      }
    });
  }

  Future<void> _loadFunctions() async {
    final functions = await ApiDatabase.getFunctionsForContract(widget.apiService.id!);
    print(functions);
    setState(() => _functions = functions);
  }

  Future<void> _addFunction(String funcName) async {
    if (funcName.trim().isEmpty) return;

    final newFunc = SCFunction(
      contractId: widget.apiService.id!,
      name: funcName.trim(),
      stateMutability: 'view',
      payable: false,
    );
    final newId = await ApiDatabase.insertFunction(newFunc);

    _functionNameController.clear();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditFunctionPage(
          initialName: funcName,
          initialParams: [],
          functionId: newId,
          initialStateMutability: 'view',
          initialPayable: false,
        ),
      ),
    );

    if (result == null) return;

    final params = result['params'] as List<FuncParameter>;
    final removed = result['removed'] as List<int>;
    final stateMutability = result['stateMutability'] as String;
    final payable = result['payable'] as bool;

    await ApiDatabase.updateFunction(
      SCFunction(
        id: newId,
        contractId: widget.apiService.id!,
        name: funcName.trim(),
        stateMutability: stateMutability,
        payable: payable,
      ),
    );

    for (final rid in removed) {
      await ApiDatabase.deleteParameter(rid);
    }

    for (final p in params) {
      if (p.name.trim().isEmpty || p.type.trim().isEmpty) continue;
      if (p.id == null) {
        await ApiDatabase.insertParameter(p);
      } else {
        await ApiDatabase.updateParameter(p);
      }
    }

    await _loadFunctions();
  }

  Future<void> _editFunction(SCFunction func) async {
    final existing = await ApiDatabase.getParametersForFunction(func.id!);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditFunctionPage(
          initialName: func.name,
          initialParams: existing,
          functionId: func.id!,
          initialStateMutability: func.stateMutability,
          initialPayable: func.payable,
        ),
      ),
    );

    if (result == null) return;

    final name = result['name'] as String;
    final params = result['params'] as List<FuncParameter>;
    final removed = result['removed'] as List<int>;
    final stateMutability = result['stateMutability'] as String;
    final payable = result['payable'] as bool;

    await ApiDatabase.updateFunction(
      SCFunction(
        id: func.id,
        contractId: func.contractId,
        name: name,
        stateMutability: stateMutability,
        payable: payable,
      ),
    );

    for (final rid in removed) {
      await ApiDatabase.deleteParameter(rid);
    }

    for (final p in params) {
      if (p.id != null) {
        await ApiDatabase.updateParameter(p);
      } else {
        await ApiDatabase.insertParameter(p);
      }
    }

    await _loadFunctions();
  }

  Future<void> _deleteFunction(int id) async {
    await ApiDatabase.deleteFunction(id);
    _loadFunctions();
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
                IconButton(
                  icon: const Icon(Icons.play_arrow),
                  onPressed: () async {
                    final params = await ApiDatabase.getParametersForFunction(func.id!);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FunctionCallPage(
                          func: func,
                          params: params,
                          apiService: widget.apiService,
                        ),
                      ),
                    );
                  },
                ),
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

  Future<List<CallResult>> _fetchAllResults() {
    return ApiDatabase.getResultsForContract(widget.apiService.id!);
  }

  Widget _buildResultList() {
    return FutureBuilder<List<CallResult>>(
      future: _fetchAllResults(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        if (snapshot.data!.isEmpty) return const Center(child: Text('No data found'));

        return ListView.builder(
          itemCount: snapshot.data!.length,
          padding: const EdgeInsets.only(top: 15),
          itemBuilder: (context, index) {
            final result = snapshot.data![index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Function: ${result.functionName}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(DateFormat.yMd().add_Hms().format(result.timestamp.toLocal())),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () async {
                          await ApiDatabase.deleteCallResult(result.id!);
                          setState(() {}); // triggers FutureBuilder to reload fresh data
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SelectableText(result.result),
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Divider(),
                  ),
                ],
              ),
            );
          },
        );
      },
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
          _buildResultList(),
          EventPage(apiService: widget.apiService),
        ],
      ),
    );
  }
}