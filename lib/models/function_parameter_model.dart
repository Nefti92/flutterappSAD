class FunctionParameter {
  final int? id;
  final int functionId;
  String name; 
  String type;

  FunctionParameter({
    this.id,
    required this.functionId,
    required this.name,
    required this.type,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'function_id': functionId,
    'name': name,
    'type': type,
  };

  factory FunctionParameter.fromMap(Map<String, dynamic> map) => FunctionParameter(
    id: map['id'],
    functionId: map['function_id'],
    name: map['name'],
    type: map['type'],
  );
}
