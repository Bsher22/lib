// lib/models/shot.dart
class Shot {
  final int id;
  final int playerId;
  final String zone;
  final String type;
  final bool success;
  final String? outcome;
  final DateTime timestamp;
  final double? power;
  final double? quickRelease;
  final String? workout;
  final String? videoPath;
  final String source;
  final int? workoutId;
  final String? assessmentId;
  final String? sessionNotes;
  
  // Group tracking fields for targeted progress analysis
  final int? groupIndex;        // Which assessment group this shot belongs to (0, 1, 2, etc.)
  final String? groupId;        // Optional group identifier
  final String? intendedZone;   // What zone the player was aiming for
  final String? intendedDirection; // NEW: Directional intent (North, South, East, West, Center)

  Shot({
    required this.id,
    required this.playerId,
    required this.zone,
    required this.type,
    required this.success,
    this.outcome,
    required this.timestamp,
    this.power,
    this.quickRelease,
    this.workout,
    this.videoPath,
    required this.source,
    this.workoutId,
    this.assessmentId,
    this.sessionNotes,
    // Group tracking parameters
    this.groupIndex,
    this.groupId,
    this.intendedZone,
    this.intendedDirection,  // NEW
  });

  factory Shot.fromJson(Map<String, dynamic> json) {
    return Shot(
      id: int.tryParse(json['id'].toString()) ?? 0,
      playerId: int.tryParse(json['player_id'].toString()) ?? 0,
      zone: json['zone']?.toString() ?? '0', // Convert to string, default to '0'
      type: json['type'] as String? ?? 'Unknown', // Default to 'Unknown'
      success: json['success'] == 1 || json['success'] == true,
      outcome: json['outcome'] as String? ?? 'Unknown', // Default to 'Unknown'
      // ✅ FIXED: Handle both 'date' and 'timestamp' for backward compatibility
      timestamp: json['date'] != null 
          ? DateTime.parse(json['date'] as String)
          : DateTime.parse(json['timestamp'] as String? ?? DateTime.now().toIso8601String()),
      power: (json['power'] as num?)?.toDouble(),
      quickRelease: (json['quick_release'] as num?)?.toDouble(),
      workout: json['workout'] as String?,
      videoPath: json['video_path'] as String?,
      source: json['source'] as String? ?? 'individual',
      workoutId: json['workout_id'] != null ? int.tryParse(json['workout_id'].toString()) : null,
      assessmentId: json['assessment_id']?.toString(),
      sessionNotes: json['notes'] as String?, // Map 'notes' to sessionNotes
      // Group tracking fields from JSON
      groupIndex: json['group_index'] != null ? int.tryParse(json['group_index'].toString()) : null,
      groupId: json['group_id']?.toString(),
      intendedZone: json['intended_zone']?.toString(),
      intendedDirection: json['intended_direction']?.toString(), // NEW
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'player_id': playerId,
        'zone': zone,
        'type': type,
        'success': success ? 1 : 0,
        'outcome': outcome,
        'date': timestamp.toIso8601String(), // ✅ CORRECT: Use 'date' instead of 'timestamp'
        'power': power,
        'quick_release': quickRelease,
        'workout': workout,
        'video_path': videoPath,
        'source': source,
        'workout_id': workoutId,
        'assessment_id': assessmentId,
        'session_notes': sessionNotes,
        // Group tracking fields
        'group_index': groupIndex,
        'group_id': groupId,
        'intended_zone': intendedZone,
        'intended_direction': intendedDirection, // NEW
      };

  Shot copyWith({
    int? workoutId, 
    String? assessmentId,
    int? groupIndex,
    String? groupId,
    String? intendedZone,
    String? intendedDirection, // NEW
  }) {
    return Shot(
      id: id,
      playerId: playerId,
      zone: zone,
      type: type,
      success: success,
      outcome: outcome,
      timestamp: timestamp,
      power: power,
      quickRelease: quickRelease,
      workout: workout,
      videoPath: videoPath,
      source: source,
      workoutId: workoutId ?? this.workoutId,
      assessmentId: assessmentId ?? this.assessmentId,
      sessionNotes: sessionNotes,
      // Group tracking in copyWith
      groupIndex: groupIndex ?? this.groupIndex,
      groupId: groupId ?? this.groupId,
      intendedZone: intendedZone ?? this.intendedZone,
      intendedDirection: intendedDirection ?? this.intendedDirection, // NEW
    );
  }

  /// Helper methods
  bool get isFromWorkout => source == 'workout';
  bool get isFromAssessment => source == 'assessment';
  bool get isIndividual => source == 'individual';

  // Group tracking helper methods
  bool get hasGroupTracking => groupIndex != null;
  bool get hasIntendedZone => intendedZone != null && intendedZone!.isNotEmpty;
  bool get hasIntendedDirection => intendedDirection != null && intendedDirection!.isNotEmpty; // NEW
  
  /// Check if this shot hit the intended zone
  bool get hitIntendedZone {
    if (!hasIntendedZone) return false;
    return zone == intendedZone;
  }
  
  /// NEW: Check if this shot hit the intended direction (any zone in that direction)
  bool get hitIntendedDirection {
    if (!hasIntendedDirection) return false;
    
    switch (intendedDirection!.toLowerCase()) {
      case 'north':
        return ['1', '2', '3'].contains(zone);
      case 'south':
        return ['7', '8', '9'].contains(zone);
      case 'east':
        return ['3', '6', '9'].contains(zone);
      case 'west':
        return ['1', '4', '7'].contains(zone);
      case 'center':
        return ['2', '5', '8'].contains(zone);
      default:
        return false;
    }
  }
  
  /// Get the zone accuracy type for this shot
  String get zoneAccuracyType {
    if (!hasIntendedZone && !hasIntendedDirection) return 'no_target';
    
    if (zone.startsWith('miss_')) {
      return 'miss';
    } else if (hasIntendedZone && zone == intendedZone) {
      return 'intended_hit';
    } else if (hasIntendedDirection && hitIntendedDirection) {
      return 'direction_hit';
    } else {
      return 'zone_miss'; // Hit net but wrong zone/direction
    }
  }
  
  /// Check if this is a miss shot (missed the net entirely)
  bool get isMissShot => zone.startsWith('miss_');
  
  /// Get miss direction if this is a miss shot
  String? get missDirection {
    if (!isMissShot) return null;
    
    switch (zone) {
      case 'miss_left': return 'left';
      case 'miss_high': return 'high';
      case 'miss_right': return 'right';
      default: return null;
    }
  }
  
  /// Get a description of the shot for progress tracking
  String get progressDescription {
    if (isMissShot) {
      return 'Miss ${missDirection ?? 'unknown'}';
    } else if (hasIntendedDirection) {
      if (hitIntendedDirection) {
        return 'Hit $intendedDirection direction (zone $zone)';
      } else {
        return 'Hit zone $zone (target: $intendedDirection)';
      }
    } else if (hasIntendedZone) {
      return hitIntendedZone 
        ? 'Hit target zone $zone' 
        : 'Hit zone $zone (target: $intendedZone)';
    } else {
      return 'Hit zone $zone';
    }
  }

  /// NEW: Get directional accuracy description
  String get directionAccuracyDescription {
    if (!hasIntendedDirection) return progressDescription;
    
    if (isMissShot) {
      return 'Miss ${missDirection ?? 'unknown'} (target: $intendedDirection)';
    } else if (hitIntendedDirection) {
      return '🎯 Hit $intendedDirection direction!';
    } else {
      return '📍 Off direction (hit zone $zone, target: $intendedDirection)';
    }
  }

  // Getter for source display name
  String get sourceDisplayName {
    switch (source.toLowerCase()) {
      case 'assessment':
        return 'Assessment';
      case 'workout':
        return 'Workout';
      case 'individual':
        return 'Individual';
      default:
        return source.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }
  
  /// Get display name for the group if available
  String? get groupDisplayName {
    if (groupIndex == null) return null;
    
    if (groupId != null && groupId!.isNotEmpty) {
      return 'Group ${groupIndex! + 1}: $groupId';
    } else {
      return 'Group ${groupIndex! + 1}';
    }
  }
  
  /// NEW: Get intended target display (direction or zone)
  String? get intendedTargetDisplay {
    if (hasIntendedDirection) {
      return '$intendedDirection Direction';
    } else if (hasIntendedZone) {
      return 'Zone $intendedZone';
    }
    return null;
  }
  
  /// NEW: Check if shot was successful based on intended target
  bool get hitIntendedTarget {
    if (hasIntendedDirection) {
      return success && hitIntendedDirection;
    } else if (hasIntendedZone) {
      return success && hitIntendedZone;
    }
    return success; // Fallback to basic success
  }
  
  /// ✅ FIXED: Create a shot data map for API submission (used in assessment execution)
  Map<String, dynamic> toApiData({
    required int playerId,
    required String assessmentId,
    int? groupIndex,
    String? groupId,
    String? intendedZone,
    String? intendedDirection, // NEW
    String? sessionNotes,
  }) {
    return {
      'player_id': playerId,
      'zone': zone,
      'type': type,
      'success': success,
      'outcome': outcome,
      'date': timestamp.toIso8601String(), // ✅ FIXED: Use 'date' instead of 'timestamp'
      'source': 'assessment',
      'assessment_id': assessmentId,
      if (power != null) 'power': power,
      if (quickRelease != null) 'quick_release': quickRelease,
      // Group tracking fields for API
      if (groupIndex != null) 'group_index': groupIndex,
      if (groupId != null) 'group_id': groupId,
      if (intendedZone != null) 'intended_zone': intendedZone,
      if (intendedDirection != null) 'intended_direction': intendedDirection, // NEW
      if (sessionNotes != null) 'notes': sessionNotes,
    };
  }
  
  /// NEW: Get zones that belong to a direction
  static List<String> getZonesForDirection(String direction) {
    switch (direction.toLowerCase()) {
      case 'north':
        return ['1', '2', '3'];
      case 'south':
        return ['7', '8', '9'];
      case 'east':
        return ['3', '6', '9'];
      case 'west':
        return ['1', '4', '7'];
      case 'center':
        return ['2', '5', '8'];
      default:
        return [];
    }
  }
  
  /// NEW: Get direction from zone number
  static List<String> getDirectionsForZone(String zone) {
    final directions = <String>[];
    
    if (['1', '2', '3'].contains(zone)) directions.add('North');
    if (['7', '8', '9'].contains(zone)) directions.add('South');
    if (['1', '4', '7'].contains(zone)) directions.add('West');
    if (['3', '6', '9'].contains(zone)) directions.add('East');
    if (['2', '5', '8'].contains(zone)) directions.add('Center');
    
    return directions;
  }
  
  @override
  String toString() {
    return 'Shot(id: $id, zone: $zone, type: $type, success: $success, '
           'groupIndex: $groupIndex, intendedZone: $intendedZone, intendedDirection: $intendedDirection)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is Shot &&
      other.id == id &&
      other.playerId == playerId &&
      other.zone == zone &&
      other.type == type &&
      other.success == success &&
      other.assessmentId == assessmentId &&
      other.groupIndex == groupIndex &&
      other.intendedDirection == intendedDirection;
  }
  
  @override
  int get hashCode {
    return id.hashCode ^
      playerId.hashCode ^
      zone.hashCode ^
      type.hashCode ^
      success.hashCode ^
      assessmentId.hashCode ^
      groupIndex.hashCode ^
      intendedDirection.hashCode;
  }
}