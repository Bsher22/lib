// lib/models/program_sequence.dart

class ProgramSequence {
  final int? id;
  final int programId;
  final int sequenceOrder;
  final int shotCount;
  final String shotType;
  final String targetZones;
  final String? description;

  ProgramSequence({
    this.id,
    required this.programId,
    required this.sequenceOrder,
    required this.shotCount,
    required this.shotType,
    required this.targetZones,
    this.description,
  });

  factory ProgramSequence.fromJson(Map<String, dynamic> json) {
    return ProgramSequence(
      id: json['id'],
      programId: json['program_id'],
      sequenceOrder: json['sequence_order'],
      shotCount: json['shot_count'],
      shotType: json['shot_type'],
      targetZones: json['target_zones'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'program_id': programId,
      'sequence_order': sequenceOrder,
      'shot_count': shotCount,
      'shot_type': shotType,
      'target_zones': targetZones,
      'description': description,
    };
  }
  
  // Helper method to get zones as a list of strings
  List<String> getTargetZonesList() {
    return targetZones.split(',');
  }
}