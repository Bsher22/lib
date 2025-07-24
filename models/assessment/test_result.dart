// lib/models/assessment/test_result.dart
class TestResult {
  final String id;
  final String playerId;
  final String testId;
  final String testName;
  final String testType;
  final double result;
  final String? units;
  final DateTime timestamp;
  final Map<String, dynamic>? additionalData;
  
  TestResult({
    required this.id,
    required this.playerId,
    required this.testId,
    required this.testName,
    required this.testType,
    required this.result,
    this.units,
    required this.timestamp,
    this.additionalData,
  });
  
  factory TestResult.fromJson(Map<String, dynamic> json) {
    return TestResult(
      id: json['id'],
      playerId: json['player_id'],
      testId: json['test_id'],
      testName: json['test_name'],
      testType: json['test_type'],
      result: (json['result'] as num).toDouble(),
      units: json['units'],
      timestamp: DateTime.parse(json['timestamp']),
      additionalData: json['additional_data'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_id': playerId,
      'test_id': testId,
      'test_name': testName,
      'test_type': testType,
      'result': result,
      'units': units,
      'timestamp': timestamp.toIso8601String(),
      'additional_data': additionalData,
    };
  }
}