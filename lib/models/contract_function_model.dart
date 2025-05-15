class ContractFunction {
  final int? id;
  final int serviceId;
  final String name;

  ContractFunction({
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

  factory ContractFunction.fromMap(Map<String, dynamic> map) {
    return ContractFunction(
      id: map['id'],
      serviceId: map['service_id'],
      name: map['name'],
    );
  }
}
