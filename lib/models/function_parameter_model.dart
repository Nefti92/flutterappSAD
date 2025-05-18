class FuncParameter {
  final int? id;
  final int functionId;
  String name; 
  String type;

  FuncParameter({
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

  factory FuncParameter.fromMap(Map<String, dynamic> map) => FuncParameter(
    id: map['id'],
    functionId: map['function_id'],
    name: map['name'],
    type: map['type'],
  );
}
