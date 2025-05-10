import 'package:flutter/material.dart';
import 'baseScaffold.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePage createState() => _HomePage();
}

class _HomePage extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  final List<Map<String, String>> items = [
    {"title": "Apple", "image": "https://upload.wikimedia.org/wikipedia/commons/1/15/Red_Apple.jpg"},
    {"title": "Banana", "image": "https://upload.wikimedia.org/wikipedia/commons/8/8a/Banana-Single.jpg"},
    {"title": "Cherry", "image": "https://upload.wikimedia.org/wikipedia/commons/b/bb/Cherry_Stella444.jpg"},
    {"title": "Date", "image": "https://upload.wikimedia.org/wikipedia/commons/1/15/Red_Apple.jpg"},
    {"title": "Elderberry", "image": "https://upload.wikimedia.org/wikipedia/commons/1/15/Red_Apple.jpg"},
    {"title": "Fig", "image": "https://upload.wikimedia.org/wikipedia/commons/1/15/Red_Apple.jpg"},
    {"title": "Grape", "image": "https://upload.wikimedia.org/wikipedia/commons/1/15/Red_Apple.jpg"},
    {"title": "Honeydew", "image": "https://upload.wikimedia.org/wikipedia/commons/1/15/Red_Apple.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> filteredItems = items
        .where((item) =>
            item["title"]!.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

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
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
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
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      double imageSize = constraints.maxWidth * 0.7; // relative sizing

                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(
                              filteredItems[index]["image"]!,
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              filteredItems[index]["title"]!,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
          ),
        ],
      ),
    );
  }
}
