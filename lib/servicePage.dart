import 'package:cdapp/editFunctionPage.dart';
import 'package:cdapp/functionCallPage.dart';
import 'package:cdapp/models/contract_function_model.dart';
import 'package:cdapp/models/function_parameter_model.dart';
import 'package:flutter/material.dart';
import 'package:cdapp/models/api_service_model.dart';
import 'package:cdapp/models/api_service_database.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/web3dart.dart';

class ApiDetailPage extends StatefulWidget {
  final ApiService apiService;

  const ApiDetailPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<ApiDetailPage> createState() => _ApiDetailPageState();
}

class _ApiDetailPageState extends State<ApiDetailPage> with SingleTickerProviderStateMixin {
  final TextEditingController _functionNameController = TextEditingController();
  List<SCFunction> _functions = [];
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadFunctions();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _loadFunctions() async {
    final functions = await ApiDatabase.getFunctionsForService(widget.apiService.id!);
    print(functions);
    setState(() => _functions = functions);
  }

  Future<void> _addFunction(String funcName) async {
    if (funcName.trim().isEmpty) return;

    final newFunc = SCFunction(serviceId: widget.apiService.id!, name: funcName.trim());
    final newId = await ApiDatabase.insertFunction(newFunc);

    _functionNameController.clear();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditFunctionPage(
          initialName: funcName,
          initialParams: [],
          functionId: newId,
        ),
      ),
    );

    if (result == null) return;

    final params = result['params'] as List<FuncParameter>;
    final removed = result['removed'] as List<int>;

    for (final rid in removed) {
      await ApiDatabase.deleteParameter(rid);
    }

    for (final p in params) {
      if (p.name.trim().isEmpty || p.type.trim().isEmpty) continue;
      if (p.id == null) {
        await ApiDatabase.insertParameter(FuncParameter(
          functionId: newId,
          name: p.name,
          type: p.type,
        ));
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
        ),
      ),
    );
    if (result == null) return;

    final name = result['name'] as String;
    final params = result['params'] as List<FuncParameter>;
    final removed = result['removed'] as List<int>;

    await ApiDatabase.updateFunction(
      SCFunction(id: func.id, serviceId: func.serviceId, name: name),
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
                IconButton(icon: const Icon(Icons.play_arrow), onPressed: () => _callContractFunction(func)),
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

  Future<void> _callContractFunctionWithInput(
    SCFunction func,
    List<FuncParameter> params,
    Map<String, String> inputs,
  ) async {
    final contractAddress = EthereumAddress.fromHex(widget.apiService.address);
    final rpcUrl = 'http://${widget.apiService.ip}:${widget.apiService.port}';
    // final abi = await _loadContractAbi(); // Implement this to load your ABI
    final abi = "";
    final client = Web3Client(rpcUrl, http.Client());

    final contract = DeployedContract(
      ContractAbi.fromJson(abi, widget.apiService.title),
      contractAddress,
    );

    final SCFunction = contract.function(func.name);

    try {
      final inputParams = params.map((p) {
        final value = inputs[p.name]!;
        switch (p.type) {
          case 'address':
            return EthereumAddress.fromHex(value);
          case 'uint':
          case 'uint256':
          case 'int':
          case 'int256':
            return BigInt.parse(value);
          case 'bool':
            return value.toLowerCase() == 'true';
          case 'string':
            return value;
          default:
            throw Exception('Unsupported type: ${p.type}');
        }
      }).toList();

      final result = await client.call(
        contract: contract,
        function: SCFunction,
        params: inputParams,
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Result'),
            content: Text(result.toString()),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _callContractFunction(SCFunction func) async {
    final params = await ApiDatabase.getParametersForFunction(func.id!);

    final inputValues = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => FunctionCallPage(func: func, params: params),
      ),
    );

    if (inputValues != null) {
      await _callContractFunctionWithInput(func, params, inputValues);
    }
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
          const Center(child: Text('Dati Vari')),
          const Center(child: Text('Eventi')),
        ],
      ),
    );
  }
}
