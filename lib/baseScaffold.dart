import 'package:flutter/material.dart';
import 'apiServicesPage.dart';
import 'homePage.dart';
import 'main.dart';

class BaseScaffold extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Widget? floatingActionButton;

  const BaseScaffold({
    required this.body,
    required this.currentIndex,
    this.floatingActionButton,
    super.key,
  });

  void _onTabTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = const MyApp();
      case 1:
        page = const HomePage();
      case 2:
        page = const ApiServicesPage();
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onTabTapped(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.logout),
            label: 'Logout',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.api),
            label: 'API',
          ),
        ],
      ),
    );
  }
}
