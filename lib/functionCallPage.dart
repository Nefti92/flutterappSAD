import 'package:cdapp/models/api_database.dart';
import 'package:cdapp/models/contract_model.dart';
import 'package:cdapp/models/call_result_model.dart';
import 'package:cdapp/models/wallet_service_model.dart';
import 'package:cdapp/utils/web3_extensions.dart';
import 'package:flutter/material.dart';
import 'package:cdapp/models/function_parameter_model.dart';
import 'package:cdapp/models/contract_function_model.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';

class FunctionCallPage extends StatefulWidget {
  final SCFunction func;
  final List<FuncParameter> params;
  final CallResult? latestResult;
  final Contract apiService;

  const FunctionCallPage({
    super.key,
    required this.func,
    required this.params,
    required this.apiService,
    this.latestResult,
  });

  @override
  State<FunctionCallPage> createState() => _FunctionCallPageState();
}

class _FunctionCallPageState extends State<FunctionCallPage> {
  final Map<String, TextEditingController> _controllers = {};
  final _formKey = GlobalKey<FormState>();
  List<CallResult> _results = [];

  List<FuncParameter> get _inputParams =>
      widget.params.where((p) => !p.output).toList();

  // Whether the function can receive ETH
  bool get _isPayable => widget.func.payable;

  // Whether the function changes state (needs gas)
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

    _loadResults(); // load historical call results
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
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

    final inputs = {
      for (var p in _inputParams) p.name: _controllers[p.name]!.text.trim(),
    };

    if (_isPayable) {
      inputs['value'] = _controllers['value']?.text.trim() ?? '0';
    }
    if (_isStateChanging) {
      inputs['maxGas'] = _controllers['maxGas']?.text.trim() ?? '';
    }

    await _executeContractCall(inputs);
  }

  Future<void> _executeContractCall(Map<String, String> inputs) async {
    var contractAddress = EthereumAddress.fromHex(widget.apiService.address);
    var rpcUrl = 'http://${widget.apiService.ip}:${widget.apiService.port}';
    if (widget.apiService.port == 443) rpcUrl = 'https://${widget.apiService.ip}';
    // rpcUrl = "https://192.168.1.57";
    // contractAddress = EthereumAddress.fromHex("0x2E1f232a9439C3D459FcEca0BeEf13acc8259Dd8");
    print(contractAddress);

    final inputParams = widget.params.where((p) => !p.output).toList();
    final outputParams = widget.params.where((p) => p.output).toList();

    final abi = ContractAbi.fromJson(
      '''
      [
        {
          "inputs": [
            ${inputParams.map((p) => '{"name": "${p.name}", "type": "${p.type}"}').join(',')}
          ],
          "name": "${widget.func.name}",
          "outputs": [
            ${outputParams.map((p) => '{"name": "${p.name}", "type": "${p.type}"}').join(',')}
          ],
          "payable": ${widget.func.payable},
          "stateMutability": "${widget.func.stateMutability}",
          "type": "function"
        }
      ]
      ''',
      widget.func.name,
    );

    final client = Web3Client(rpcUrl, http.Client());
    final contract = DeployedContract(abi, contractAddress);
    final function = contract.function(widget.func.name);

    final typedInputs = inputParams.map((p) {
      final value = inputs[p.name]!;
      switch (p.type) {
        case 'address': return EthereumAddress.fromHex(value);
        case 'uint':
        case 'uint256':
        case 'int':
        case 'int256':
        case 'uint8': return BigInt.parse(value);
        case 'bool': return value.toLowerCase() == 'true';
        case 'string': return value;
        case 'bytes': return hexToBytes(value);
        default: throw Exception('Unsupported type: ${p.type}');
      }
    }).toList();

    final valueWei = inputs.containsKey('value') ? BigInt.parse(inputs['value']!) : BigInt.zero;
    final maxGas = inputs.containsKey('maxGas') ? int.tryParse(inputs['maxGas']!) : null;

    String resultText;

    try {
      if (widget.func.stateMutability == 'view' || widget.func.stateMutability == 'pure') {
        final result = await client.call(
          contract: contract,
          function: function,
          params: typedInputs,
        );
        resultText = '$result';
      } else {
        final privateKeyHex = await WalletService.getPrivateKey();
        if (privateKeyHex == null) throw Exception('Private key required');

        final creds = EthPrivateKey.fromHex(privateKeyHex);
        final tx = Transaction.callContract(
          contract: contract,
          function: function,
          parameters: typedInputs,
          value: EtherAmount.inWei(valueWei),
          maxGas: maxGas,
        );

        final txHash = await client.sendTransaction(creds, tx, chainId: widget.apiService.chainID);
        final receipt = await client.waitForReceipt(txHash);
        resultText = 'Tx Hash: $txHash\nBlock: ${receipt.blockNumber}\nStatus: ${receipt.status}';
      }
    } catch (e) {
      resultText = 'Error: $e';
    } finally {
      client.dispose();
    }

    final callResult = CallResult(
      functionId: widget.func.id!,
      contractAddress: widget.apiService.address,
      functionName: widget.func.name,
      result: resultText.replaceAll('[', '').replaceAll(']', ''),
      timestamp: DateTime.now(),
    );

    await ApiDatabase.insertCallResult(callResult);
    await _loadResults();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Call executed successfully')),
    );
  }


  Future<void> _loadResults() async {
    final results = await ApiDatabase.getResultsForFunction(widget.func.id!);
    setState(() => _results = results);
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
              if (_results.isNotEmpty) ...[
                const Divider(height: 32),
                Text('Past Calls', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final r in _results)
                  Padding(
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
                                    'Function: ${r.functionName}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(DateFormat.yMd().add_Hms().format(r.timestamp.toLocal())),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete',
                              onPressed: () async {
                                await ApiDatabase.deleteCallResult(r.id!);
                                setState(() {
                                  _results.removeWhere((res) => res.id == r.id);
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Builder(
                          builder: (_) {
                            final resultText = r.result;
                            final imageUrlPattern = RegExp(r'(https?:\/\/.*\.(?:png|jpg|jpeg|gif|webp))', caseSensitive: false);
                            final match = imageUrlPattern.firstMatch(resultText);
                            final imageUrl = match?.group(0);

                            if (imageUrl != null) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                child: Center(
                                  child: Image.network(
                                    imageUrl,
                                    height: 200,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Text('Result: $resultText'),
                                  ),
                                ),
                              );
                            } else {
                              return SelectableText('Result: $resultText');
                            }
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Divider(),
                        ),
                      ],
                    ),
                  ),
              ]

            ],
          ),
        ),
      ),
    );
  }
}
