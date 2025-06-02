class Contract {
  final int? id;
  final String address;
  final String title;
  final String description;
  final String icon;
  final String ip;
  final int port;
  final int chainID;
  final DateTime lastAccess;

  Contract({
    this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.ip,
    required this.port,
    required this.lastAccess,
    required this.address, 
    required this.chainID,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'title': title,
      'description': description,
      'icon': icon,
      'ip': ip,
      'port': port,
      'chainID': chainID,
      'lastAccess': lastAccess.toIso8601String(),
    };
  }

  static Contract fromMap(Map<String, dynamic> map) {
    return Contract(
      id: map['id'],
      address: map['address'],
      title: map['title'],
      description: map['description'],
      icon: map['icon'],
      ip: map['ip'],
      port: map['port'],
      chainID: map['chainID'],
      lastAccess: DateTime.parse(map['lastAccess']),
    );
  }
}
