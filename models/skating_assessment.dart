// lib/models/skating_assessment.dart
import 'package:flutter/material.dart';

class SkatingAssessment {
  final String id;
  final int playerId;
  final String title;
  final String? description;
  final String assessmentType;
  final String position;
  final String ageGroup;
  final int totalTests;
  final int completedTests;
  final double overallScore;
  final String? performanceLevel;
  final String status;
  final DateTime startedAt;
  final DateTime completedAt;
  final int? durationMinutes;
  final String? notes;
  final List<String> strengths;
  final List<String> improvements;
  // FIXED: Use assessmentData to match backend (not assessmentMetadata)
  final Map<String, dynamic>? assessmentData;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;

  // Derived properties
  final String? playerName;
  final String? teamName;

  SkatingAssessment({
    required this.id,
    required this.playerId,
    required this.title,
    this.description,
    required this.assessmentType,
    required this.position,
    required this.ageGroup,
    required this.totalTests,
    required this.completedTests,
    required this.overallScore,
    this.performanceLevel,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    this.durationMinutes,
    this.notes,
    required this.strengths,
    required this.improvements,
    this.assessmentData,  // FIXED: Correct field name
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.playerName,
    this.teamName,
  });

  factory SkatingAssessment.fromJson(Map<String, dynamic> json) {
    return SkatingAssessment(
      id: json['id']?.toString() ?? '',
      playerId: int.tryParse(json['player_id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? 'Skating Assessment',
      description: json['description']?.toString(),
      assessmentType: json['assessment_type']?.toString() ?? 'comprehensive',
      position: json['position']?.toString() ?? 'forward',
      ageGroup: json['age_group']?.toString() ?? 'youth_15_18',
      totalTests: int.tryParse(json['total_tests']?.toString() ?? '0') ?? 0,
      completedTests: int.tryParse(json['completed_tests']?.toString() ?? '0') ?? 0,
      overallScore: (json['overall_score'] as num?)?.toDouble() ?? 0.0,
      performanceLevel: json['performance_level']?.toString(),
      status: json['status']?.toString() ?? 'completed',
      startedAt: DateTime.parse(json['started_at'] ?? DateTime.now().toIso8601String()),
      completedAt: DateTime.parse(json['completed_at'] ?? DateTime.now().toIso8601String()),
      durationMinutes: json['duration_minutes'] != null ? int.tryParse(json['duration_minutes'].toString()) : null,
      notes: json['notes']?.toString(),
      strengths: _parseStringList(json['strengths']),
      improvements: _parseStringList(json['improvements']),
      // FIXED: Use correct field name to match backend
      assessmentData: json['assessment_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      createdBy: json['created_by'] != null ? int.tryParse(json['created_by'].toString()) : null,
      playerName: json['player_name']?.toString(),
      teamName: json['team_name']?.toString(),
    );
  }

  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) => item.toString()).toList();
    }
    if (data is String) {
      try {
        // Handle JSON string format
        final decoded = data.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
        if (decoded.isEmpty) return [];
        return decoded.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
      } catch (e) {
        return [data];
      }
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'player_id': playerId,
        'title': title,
        'description': description,
        'assessment_type': assessmentType,
        'position': position,
        'age_group': ageGroup,
        'total_tests': totalTests,
        'completed_tests': completedTests,
        'overall_score': overallScore,
        'performance_level': performanceLevel,
        'status': status,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt.toIso8601String(),
        'duration_minutes': durationMinutes,
        'notes': notes,
        'strengths': strengths,
        'improvements': improvements,
        'assessment_data': assessmentData,  // FIXED: Correct field name
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'created_by': createdBy,
        'player_name': playerName,
        'team_name': teamName,
      };

  // Helper methods
  bool get isCompleted => status == 'completed';
  bool get isInProgress => status == 'in_progress';
  bool get isCancelled => status == 'cancelled';

  // Get test completion percentage
  double get completionPercentage {
    if (totalTests == 0) return 0.0;
    return (completedTests / totalTests) * 100;
  }

  // Get assessment duration in formatted string
  String get formattedDuration {
    if (durationMinutes == null) return 'Unknown';
    if (durationMinutes! < 60) {
      return '${durationMinutes!} min';
    } else {
      final hours = durationMinutes! ~/ 60;
      final minutes = durationMinutes! % 60;
      return '${hours}h ${minutes}m';
    }
  }

