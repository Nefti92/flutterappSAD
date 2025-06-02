import 'dart:io';
import 'package:cdapp/eventSubscription.dart';
import 'package:cdapp/patternLockPage.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';

var mail = 'admin';
var password = '1234';

class DevHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? ctx) {
    final client = super.createHttpClient(ctx);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }
}


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TO REMOVE IN PRODUCTION
  HttpOverrides.global = DevHttpOverrides();
  // Gestione Notifiche Eventi 
  await EventSubscriptionService.initialize();
  await EventSubscriptionService.startListeningForSubscribedEvents();
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
        title: 'cdApp',
        theme: ThemeData(
          useMaterial3: true,
          // Imposta il tema colore
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        // imposta la pagina iniziale dell'App
        home: FutureBuilder<String?>(
          future: const FlutterSecureStorage().read(key: 'pattern_hash'),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final hasPattern = snapshot.data != null;
            return PatternLockScreen(isSettingPattern: !hasPattern);
          },
        ),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  // Gestisce lo stato dell'app
  var current = WordPair.random();
}