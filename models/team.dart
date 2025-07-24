// models/team.dart
import 'package:flutter/foundation.dart';

class Team {
  final int? id;
  final String name;
  final String? description;
  final String? logoPath;
  final DateTime? createdAt;
  final int playerCount;
  final String? level;
  final String? division;
  final String? logo;
  final String? ageGroup;  // ✅ ADD THIS LINE
  final String? status;    // ✅ ADD THIS LINE

  Team({
    this.id,
    required this.name,
    this.description,
    this.logoPath,
    this.createdAt,
    this.playerCount = 0,
    this.level,
    this.division,
    this.logo,
    this.ageGroup,           // ✅ ADD THIS LINE
    this.status = 'Active',  // ✅ ADD THIS LINE
  });

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      logoPath: json['logo_path'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      playerCount: json['player_count'] ?? 0,
      level: json['level'],
      division: json['division'],
      logo: json['logo'] ?? json['logo_path'],
      ageGroup: json['age_group'],        // ✅ ADD THIS LINE
      status: json['status'] ?? 'Active', // ✅ ADD THIS LINE
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_path': logoPath,
      'created_at': createdAt?.toIso8601String(),
      'player_count': playerCount,
      'level': level,
      'division': division,
      'logo': logo ?? logoPath,
      'age_group': ageGroup,    // ✅ ADD THIS LINE
      'status': status,         // ✅ ADD THIS LINE
    };
  }

  Team copyWith({
    int? id,
    String? name,
    String? description,
    String? logoPath,
    DateTime? createdAt,
    int? playerCount,
    String? level,
    String? division,
    String? logo,
    String? ageGroup,         // ✅ ADD THIS LINE
    String? status,           // ✅ ADD THIS LINE
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoPath: logoPath ?? this.logoPath,
      createdAt: createdAt ?? this.createdAt,
      playerCount: playerCount ?? this.playerCount,
      level: level ?? this.level,
      division: division ?? this.division,
      logo: logo ?? this.logo,
      ageGroup: ageGroup ?? this.ageGroup,   // ✅ ADD THIS LINE
      status: status ?? this.status,         // ✅ ADD THIS LINE
    );
  }

  @override
  String toString() {
    return 'Team(id: $id, name: $name, level: $level, division: $division, ageGroup: $ageGroup, status: $status, playerCount: $playerCount)';
  }
}