import 'package:cdapp/models/api_database.dart';
import 'package:cdapp/models/call_result_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'baseScaffold.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  late Future<List<CallResult>>? _futureResults = ApiDatabase.getAllCallResultsSorted();
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 1,
      body: Column(
        children: [
          AppBar(
            automaticallyImplyLeading: false,
            title: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search...",
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(vertical: 5),
                ),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CallResult>>(
              future: _futureResults,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final filtered = snapshot.data!
                    .where((result) => result.functionName.toLowerCase().contains(searchQuery.toLowerCase()))
                    .toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('Recent Results Not Available'));
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final res = filtered[index];
                    final resultText = filtered[index].result;
                    final imageUrlPattern = RegExp(r'(https?:\/\/.*\.(?:png|jpg|jpeg|gif|webp))', caseSensitive: false);
                    final match = imageUrlPattern.firstMatch(resultText);
                    final imageUrl = match?.group(0);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Function: ${res.functionName}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    await ApiDatabase.deleteCallResult(res.id!);
                                    setState(() {
                                      _futureResults = ApiDatabase.getAllCallResultsSorted();
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Contract: ${res.contractAddress}'),
                            const SizedBox(height: 4),
                            if (imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 9),
                                child: Center(
                                  child: Image.network(
                                    imageUrl,
                                    height: 200,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Text(resultText),
                                  ),
                                ),
                              )
                            else
                              Text('Result: $resultText'),

                            const SizedBox(height: 4),
                            Text('Time: ${DateFormat('yyyy-MM-dd HH:mm').format(res.timestamp.toLocal())}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }
}
