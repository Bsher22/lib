// lib/models/shot_assessment.dart
import 'package:flutter/material.dart';

class ShotAssessment {
  final String id;
  final int playerId;
  final int? teamId;
  final String assessmentType;
  final String title;
  final String? description;
  final DateTime date;
  final String status;
  final Map<String, dynamic>? results;
  final Map<String, dynamic>? assessmentConfig;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Derived properties
  final String? playerName;
  final String? teamName;
  final int? shotCount;

  ShotAssessment({
    required this.id,
    required this.playerId,
    this.teamId,
    required this.assessmentType,
    required this.title,
    this.description,
    required this.date,
    required this.status,
    this.results,
    this.assessmentConfig,
    required this.createdAt,
    required this.updatedAt,
    this.playerName,
    this.teamName,
    this.shotCount,
  });

  factory ShotAssessment.fromJson(Map<String, dynamic> json) {
    return ShotAssessment(
      id: json['id']?.toString() ?? '',
      playerId: int.tryParse(json['player_id']?.toString() ?? '0') ?? 0,
      teamId: json['team_id'] != null ? int.tryParse(json['team_id'].toString()) : null,
      assessmentType: json['assessment_type']?.toString() ?? 'standard',
      title: json['title']?.toString() ?? 'Assessment',
      description: json['description']?.toString(),
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      status: json['status']?.toString() ?? 'draft',
      results: json['results'] as Map<String, dynamic>?,
      assessmentConfig: json['assessment_config'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      playerName: json['player_name']?.toString(),
      teamName: json['team_name']?.toString(),
      shotCount: json['shot_count'] != null ? int.tryParse(json['shot_count'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'player_id': playerId,
        'team_id': teamId,
        'assessment_type': assessmentType,
        'title': title,
        'description': description,
        'date': date.toIso8601String(),
        'status': status,
        'results': results,
        'assessment_config': assessmentConfig,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'player_name': playerName,
        'team_name': teamName,
        'shot_count': shotCount,
      };

  // Helper methods
  bool get isCompleted => status == 'completed';
  bool get isDraft => status == 'draft';
  bool get isInProgress => status == 'in_progress';

  // Get overall score from results
  double? get overallScore {
    if (results == null) return null;
    final score = results!['overallScore'];
    if (score is num) return score.toDouble();
    return null;
  }

  // Get success rate from results
  double? get successRate {
    if (results == null) return null;
    final rate = results!['overallRate'];
    if (rate is num) return rate.toDouble();
    return null;
  }

  // Get total shots from results or assessment config
  int get totalShots {
    if (shotCount != null) return shotCount!;
    if (results != null && results!['totalShots'] is num) {
      return (results!['totalShots'] as num).toInt();
    }
    if (assessmentConfig != null && assessmentConfig!['totalShots'] is num) {
      return (assessmentConfig!['totalShots'] as num).toInt();
    }
    return 0;
  }

  // Get successful shots from results
  int get successfulShots {
    if (results != null && results!['successfulShots'] is num) {
      return (results!['successfulShots'] as num).toInt();
    }
    final rate = successRate;
    if (rate != null) {
      return (totalShots * rate).round();
    }
    return 0;
  }

  // Get strengths from results
  List<String> get strengths {
    if (results == null || results!['strengths'] == null) return [];
    final strengthsData = results!['strengths'];
    if (strengthsData is List) {
      return strengthsData.map((s) => s.toString()).toList();
    }
    return [];
  }

  // Get improvements from results
  List<String> get improvements {
    if (results == null || results!['improvements'] == null) return [];
    final improvementsData = results!['improvements'];
    if (improvementsData is List) {
      return improvementsData.map((s) => s.toString()).toList();
    }
    return [];
  }

  // Get category scores from results
  Map<String, double> get categoryScores {
    if (results == null || results!['categoryScores'] == null) return {};
    final scoresData = results!['categoryScores'];
    if (scoresData is Map<String, dynamic>) {
      return scoresData.map((key, value) {
        final doubleValue = value is num ? value.toDouble() : 0.0;
        return MapEntry(key, doubleValue);
      });
    }
    return {};
  }

  // Get zone rates from results
  Map<String, double> get zoneRates {
    if (results == null || results!['zoneRates'] == null) return {};
    final ratesData = results!['zoneRates'];
    if (ratesData is Map<String, dynamic>) {
      return ratesData.map((key, value) {
        final doubleValue = value is num ? value.toDouble() : 0.0;
        return MapEntry(key, doubleValue);
      });
    }
    return {};
  }

  // Get shot type rates from results
  Map<String, double> get typeRates {
    if (results == null || results!['typeRates'] == null) return {};
    final ratesData = results!['typeRates'];
    if (ratesData is Map<String, dynamic>) {
      return ratesData.map((key, value) {
        final doubleValue = value is num ? value.toDouble() : 0.0;
        return MapEntry(key, doubleValue);
      });
    }
    return {};
  }

  // Get assessment groups from assessment config
  List<Map<String, dynamic>> get assessmentGroups {
    if (assessmentConfig == null || assessmentConfig!['groups'] == null) return [];
    final groupsData = assessmentConfig!['groups'];
    if (groupsData is List) {
      return groupsData.map((g) => Map<String, dynamic>.from(g)).toList();
    }
    return [];
  }

  // Get description for display
  String get displayDescription {
    if (description != null && description!.isNotEmpty) {
      return description!;
    }
    return _getDefaultDescription();
  }

  String _getDefaultDescription() {
    switch (assessmentType.toLowerCase()) {
      case 'comprehensive':
        return 'Complete assessment of all shot types and zones';
      case 'quick':
        return 'Brief assessment focused on primary shot types';
      case 'advanced':
        return 'Detailed assessment with advanced metrics and analysis';
      default:
        return 'Shot assessment to evaluate shooting performance';
    }
  }

  // Get performance level description
  String get performanceLevel {
    final score = overallScore;
    if (score == null) return 'Not Rated';
    
    if (score >= 8.5) return 'Excellent';
    if (score >= 7.0) return 'Very Good';
    if (score >= 5.5) return 'Good';
    if (score >= 4.0) return 'Average';
    if (score >= 2.5) return 'Below Average';
    return 'Needs Improvement';
  }

  // Get formatted date string
  String get formattedDate {
    return '${date.month}/${date.day}/${date.year}';
  }

  // Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else {
      return 'Today';
    }
  }

  // Getter for assessment type display name
  String get assessmentTypeDisplayName {
    switch (assessmentType.toLowerCase()) {
      case 'comprehensive':
        return 'Comprehensive';
      case 'quick':
        return 'Quick';
      case 'advanced':
        return 'Advanced';
      case 'wrist_shot':
        return 'Wrist Shot';
      case 'slap_shot':
        return 'Slap Shot';
      case 'snap_shot':
        return 'Snap Shot';
      default:
        return assessmentType.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  // Getter for overall success rate
  double get overallSuccessRate {
    final rate = successRate;
    if (rate != null) return rate;
    if (results != null && results!['successfulShots'] is num && totalShots > 0) {
      return (results!['successfulShots'] as num).toDouble() / totalShots;
    }
    return 0.0;
  }

  // Getter for performance color based on success rate
  Color get performanceColor {
    final rate = overallSuccessRate;
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.lightGreen;
    if (rate >= 0.4) return Colors.orange;
    if (rate >= 0.2) return Colors.deepOrange;
    return Colors.red;
  }

  // Getter for status display name
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'draft':
        return 'Draft';
      default:
        return status.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  // Getter to check if zone data is available
  bool get hasZoneData {
    return results != null && results!['zoneRates'] != null && zoneRates.isNotEmpty;
  }

  // Getter for zone success rates
  Map<String, double> get zoneSuccessRates {
    return zoneRates;
  }

  // Copy with method for updates
  ShotAssessment copyWith({
    String? id,
    int? playerId,
    int? teamId,
    String? assessmentType,
    String? title,
    String? description,
    DateTime? date,
    String? status,
    Map<String, dynamic>? results,
    Map<String, dynamic>? assessmentConfig,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? playerName,
    String? teamName,
    int? shotCount,
  }) {
    return ShotAssessment(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      teamId: teamId ?? this.teamId,
      assessmentType: assessmentType ?? this.assessmentType,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      status: status ?? this.status,
      results: results ?? this.results,
      assessmentConfig: assessmentConfig ?? this.assessmentConfig,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      playerName: playerName ?? this.playerName,
      teamName: teamName ?? this.teamName,
      shotCount: shotCount ?? this.shotCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShotAssessment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ShotAssessment{id: $id, title: $title, status: $status, date: $date}';
  }
}