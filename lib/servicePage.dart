import 'package:cdapp/editFunctionPage.dart';
import 'package:cdapp/functionCallPage.dart';
import 'package:cdapp/models/contract_function_model.dart';
import 'package:cdapp/models/function_parameter_model.dart';
import 'package:cdapp/models/wallet_service_model.dart';
import 'package:cdapp/utils/web3_extensions.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cdapp/models/api_service_model.dart';
import 'package:cdapp/models/api_service_database.dart';
import 'package:http/http.dart' as http;
import 'package:web3dart/crypto.dart';
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

    final newFunc = SCFunction(
      serviceId: widget.apiService.id!,
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
        serviceId: widget.apiService.id!,
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
        serviceId: func.serviceId,
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
    BigInt valueWei,
    int? maxGas,
  ) async {
    final contractAddress = EthereumAddress.fromHex(widget.apiService.address);
    var rpcUrl = 'http://${widget.apiService.ip}:${widget.apiService.port}';
    if (widget.apiService.port == 443) rpcUrl = 'https://${widget.apiService.ip}';
    rpcUrl = "https://192.168.1.57";
    print(contractAddress);

    // Log payload
    final fullPayload = {
      'function': func.toMap(),
      'parameters': params.map((p) => p.toMap()).toList(),
      'inputs': inputs,
    };
    final pretty = const JsonEncoder.withIndent('  ').convert(fullPayload);
    debugPrint(pretty);

    // Separate input and output parameters
    final inputParams = params.where((p) => !p.output).toList();
    final outputParams = params.where((p) => p.output).toList();

    // Construct ABI dynamically
    final abi = ContractAbi.fromJson(
      '''
      [
        {
          "inputs": [
            ${inputParams.map((p) => '{"name": "${p.name}", "type": "${p.type}"}').join(',')}
          ],
          "name": "${func.name}",
          "outputs": [
            ${outputParams.map((p) => '{"name": "${p.name}", "type": "${p.type}"}').join(',')}
          ],
          "payable": "${func.payable}",
          "stateMutability": "${func.stateMutability}",
          "type": "function"
        }
      ]
      ''',
      func.name,
    );

    final prettyABI = const JsonEncoder.withIndent('  ').convert(abi.toString());
    debugPrint(prettyABI);

    final client = Web3Client(rpcUrl, http.Client());
    final contract = DeployedContract(abi, contractAddress);
    final function = contract.function(func.name);

    // Parse input parameters into correct Dart types
    final typedInputs = inputParams.map((p) {
      final value = inputs[p.name]!;
      switch (p.type) {
        case 'address':
          return EthereumAddress.fromHex(value);
        case 'uint':
        case 'uint256':
        case 'int':
        case 'int256':
        case 'uint8':
          return BigInt.parse(value);
        case 'bool':
          return value.toLowerCase() == 'true';
        case 'string':
          return value;
        case 'bytes':
          return hexToBytes(value);
        default:
          throw Exception('Unsupported type: ${p.type}');
      }
    }).toList();

    try {
      if (func.stateMutability == 'view' || func.stateMutability == 'pure') {
        // READ-ONLY
        final result = await client.call(
          contract: contract,
          function: function,
          params: typedInputs,
        );

        debugPrint('call() → $result');
      } else {
          // STATE-CHANGING --> SIGNED TX
          final privateKeyHex = await WalletService.getPrivateKey();
          if (privateKeyHex == null) {
            throw Exception('Private key required for ${func.name}()');
          }
          final creds = EthPrivateKey.fromHex(privateKeyHex);

          final tx = Transaction.callContract(
            contract: contract,
            function: function,
            parameters: typedInputs,
            value: EtherAmount.fromBigInt(EtherUnit.wei, valueWei),
            maxGas: maxGas,
          );

          final txHash = await client.sendTransaction(
            creds,
            tx,
            chainId: widget.apiService.chainID,
          );
          debugPrint('txHash → $txHash');

          final receipt = await client.waitForReceipt(txHash);

          debugPrint('Mined in block ${receipt.blockNumber}');
          debugPrint('Receipt → $receipt');
        }
      } catch (e) {
        debugPrint('Error during ${func.name}: $e');
      } finally {
        client.dispose();
      }
    }

  Future<void> _callContractFunction(SCFunction func) async {
    final params = await ApiDatabase.getParametersForFunction(func.id!);

    final inputs = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => FunctionCallPage(func: func, params: params),
      ),
    );

    if (inputs != null) {
      final valueWei = inputs.containsKey('valueWei')
          ? BigInt.parse(inputs['valueWei']!)
          : BigInt.zero;
      final maxGas = inputs.containsKey('maxGas')
          ? int.parse(inputs['maxGas']!)
          : null;
      
      print(inputs.values);
      await _callContractFunctionWithInput(
        func,
        params,
        inputs,
        valueWei,
        maxGas,
      );
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