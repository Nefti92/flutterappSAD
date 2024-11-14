import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'customWidgets.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();

  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();  
    var screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Login', 
              style: TextStyle(
                color: Color.fromRGBO(0, 0, 0, 1), // Imposta il colore del testo
                fontSize: 30, // Imposta la dimensione del testo
              ),
              selectionColor: Color.fromRGBO(0, 0, 0, 1),
            ),
            SizedBox(height: 10),
            CustomTextField(
              labelText: 'E-mail',
              hintText: 'Inserisci la tua email',
              prefixIcon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              hintColor: const Color.fromRGBO(0, 0, 0, 0.3),
              borderColor: const Color.fromRGBO(255, 204, 128, 1),
              height: 70,
              width: screenWidth*0.93,
            ),
            SizedBox(height: 10),
            CustomTextField(
              labelText: 'Password',
              hintText: 'Inserisci la tua password',
              prefixIcon: Icons.lock,
              isObscure: true,
              hintColor: const Color.fromRGBO(0, 0, 0, 0.3),
              borderColor: const Color.fromRGBO(255, 204, 128, 1),
              height: 70,
              width: screenWidth*0.93,
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                appState.getNext();
              },
              child: Text('Accedi'),
            ),
          ],
        ),
      ),
    );
  }
}
