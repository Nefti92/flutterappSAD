import 'package:cdapp/models/api_database.dart';
import 'package:cdapp/models/contract_event_model.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';
import 'dart:async';

class EventSubscriptionService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final Map<int, StreamSubscription> _subscriptions = {};

  static Future<void> initialize() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    final InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(settings);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> startListeningForEvent(SCEvent event) async {
    if (_subscriptions.containsKey(event.id)) return;

    final service = await ApiDatabase.getContractById(event.contractId);
    if (service == null) return;

    final rpcUrl = 'https://${service.ip}:${service.port}';
    final contractAddress = service.address;

    final client = Web3Client(rpcUrl, Client());
    print(event.abi);
    final contract = DeployedContract(
      ContractAbi.fromJson(event.abi, event.name),
      EthereumAddress.fromHex(contractAddress),
    );

    final eventDefinition = contract.event(event.name);

    final subscription = client
        .events(FilterOptions.events(contract: contract, event: eventDefinition))
        .listen((log) async {
      await _notificationsPlugin.show(
        0,
        'Event Triggered',
        '${event.name} was emitted',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'event_channel',
            'Contract Events',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    });

    _subscriptions[event.id!] = subscription;
  }

  static Future<void> stopListeningForEvent(int eventId) async {
    final subscription = _subscriptions[eventId];
    await subscription?.cancel();
    _subscriptions.remove(eventId);
  }

  static Future<void> startListeningForSubscribedEvents() async {
    final subscribedEvents = await ApiDatabase.getSubscribedEvents();
    for (final event in subscribedEvents) {
      await startListeningForEvent(event);
    }
  }
}
