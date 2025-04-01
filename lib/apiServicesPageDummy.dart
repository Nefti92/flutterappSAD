import 'package:flutter/material.dart';
import 'baseScaffold.dart';
import 'package:intl/intl.dart'; // for formatting date

class ApiServicesPage extends StatefulWidget {
  const ApiServicesPage({super.key});

  @override
  State<ApiServicesPage> createState() => _ApiServicesPageState();
}

class _ApiServicesPageState extends State<ApiServicesPage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  final List<Map<String, dynamic>> services = [
    {
      'title': 'Weather API',
      'icon': Icons.cloud,
      'description': 'Provides current and forecasted weather data.',
      'lastAccess': DateTime.now().subtract(Duration(minutes: 10)),
    },
    {
      'title': 'Translation API',
      'icon': Icons.translate,
      'description': 'Translates text between languages.',
      'lastAccess': DateTime.now().subtract(Duration(hours: 3)),
    },
    {
      'title': 'Geolocation API',
      'icon': Icons.location_on,
      'description': 'Returns user location based on IP address.',
      'lastAccess': DateTime.now().subtract(Duration(hours: 1, minutes: 30)),
    },
    {
      'title': 'Finance API',
      'icon': Icons.attach_money,
      'description': 'Fetches stock and currency exchange rates.',
      'lastAccess': DateTime.now().subtract(Duration(minutes: 5)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredServices = services
        .where((s) =>
            s['title'].toLowerCase().contains(searchQuery.toLowerCase()) ||
            s['description'].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) => b['lastAccess'].compareTo(a['lastAccess']));

    return BaseScaffold(
      currentIndex: 2,
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
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: "Search APIs...",
                  border: InputBorder.none,
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredServices.length,
              itemBuilder: (context, index) {
                final api = filteredServices[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              api['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(api['icon'], color: Colors.deepOrange),
                        ],
                      ),
                      const Divider(height: 16, thickness: 1),
                      Text(
                        api['description'],
                        style: const TextStyle(fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Last accessed: ${DateFormat('yyyy-MM-dd HH:mm').format(api['lastAccess'])}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