  // Get performance level color
  Color get performanceColor {
    switch (performanceLevel?.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'very good':
        return Colors.lightGreen;
      case 'good':
        return Colors.blue;
      case 'average':
        return Colors.orange;
      case 'below average':
        return Colors.deepOrange;
      case 'needs improvement':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Get status display name
  String get statusDisplayName {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  // Get position display name
  String get positionDisplayName {
    switch (position.toLowerCase()) {
      case 'forward':
        return 'Forward';
      case 'defenseman':
        return 'Defenseman';
      case 'goalie':
        return 'Goalie';
      default:
        return position.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  // Get age group display name
  String get ageGroupDisplayName {
    switch (ageGroup.toLowerCase()) {
      case 'youth_8_10':
        return '8-10 Years';
      case 'youth_11_14':
        return '11-14 Years';
      case 'youth_15_18':
        return '15-18 Years';
      case 'adult':
        return 'Adult';
      default:
        return ageGroup.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  // Get assessment type display name
  String get assessmentTypeDisplayName {
    switch (assessmentType.toLowerCase()) {
      case 'comprehensive':
        return 'Comprehensive';
      case 'quick':
        return 'Quick';
      case 'speed_focus':
        return 'Speed Focus';
      case 'agility_focus':
        return 'Agility Focus';
      default:
        return assessmentType.split('_').map((word) => 
            word[0].toUpperCase() + word.substring(1)).join(' ');
    }
  }

  // Get formatted date string
  String get formattedDate {
    return '${completedAt.month}/${completedAt.day}/${completedAt.year}';
  }

  // Get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(completedAt);
    
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

  // Get test scores from assessment data
  Map<String, double> get testScores {
    if (assessmentData == null || assessmentData!['scores'] == null) return {};
    final scoresData = assessmentData!['scores'];
    if (scoresData is Map<String, dynamic>) {
      return scoresData.map((key, value) {
        final doubleValue = value is num ? value.toDouble() : 0.0;
        return MapEntry(key, doubleValue);
      });
    }
    return {};
  }

  // Get test times from assessment data
  Map<String, double> get testTimes {
    if (assessmentData == null || assessmentData!['test_times'] == null) return {};
    final timesData = assessmentData!['test_times'];
    if (timesData is Map<String, dynamic>) {
      return timesData.map((key, value) {
        final doubleValue = value is num ? value.toDouble() : 0.0;
        return MapEntry(key, doubleValue);
      });
    }
    return {};
  }

  // Get analysis results from assessment data
  Map<String, dynamic> get analysisResults {
    if (assessmentData == null || assessmentData!['analysis_results'] == null) return {};
    final analysisData = assessmentData!['analysis_results'];
    if (analysisData is Map<String, dynamic>) {
      return analysisData;
    }
    return {};
  }

  // Get assessment config from assessment data
  Map<String, dynamic> get assessmentConfig {
    if (assessmentData == null || assessmentData!['assessment_config'] == null) return {};
    final configData = assessmentData!['assessment_config'];
    if (configData is Map<String, dynamic>) {
      return configData;
    }
    return {};
  }

  // Check if has performance data
  bool get hasPerformanceData {
    return testScores.isNotEmpty || testTimes.isNotEmpty;
  }

  // Get strongest areas (top 2 test scores)
  List<String> get strongestAreas {
    if (testScores.isEmpty) return [];
    final sortedScores = testScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedScores.take(2).map((entry) => entry.key).toList();
  }

  // Get weakest areas (bottom 2 test scores)
  List<String> get weakestAreas {
    if (testScores.isEmpty) return [];
    final sortedScores = testScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sortedScores.take(2).map((entry) => entry.key).toList();
  }

  // Copy with method for updates
  SkatingAssessment copyWith({
    String? id,
    int? playerId,
    String? title,
    String? description,
    String? assessmentType,
    String? position,
    String? ageGroup,
    int? totalTests,
    int? completedTests,
    double? overallScore,
    String? performanceLevel,
    String? status,
    DateTime? startedAt,
    DateTime? completedAt,
    int? durationMinutes,
    String? notes,
    List<String>? strengths,
    List<String>? improvements,
    Map<String, dynamic>? assessmentData,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    String? playerName,
    String? teamName,
  }) {
    return SkatingAssessment(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      title: title ?? this.title,
      description: description ?? this.description,
      assessmentType: assessmentType ?? this.assessmentType,
      position: position ?? this.position,
      ageGroup: ageGroup ?? this.ageGroup,
      totalTests: totalTests ?? this.totalTests,
      completedTests: completedTests ?? this.completedTests,
      overallScore: overallScore ?? this.overallScore,
      performanceLevel: performanceLevel ?? this.performanceLevel,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      notes: notes ?? this.notes,
      strengths: strengths ?? this.strengths,
      improvements: improvements ?? this.improvements,
      assessmentData: assessmentData ?? this.assessmentData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      playerName: playerName ?? this.playerName,
      teamName: teamName ?? this.teamName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SkatingAssessment && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SkatingAssessment{id: $id, title: $title, status: $status, completedAt: $completedAt}';
  }
}