class SCFunction {
  final int? id;
  final int serviceId;
  final String name;
  final String stateMutability;
  final bool payable;

  SCFunction({
    this.id,
    required this.serviceId,
    required this.name,
    required this.stateMutability,
    required this.payable,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_id': serviceId,
      'name': name,
      'state_mutability': stateMutability,
      'payable': payable ? 1 : 0,
    };
  }

  factory SCFunction.fromMap(Map<String, dynamic> map) {
    return SCFunction(
      id: map['id'],
      serviceId: map['service_id'],
      name: map['name'],
      stateMutability: map['state_mutability'] ?? 'empty',
      payable: map['payable'] == 1 || map['payable'] == true,
    );
  }
}
