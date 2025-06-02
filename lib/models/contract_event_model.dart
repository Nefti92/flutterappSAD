class SCEvent {
  final int? id;
  final int contractId;
  final String name;
  final String abi;
  final bool anonymous;
  final bool subscribed;

  SCEvent({
    this.id,
    required this.contractId,
    required this.name,
    this.abi = "",
    required this.anonymous,
    this.subscribed = false,
  });

  factory SCEvent.fromMap(Map<String, dynamic> map) => SCEvent(
    id: map['id'],
    contractId: map['contract_id'],
    name: map['name'],
    abi: map['abi'],
    anonymous: map['anonymous'] == 1,
    subscribed: map['subscribed'] == 1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'contract_id': contractId,
    'name': name,
    'abi': abi,
    'anonymous': anonymous ? 1 : 0,
    'subscribed': subscribed ? 1 : 0,
  };
}
