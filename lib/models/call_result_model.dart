class CallResult {
  final int? id;
  final int functionId;
  final String contractAddress;
  final String functionName;
  final String result;
  final DateTime timestamp;

  CallResult({
    this.id,
    required this.functionId,
    required this.contractAddress,
    required this.functionName,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'function_id': functionId,
    'contract_address': contractAddress,
    'function_name': functionName,
    'result': result,
    'timestamp': timestamp.toIso8601String(),
  };

  factory CallResult.fromMap(Map<String, dynamic> map) => CallResult(
    id: map['id'],
    functionId: map['function_id'],
    contractAddress: map['contract_address'],
    functionName: map['function_name'],
    result: map['result'],
    timestamp: DateTime.parse(map['timestamp']),
  );
}
