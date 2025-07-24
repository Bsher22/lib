// lib/models/training_program.dart

class TrainingProgram {
  final int? id;
  final String name;
  final String? description;
  final String difficulty;
  final String type;
  final String duration;
  final int totalShots;
  final DateTime createdAt;
  final int? estimatedDuration;  // Added field for duration in minutes

  TrainingProgram({
    this.id,
    required this.name,
    this.description,
    required this.difficulty,
    required this.type,
    required this.duration,
    required this.totalShots,
    required this.createdAt,
    this.estimatedDuration,
  });

  factory TrainingProgram.fromJson(Map<String, dynamic> json) {
    return TrainingProgram(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      difficulty: json['difficulty'],
      type: json['type'],
      duration: json['duration'],
      totalShots: json['total_shots'],
      createdAt: DateTime.parse(json['created_at']),
      estimatedDuration: json['estimated_duration'] ?? 
        (json['duration'] != null ? 
          int.tryParse(json['duration'].toString().replaceAll(RegExp(r'[^0-9]'), '')) : 
          null),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'difficulty': difficulty,
      'type': type,
      'duration': duration,
      'total_shots': totalShots,
      'created_at': createdAt.toIso8601String(),
      'estimated_duration': estimatedDuration,
    };
  }
}