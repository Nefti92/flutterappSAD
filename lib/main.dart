import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'customWidgets.dart';

var mail = 'admin';
var password = '1234';

void main() {
  // Avvio dell'App
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // costruttore dell'App
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Fornisce un'istanza di MyAppState a tutti i widget figli
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        // Nome dell'App
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          // Imposta il tema colore
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        // imposta la pagina iniziale dell'App
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  // Gestisce lo stato dell'app
  var current = WordPair.random();
}

class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Si ottiene la larghezza dello schermo
    var screenWidth = MediaQuery.of(context).size.width;
    var inputMail;
    var inputPassword;

    return Scaffold(
      body: Center(
        child: Column(
          // Centra gli elementi verticalmente
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            
            // Titolo della pagina di Login
            Text('Login', 
              style: TextStyle(
                color: Color.fromRGBO(0, 0, 0, 1),
                fontSize: 30,
              ),
              selectionColor: Color.fromRGBO(0, 0, 0, 1),
            ),

            // Separatore
            SizedBox(height: 10),

            // Widget personalizzato per l'inserimento della e-mail
            CustomTextField(
              // Titolo del widget
              labelText: 'E-mail',
              // 'consiglio' visualizzato per la scrittura
              hintText: 'Inserisci la tua email',
              // Icona
              prefixIcon: Icons.email,
              // Tipologia di scrittura permessa
              keyboardType: TextInputType.emailAddress,
              // Funzione di lettura del testo scritto
              onChanged: (value){
                if(value != null) {
                  inputMail = value;
                }
              },
              // Colore del 'consiglio'
              hintColor: const Color.fromRGBO(0, 0, 0, 0.3),
              // Colore del bordo della cella
              borderColor: const Color.fromRGBO(255, 204, 128, 1),
              // Altezza della cella
              height: 70,
              // Largheza della cella
              width: screenWidth*0.93,
            ),

            // Separatore
            SizedBox(height: 10),

            
            // Widget personalizzato per l'inserimento della password
            CustomTextField(
              labelText: 'Password',
              hintText: 'Inserisci la tua password',
              prefixIcon: Icons.lock,
              onChanged: (value){
                if(value != null) {
                  inputPassword = value;
                }
              },
              isObscure: true,
              hintColor: const Color.fromRGBO(0, 0, 0, 0.3),
              borderColor: const Color.fromRGBO(255, 204, 128, 1),
              height: 70,
              width: screenWidth*0.93,
            ),
            
            // Separatore
            SizedBox(height: 15),
            
            // Pulsante per verificare le credenziali
            ElevatedButton(
              onPressed: () {
                print('password: ${inputPassword}, ${password}');
                print('email: ${inputMail}, ${mail}');
                if(mail == inputMail && password == inputPassword) {
                  print('loggato!');
                }
              },
              child: Text('Accedi'),
            ),
          ],
        ),
      ),
    );
  }
}
