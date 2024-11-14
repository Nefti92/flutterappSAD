import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomTextField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final bool isObscure;
  final TextInputType keyboardType;
  final Color textColor;
  final Color hintColor;
  final double fontSize;
  final Color backgroundColor;
  final double borderWidth;
  final Color borderColor;
  final double height;
  final double width;

  const CustomTextField({
    Key? key,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.isObscure = false,
    this.keyboardType = TextInputType.text,
    this.hintColor = Colors.black,
    this.textColor = Colors.black,
    this.fontSize = 16.0,
    this.backgroundColor = Colors.white,
    this.borderWidth = 1.0,
    this.borderColor = Colors.grey,
    this.height = 60.0,
    this.width = double.infinity,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: backgroundColor, // Colore di sfondo del campo
        borderRadius: BorderRadius.circular(8.0), // Bordo arrotondato
        border: Border.all(
          color: borderColor,   // Colore del bordo
          width: borderWidth,   // Larghezza del bordo
        ),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintStyle: TextStyle(
            color: hintColor
          ),
          labelText: labelText,
          hintText: hintText,
          border: InputBorder.none, // Rimuove il bordo predefinito
          prefixIcon: Icon(prefixIcon),
          contentPadding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
        ),
        obscureText: isObscure,
        keyboardType: keyboardType,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

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
