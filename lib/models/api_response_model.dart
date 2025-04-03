class ApiResponse {
  final int? id;
  final int serviceId;
  final String uri;
  final String type;
  final String response;
  final DateTime timestamp;

  ApiResponse({
    this.id,
    required this.serviceId,
    required this.uri,
    required this.type,
    required this.response,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'service_id': serviceId,
      'uri': uri,
      'type': type,
      'response': response,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static ApiResponse fromMap(Map<String, dynamic> map) {
    return ApiResponse(
      id: map['id'],
      serviceId: map['service_id'],
      uri: map['uri'],
      type: map['type'],
      response: map['response'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
