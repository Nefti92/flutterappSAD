import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cdapp/models/api_service_database.dart';
import 'package:cdapp/models/api_service_model.dart';
import 'package:cdapp/models/api_response_model.dart';
import 'baseScaffold.dart';

class ApiDetailPage extends StatefulWidget {
  final ApiService apiService;

  const ApiDetailPage({Key? key, required this.apiService}) : super(key: key);

  @override
  _ApiDetailPageState createState() => _ApiDetailPageState();
}

class _ApiDetailPageState extends State<ApiDetailPage> {
  final TextEditingController _uriController = TextEditingController();
  String _selectedType = 'Detect Type';
  bool _isLoading = false;
  String _responseData = '';
  List<ApiResponse> _previousResponses = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';


  @override
  void initState() {
    super.initState();
    _loadSavedResponses();
  }

  Future<void> _loadSavedResponses() async {
    final rows = await ApiDatabase.getResponsesForService(widget.apiService.id!);
    setState(() {
      _previousResponses = rows.map((e) => ApiResponse.fromMap(e)).toList();
    });
  }

  Future<void> _fetchData() async {
    if (_uriController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An URI is needed to perform the request')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _responseData = '';
    });

    final String url =
        'http://${widget.apiService.ip}:${widget.apiService.port}${_uriController.text}';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          _responseData = response.body;
        });

        final newResponse = ApiResponse(
          serviceId: widget.apiService.id!,
          uri: _uriController.text,
          type: _selectedType,
          response: response.body,
          timestamp: DateTime.now(),
        );

        await ApiDatabase.insertResponseModel(newResponse);
        await _loadSavedResponses();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildFormattedResponse(ApiResponse response) {
    switch (response.type) {
      case 'Image':
        try {
          Uint8List imageBytes = base64Decode(response.response);
          return Image.memory(imageBytes, height: 200);
        } catch (e) {
          return const Text('Errore durante la decodifica dell\'immagine.');
        }

      case 'Tabular':
        try {
          final List<dynamic> jsonList = jsonDecode(response.response);
          if (jsonList.isEmpty) return const Text('Nessun dato tabellare disponibile.');

          final headers = (jsonList[0] as Map).keys.toList();

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
              rows: jsonList.map<DataRow>((item) {
                return DataRow(
                  cells: headers.map((h) => DataCell(Text(item[h].toString()))).toList(),
                );
              }).toList(),
            ),
          );
        } catch (e) {
          return const Text('Errore nella visualizzazione tabellare.');
        }

      case 'Text':
      default:
        return Text(response.response);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScaffold(
      currentIndex: 2,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(  
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  IconData(int.parse(widget.apiService.icon), fontFamily: 'MaterialIcons'),
                  size: 30,
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.apiService.title,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.apiService.description,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _uriController,
              decoration: const InputDecoration(labelText: 'URI'),
            ),
            const SizedBox(height: 20),

            // Row 1: Detect Type + Text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['Detect Type', 'Text'].map((type) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: type,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    Text(type),
                    const SizedBox(width: 16),
                  ],
                );
              }).toList(),
            ),

            // Row 2: Image + Tabular
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: ['Image', 'Tabular'].map((type) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<String>(
                      value: type,
                      groupValue: _selectedType,
                      onChanged: (value) {
                        setState(() {
                          _selectedType = value!;
                        });
                      },
                    ),
                    Text(type),
                    const SizedBox(width: 16),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Centered Request Button
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cloud_download),
                label: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Request Data'),
                onPressed: _isLoading ? null : _fetchData,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),


            const Divider(height: 32),

            /// SEARCH BAR + RESPONSE LIST TITLE
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: const InputDecoration(
                hintText: 'Search in data...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: _previousResponses.where((r) {
                  final content = '${r.uri} ${r.type} ${r.response} ${r.timestamp}';
                  return content.toLowerCase().contains(_searchQuery.toLowerCase());
                }).length,
                itemBuilder: (context, index) {
                  final filteredResponses = _previousResponses.where((r) {
                    final content = '${r.uri} ${r.type} ${r.response} ${r.timestamp}';
                    return content.toLowerCase().contains(_searchQuery.toLowerCase());
                  }).toList();

                  final r = filteredResponses[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('URI: ${r.uri}'),
                          Text('Tipo: ${r.type}', style: const TextStyle(fontStyle: FontStyle.italic)),
                          const SizedBox(height: 6),
                          _buildFormattedResponse(r),
                          const SizedBox(height: 6),
                          Text(
                            'Salvato: ${r.timestamp.toLocal()}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
      )
    );
  }
}
