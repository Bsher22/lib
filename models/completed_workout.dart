class CompletedWorkout {
  final int id;
  final int playerId;
  final int programId;
  final String? programName;
  final DateTime dateCompleted;
  final int totalShots;
  final int successfulShots;
  final String? notes;

  CompletedWorkout({
    required this.id,
    required this.playerId,
    required this.programId,
    this.programName,
    required this.dateCompleted,
    required this.totalShots,
    required this.successfulShots,
    this.notes,
  });

  factory CompletedWorkout.fromJson(Map<String, dynamic> json) {
    return CompletedWorkout(
      id: json['id'],
      playerId: json['player_id'],
      programId: json['program_id'],
      programName: json['program_name'],
      dateCompleted: DateTime.parse(json['date_completed']),
      totalShots: json['total_shots'],
      successfulShots: json['successful_shots'],
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_id': playerId,
      'program_id': programId,
      'program_name': programName,
      'date_completed': dateCompleted.toIso8601String(),
      'total_shots': totalShots,
      'successful_shots': successfulShots,
      'notes': notes,
    };
  }
}