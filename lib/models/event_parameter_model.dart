class EventParameter {
  final int? id;
  final int eventId;
  String name;
  String type;
  bool indexed;

  EventParameter({
    this.id,
    required this.eventId,
    required this.name,
    required this.type,
    required this.indexed,
  });

  factory EventParameter.fromMap(Map<String, dynamic> map) => EventParameter(
    id: map['id'],
    eventId: map['event_id'],
    name: map['name'],
    type: map['type'],
    indexed: map['indexed'] == 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'event_id': eventId,
    'name': name,
    'type': type,
    'indexed': indexed ? 1 : 0,
  };
}
