import 'dart:convert';

import 'package:cdapp/editEventPage.dart';
import 'package:cdapp/eventSubscription.dart';
import 'package:cdapp/models/contract_event_model.dart';
import 'package:flutter/material.dart';
import 'package:cdapp/models/contract_model.dart';
import 'package:cdapp/models/event_parameter_model.dart';
import 'package:cdapp/models/api_database.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:web3dart/web3dart.dart';

class EventPage extends StatefulWidget {
  final Contract apiService;

  const EventPage({Key? key, required this.apiService}) : super(key: key);

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  final TextEditingController _eventNameController = TextEditingController();
  List<SCEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    final events = await ApiDatabase.getEventsForContract(widget.apiService.id!);
    setState(() => _events = events);
  }

  Future<void> _addEvent(String eventName) async {
    if (eventName.trim().isEmpty) return;

    final newEvent = SCEvent(
      contractId: widget.apiService.id!,
      name: eventName.trim(),
      anonymous: false, 
    );
    final newId = await ApiDatabase.insertEvent(newEvent);

    _eventNameController.clear();

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditEventPage(
          initialName: eventName,
          initialParams: [],
          eventId: newId,
          initialAnonymous: false,
        ),
      ),
    );

    if (result == null) return;

    final name = result['name'] as String;
    final params = result['params'] as List<EventParameter>;
    final removed = result['removed'] as List<int>;
    final anonymous = result['anonymous'] as bool;

    await ApiDatabase.updateEvent(
      SCEvent(
        id: newId,
        contractId: widget.apiService.id!,
        name: name,
        anonymous: anonymous,
      ),
    );

    for (final rid in removed) {
      await ApiDatabase.deleteEventParameter(rid);
    }

    for (final p in params) {
      if (p.name.trim().isEmpty || p.type.trim().isEmpty) continue;
      if (p.id == null) {
        await ApiDatabase.insertEventParameter(p);
      } else {
        await ApiDatabase.updateEventParameter(p);
      }
    }

    await _loadEvents();
  }

  Future<void> _editEvent(SCEvent event) async {
    final existing = await ApiDatabase.getParametersForEvent(event.id!);
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditEventPage(
          initialName: event.name,
          initialParams: existing,
          eventId: event.id!,
          initialAnonymous: event.anonymous,
        ),
      ),
    );

    if (result == null) return;

    final name = result['name'] as String;
    final params = result['params'] as List<EventParameter>;
    final removed = result['removed'] as List<int>;
    final anonymous = result['anonymous'] as bool;

    await ApiDatabase.updateEvent(
      SCEvent(
        id: event.id,
        contractId: event.contractId,
        name: name,
        anonymous: anonymous,
      ),
    );

    for (final rid in removed) {
      await ApiDatabase.deleteEventParameter(rid);
    }

    for (final p in params) {
      if (p.id != null) {
        await ApiDatabase.updateEventParameter(p);
      } else {
        await ApiDatabase.insertEventParameter(p);
      }
    }

    await _loadEvents();
  }

  Future<void> _deleteEvent(int id) async {
    await ApiDatabase.deleteEvent(id);
    _loadEvents();
  }

  Future<SCEvent> updateABI(SCEvent event) async {
    final parameters = await ApiDatabase.getParametersForEvent(event.id!);

    final abi = jsonEncode([
      {
        "anonymous": event.anonymous,
        "inputs": parameters
            .map((e) => {
                  "indexed": e.indexed,
                  "name": e.name,
                  "type": e.type,
                })
            .toList(),
        "name": event.name,
        "type": "event"
      }
    ]);


    final updatedEvent = SCEvent(
      id: event.id,
      contractId: event.contractId,
      name: event.name,
      abi: abi,
      anonymous: event.anonymous,
      subscribed: true,
    );

    await ApiDatabase.updateEvent(updatedEvent);

    return updatedEvent;
  }

  Future<void> _subscribeToEvent(SCEvent event) async {
    SCEvent updatedEvent = await updateABI(event);
    await ApiDatabase.updateEvent(updatedEvent);
    await EventSubscriptionService.startListeningForEvent(updatedEvent);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscribed to event successfully!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _showLogsForEvent(SCEvent event) async {
    final parameters = await ApiDatabase.getParametersForEvent(event.id!);
    final EthereumAddress contractAddress = EthereumAddress.fromHex(widget.apiService.address);
    final rpcUrl = 'https://${widget.apiService.ip}:${widget.apiService.port}';

    if(event.abi == "") {
      event = await updateABI(event);
    }

    final DeployedContract contract = DeployedContract(
      ContractAbi.fromJson(event.abi, event.name),
      contractAddress,
    );

    final eventDefinition = contract.event(event.name);

    final client = Web3Client(rpcUrl, Client());
    final latestBlock = await client.getBlockNumber();
    final fromBlock = latestBlock - 5000;

    final filter = FilterOptions.events(
      contract: contract,
      event: eventDefinition,
      fromBlock: BlockNum.exact(fromBlock),
      toBlock: BlockNum.exact(latestBlock),
    );

    final logs = await client.getLogs(filter);

    if (logs.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('Logs for ${event.name}'),
          content: Text('No logs found for this event.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    final decodedLogsWithTimestamps = <Map<String, dynamic>>[];

    for (final log in logs) {
      final decoded = eventDefinition.decodeResults(log.topics!, log.data!);
      final labelValuePairs = <String>[];

      for (int i = 0; i < decoded.length; i++) {
        final paramName = parameters[i].name;
        labelValuePairs.add('$paramName: ${decoded[i]}');
      }

      final blockNumberHex = '0x${log.blockNum!.toRadixString(16)}';
      final blockInfo = await client.getBlockInformation(blockNumber: blockNumberHex);

      decodedLogsWithTimestamps.add({
        'timestamp': blockInfo.timestamp,
        'content': '⏱ Emitted at: ${DateFormat('yyyy-MM-dd HH:mm').format(blockInfo.timestamp.toLocal())}\n${labelValuePairs.join('\n')}\n',
      });
    }

    // Sort by timestamp descending
    decodedLogsWithTimestamps.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    // Convert to list of strings
    final decodedLogs = decodedLogsWithTimestamps.map((e) => e['content'] as String).toList();

    // Display the decoded logs in a dialog
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Logs for ${event.name}'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 1.5,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: decodedLogs.map((log) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(log),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Divider(),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList() {
    return Column(
      children: _events.map((event) {
        return ListTile(
          title: Text(event.name),
          trailing: Wrap(
            spacing: 8,
            children: [
              IconButton(
                icon: const Icon(Icons.list),
                tooltip: 'View Logs',
                onPressed: () => _showLogsForEvent(event),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_active_outlined),
                tooltip: 'Subscribe',
                onPressed: () => _subscribeToEvent(event),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editEvent(event),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _deleteEvent(event.id!),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }


  Widget _buildAddEventField() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _eventNameController,
            decoration: const InputDecoration(labelText: 'Event Name'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            final name = _eventNameController.text.trim();
            if (name.isNotEmpty) {
              _addEvent(name);
            }
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildAddEventField(),
          const SizedBox(height: 12),
          Expanded(child: SingleChildScrollView(child: _buildEventList())),
        ],
      ),
    );
  }
}
