class SCFunction {
  final int? id;
  final int serviceId;
  final String name;

  SCFunction({
    this.id,
    required this.serviceId,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_id': serviceId,
      'name': name,
    };
  }

  factory SCFunction.fromMap(Map<String, dynamic> map) {
    return SCFunction(
      id: map['id'],
      serviceId: map['service_id'],
      name: map['name'],
    );
  }
}
