import 'package:flutter/material.dart';
import 'baseScaffold.dart';
import 'package:intl/intl.dart';
import 'package:cdapp/models/api_database.dart';
import 'package:cdapp/models/contract_model.dart';
import 'package:cdapp/smartContractPage.dart';


class ContractsPage extends StatefulWidget {
  const ContractsPage({super.key});

  @override
  State<ContractsPage> createState() => _ContractsPagePageState();
}

class _ContractsPagePageState extends State<ContractsPage> {
  List<Contract> services = [];
  final _searchController = TextEditingController();
  String query = '';

  final List<IconData> availableIcons = [
    Icons.cloud,
    Icons.http,
    Icons.api,
    Icons.bolt,
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices() async {
    final data = await ApiDatabase.getAllContracts();
    setState(() {
      services = data;
    });
  }

  void _showAddDialog() {
    final titleController = TextEditingController();
    final addressController = TextEditingController();
    final descController = TextEditingController();
    final ipController = TextEditingController();
    final portController = TextEditingController();
    final chainIDController = TextEditingController();
    IconData? selectedIcon;
      showDialog(
        context: context,
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setModalState) => AlertDialog(
              title: const Text('Create API Service'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                    TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                    TextField(controller: ipController, decoration: const InputDecoration(labelText: 'IP Address')),
                    TextField(controller: portController, decoration: const InputDecoration(labelText: 'Port'), keyboardType: TextInputType.number),
                    TextField(controller: chainIDController, decoration: const InputDecoration(labelText: 'ChainID'), keyboardType: TextInputType.number),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 12,
                      children: availableIcons.map((icon) {
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedIcon = icon),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: selectedIcon == icon ? Colors.deepOrange : Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: selectedIcon == icon ? Colors.deepOrange.withOpacity(0.1) : null,
                            ),
                            child: Icon(icon, size: 30),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedIcon != null) {
                      final newService = Contract(
                        title: titleController.text,
                        address: addressController.text,
                        description: descController.text,
                        ip: ipController.text,
                        port: int.tryParse(portController.text) ?? 0,
                        chainID: int.tryParse(chainIDController.text) ?? 1337,
                        icon: selectedIcon!.codePoint.toString(),
                        lastAccess: DateTime.now(),
                      );
                      await ApiDatabase.insertContract(newService);
                      _loadServices();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          );
        },
      );
  }

  void _showEditDialog(Contract contract) {
    final titleController = TextEditingController(text: contract.title);
    final addressController = TextEditingController(text: contract.address);
    final descController = TextEditingController(text: contract.description);
    final ipController = TextEditingController(text: contract.ip);
    final portController = TextEditingController(text: contract.port.toString());
    final chainIDController = TextEditingController(text: contract.chainID.toString());
    IconData? selectedIcon = IconData(int.parse(contract.icon), fontFamily: 'MaterialIcons');

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) => AlertDialog(
            title: const Text('Edit API Service'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                  TextField(controller: addressController, decoration: const InputDecoration(labelText: 'Address')),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
                  TextField(controller: ipController, decoration: const InputDecoration(labelText: 'IP Address')),
                  TextField(controller: portController, decoration: const InputDecoration(labelText: 'Port'), keyboardType: TextInputType.number),
                  TextField(controller: chainIDController, decoration: const InputDecoration(labelText: 'ChainID'), keyboardType: TextInputType.number),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    children: availableIcons.map((icon) {
                      return GestureDetector(
                        onTap: () => setModalState(() => selectedIcon = icon),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: selectedIcon == icon ? Colors.deepOrange : Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: selectedIcon == icon ? Colors.deepOrange.withOpacity(0.1) : null,
                          ),
                          child: Icon(icon, size: 30),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedIcon != null) {
                    final updated = Contract(
                      id: contract.id,
                      title: titleController.text,
                      address: addressController.text,
                      description: descController.text,
                      ip: ipController.text,
                      port: int.tryParse(portController.text) ?? 0,
                      chainID: int.tryParse(chainIDController.text) ?? 1337,
                      icon: selectedIcon!.codePoint.toString(),
                      lastAccess: DateTime.now(),
                    );
                    await ApiDatabase.updateContract(updated);
                    _loadServices();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    final filtered = services.where((s) =>
      s.title.toLowerCase().contains(query.toLowerCase()) ||
      s.description.toLowerCase().contains(query.toLowerCase())).toList();

    return BaseScaffold(
      currentIndex: 2,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            // color: Theme.of(context).appBarTheme.backgroundColor ?? Colors.deepOrange,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => query = val),
                      decoration: const InputDecoration(
                        hintText: 'Search...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final item = filtered[i];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SmartContractPage(apiService: item,),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepOrange),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Icon(IconData(int.parse(item.icon), fontFamily: 'MaterialIcons')),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.deepOrange),
                              onPressed: () => _showEditDialog(item),
                            ),
                          ],
                        ),

                        const Divider(),
                        Text('Address: ${item.address}'),
                        Text(item.description),
                        const SizedBox(height: 4),
                        Text('IP: ${item.ip}:${item.port} - ChainID: ${item.chainID}'),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Last Access: ${DateFormat('yyyy-MM-dd HH:mm').format(item.lastAccess.toLocal())}',
                            style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
