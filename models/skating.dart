// lib/models/skating.dart - PHASE 2 UPDATE: Clean Session-based Model
import 'package:flutter/material.dart';

class Skating {
  final int id;
  final int? playerId;
  final String? playerName;
  final DateTime date;
  final String ageGroup;
  final String position;
  
  // Raw test data
  final Map<String, double?> testTimes;
  
  // Results (calculated by backend)
  final Map<String, double> scores;
  
  // Assessment vs Practice distinction
  final bool isAssessment;
  
  // Analysis results
  final String? performanceLevel;
  final List<String> strengths;
  final List<String> improvements;
  
  // Optional metadata
  final String? notes;
  final int? comparisonId;
  final String assessmentType;
  final String? title;
  final String? description;
  
  // Team-related fields
  final bool teamAssessment;
  final int? teamId;
  final String? teamName;
  
  // ✅ PHASE 2 CLEANED: Assessment reference - String only (consistent with Shot model)
  final String? assessmentId;  // Session/batch identifier (timestamp-based)
  
  // ✅ PHASE 2 NEW: Session-level fields
  final String? sessionTitle;
  final String? sessionDescription;
  final int totalTestsPlanned;
  final String sessionStatus;
  
  // Audit fields (optional)
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? createdBy;
  final String? createdByName;

  Skating({
    required this.id,
    this.playerId,
    this.playerName,
    required this.date,
    required this.ageGroup,
    required this.position,
    required this.testTimes,
    required this.scores,
    this.isAssessment = false,
    this.performanceLevel,
    this.strengths = const [],
    this.improvements = const [],
    this.notes,
    this.comparisonId,
    this.assessmentType = 'general',
    this.title,
    this.description,
    this.teamAssessment = false,
    this.teamId,
    this.teamName,
    this.assessmentId, // ✅ String only - no dual handling
    this.sessionTitle,
    this.sessionDescription,
    this.totalTestsPlanned = 0,
    this.sessionStatus = 'completed',
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.createdByName,
  });

  // ✅ PHASE 2 NEW: Session-level factory constructors
  factory Skating.createSessionPlaceholder({
    required String assessmentId,
    required int playerId,
    String? playerName,
    required String ageGroup,
    required String position,
    String? sessionTitle,
    String? sessionDescription,
    int totalTestsPlanned = 5,
    String assessmentType = 'comprehensive',
  }) {
    return Skating(
      id: 0, // Placeholder ID
      playerId: playerId,
      playerName: playerName,
      date: DateTime.now(),
      ageGroup: ageGroup,
      position: position,
      testTimes: const {},
      scores: const {},
      isAssessment: true,
      assessmentId: assessmentId,
      sessionTitle: sessionTitle ?? 'Skating Assessment Session',
      sessionDescription: sessionDescription ?? '',
      totalTestsPlanned: totalTestsPlanned,
      sessionStatus: 'in_progress',
      assessmentType: assessmentType,
      title: sessionTitle,
      description: sessionDescription,
    );
  }

  // Factory constructors for specific types
  factory Skating.assessment({
    required int id,
    int? playerId,
    String? playerName,
    required DateTime date,
    required String ageGroup,
    required String position,
    required Map<String, double?> testTimes,
    required Map<String, double> scores,
    String? performanceLevel,
    List<String> strengths = const [],
    List<String> improvements = const [],
    String? notes,
    int? comparisonId,
    String assessmentType = 'formal_assessment',
    String? title,
    String? description,
    bool teamAssessment = false,
    int? teamId,
    String? teamName,
    String? assessmentId,
    String? sessionTitle,
    String? sessionDescription,
    int totalTestsPlanned = 0,
    String sessionStatus = 'completed',
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    String? createdByName,
  }) {
    return Skating(
      id: id,
      playerId: playerId,
      playerName: playerName,
      date: date,
      ageGroup: ageGroup,
      position: position,
      testTimes: testTimes,
      scores: scores,
      isAssessment: true, // Always true for assessments
      performanceLevel: performanceLevel,
      strengths: strengths,
      improvements: improvements,
      notes: notes,
      comparisonId: comparisonId,
      assessmentType: assessmentType,
      title: title,
      description: description,
      teamAssessment: teamAssessment,
      teamId: teamId,
      teamName: teamName,
      assessmentId: assessmentId,
      sessionTitle: sessionTitle,
      sessionDescription: sessionDescription,
      totalTestsPlanned: totalTestsPlanned,
      sessionStatus: sessionStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      createdByName: createdByName,
    );
  }

  factory Skating.practiceSession({
    required int id,
    int? playerId,
    String? playerName,
    required DateTime date,
    required String ageGroup,
    required String position,
    required Map<String, double?> testTimes,
    required Map<String, double> scores,
    String? performanceLevel,
    List<String> strengths = const [],
    List<String> improvements = const [],
    String? notes,
    String assessmentType = 'practice_session',
    String? title,
    String? description,
    bool teamAssessment = false,
    int? teamId,
    String? teamName,
    String? assessmentId,
    String? sessionTitle,
    String? sessionDescription,
    int totalTestsPlanned = 0,
    String sessionStatus = 'completed',
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    String? createdByName,
  }) {
    return Skating(
      id: id,
      playerId: playerId,
      playerName: playerName,
      date: date,
      ageGroup: ageGroup,
      position: position,
      testTimes: testTimes,
      scores: scores,
      isAssessment: false, // Always false for practice sessions
      performanceLevel: performanceLevel,
      strengths: strengths,
      improvements: improvements,
      notes: notes,
      assessmentType: assessmentType,
      title: title,
      description: description,
      teamAssessment: teamAssessment,
      teamId: teamId,
      teamName: teamName,
      assessmentId: assessmentId,
      sessionTitle: sessionTitle,
      sessionDescription: sessionDescription,
      totalTestsPlanned: totalTestsPlanned,
      sessionStatus: sessionStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      createdByName: createdByName,
    );
  }

  // Create a copy with updated fields
  Skating copyWith({
    int? id,
    int? playerId,
    String? playerName,
    DateTime? date,
    String? ageGroup,
    String? position,
    Map<String, double?>? testTimes,
    Map<String, double>? scores,
    bool? isAssessment,
    String? performanceLevel,
    List<String>? strengths,
    List<String>? improvements,
    String? notes,
    int? comparisonId,
    String? assessmentType,
    String? title,
    String? description,
    bool? teamAssessment,
    int? teamId,
    String? teamName,
    String? assessmentId,
    String? sessionTitle,
    String? sessionDescription,
    int? totalTestsPlanned,
    String? sessionStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? createdBy,
    String? createdByName,
  }) {
    return Skating(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      date: date ?? this.date,
      ageGroup: ageGroup ?? this.ageGroup,
      position: position ?? this.position,
      testTimes: testTimes ?? this.testTimes,
      scores: scores ?? this.scores,
      isAssessment: isAssessment ?? this.isAssessment,
      performanceLevel: performanceLevel ?? this.performanceLevel,
      strengths: strengths ?? this.strengths,
      improvements: improvements ?? this.improvements,
      notes: notes ?? this.notes,
      comparisonId: comparisonId ?? this.comparisonId,
      assessmentType: assessmentType ?? this.assessmentType,
      title: title ?? this.title,
      description: description ?? this.description,
      teamAssessment: teamAssessment ?? this.teamAssessment,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      assessmentId: assessmentId ?? this.assessmentId,
      sessionTitle: sessionTitle ?? this.sessionTitle,
      sessionDescription: sessionDescription ?? this.sessionDescription,
      totalTestsPlanned: totalTestsPlanned ?? this.totalTestsPlanned,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      createdByName: createdByName ?? this.createdByName,
    );
  }

  // ✅ PHASE 2 UPDATED: Create from JSON with session fields
  factory Skating.fromJson(Map<String, dynamic> json) {
    return Skating(
      id: _parseIntRequired(json['id']),
      playerId: _parseIntSafely(json['player_id']),
      playerName: json['player_name'],
      date: _parseDateSafely(json['date']) ?? DateTime.now(),
      ageGroup: json['age_group'] ?? 'youth_15_18',
      position: json['position'] ?? 'forward',
      testTimes: json['test_times'] != null 
          ? Map<String, double?>.from(json['test_times'])
          : {},
      scores: json['scores'] != null 
          ? Map<String, double>.from(json['scores']) 
          : {},
      isAssessment: json['is_assessment'] ?? false,
      performanceLevel: json['performance_level'],
      strengths: json['strengths'] != null 
          ? List<String>.from(json['strengths']) 
          : [],
      improvements: json['improvements'] != null 
          ? List<String>.from(json['improvements']) 
          : [],
      notes: json['notes'],
      comparisonId: _parseIntSafely(json['comparison_id']),
      assessmentType: json['assessment_type'] ?? 'general',
      title: json['title'],
      description: json['description'],
      teamAssessment: json['team_assessment'] ?? false,
      teamId: _parseIntSafely(json['team_id']),
      teamName: json['team_name'],
      // ✅ CLEAN: Assessment ID is always String
      assessmentId: _parseStringAssessmentId(json['assessment_id']),
      // ✅ PHASE 2 NEW: Session fields
      sessionTitle: json['session_title'],
      sessionDescription: json['session_description'],
      totalTestsPlanned: _parseIntSafely(json['total_tests_planned']) ?? 0,
      sessionStatus: json['session_status'] ?? 'completed',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      createdBy: _parseIntSafely(json['created_by']),
      createdByName: json['created_by_name'],
    );
  }

  // Helper method to safely parse assessment_id as String
  static String? _parseStringAssessmentId(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  // Helper method to safely parse integers from various types
  static int? _parseIntSafely(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return null;
      }
    }
    if (value is double) return value.toInt();
    return null;
  }

  // For required int fields (like id), use this method
  static int _parseIntRequired(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return defaultValue;
      }
    }
    if (value is double) return value.toInt();
    return defaultValue;
  }

  // Helper method to safely parse dates
  static DateTime? _parseDateSafely(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ✅ PHASE 2 UPDATED: Convert to JSON with session fields
  Map<String, dynamic> toJson({bool includeAudit = false}) {
    final data = {
      'id': id,
      'player_id': playerId,
      'player_name': playerName,
      'date': date.toIso8601String(),
      'age_group': ageGroup,
      'position': position,
      'test_times': testTimes,
      'scores': scores,
      'is_assessment': isAssessment,
      'performance_level': performanceLevel,
      'strengths': strengths,
      'improvements': improvements,
      'notes': notes,
      'comparison_id': comparisonId,
      'assessment_type': assessmentType,
      'title': title,
      'description': description,
      'team_assessment': teamAssessment,
      'team_id': teamId,
      'team_name': teamName,
      'assessment_id': assessmentId, // ✅ String assessment_id
      // ✅ PHASE 2 NEW: Session fields
      'session_title': sessionTitle,
      'session_description': sessionDescription,
      'total_tests_planned': totalTestsPlanned,
      'session_status': sessionStatus,
    };

    if (includeAudit) {
      data.addAll({
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
        'created_by': createdBy,
        'created_by_name': createdByName,
      });
    }

    return data;
  }

  // ✅ PHASE 2 NEW: Session-level methods
  static List<Skating> getSessionTests(List<Skating> all, String assessmentId) {
    return all.where((skating) => skating.assessmentId == assessmentId).toList();
  }

  static bool isSessionComplete(List<Skating> sessionTests, int expectedTotal) {
    if (expectedTotal <= 0) return true;
    return sessionTests.length >= expectedTotal;
  }

  String? get shortSessionId {
    if (assessmentId == null || assessmentId!.length < 6) return assessmentId;
    return assessmentId!.substring(assessmentId!.length - 6);
  }

  // Helper methods for UI
  String get sessionTypeDisplay {
    return isAssessment ? "Assessment" : "Practice Session";
  }

  IconData get sessionTypeIcon {
    return isAssessment ? Icons.assessment : Icons.sports_hockey;
  }

  Color get sessionTypeColor {
    return isAssessment ? Colors.blue : Colors.green;
  }

  Color get performanceLevelColor {
    switch (performanceLevel?.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.blue;
      case 'average':
        return Colors.orange;
      case 'below average':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // ✅ PHASE 2 NEW: Session status helpers
  bool get isSessionInProgress => sessionStatus == 'in_progress';
  bool get isSessionCompleted => sessionStatus == 'completed';
  
  Color get sessionStatusColor {
    switch (sessionStatus.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String get formattedDate {
    return '${date.day}/${date.month}/${date.year}';
  }

  String get formattedDateTime {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  // Get test display name
  String getTestDisplayName(String testId) {
    final names = {
      'forward_speed_test': 'Forward Speed',
      'backward_speed_test': 'Backward Speed',
      'agility_test': 'Agility',
      'transitions_test': 'Transitions',
      'crossovers_test': 'Crossovers',
      'stop_start_test': 'Stop & Start',
    };
    return names[testId] ?? testId.replaceAll('_', ' ').split(' ').map((e) => 
        e.isEmpty ? e : e[0].toUpperCase() + e.substring(1)).join(' ');
  }

  // Get category display info
  IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'speed':
        return Icons.speed;
      case 'agility':
        return Icons.rotate_right;
      case 'technique':
        return Icons.sports_hockey;
      case 'power':
        return Icons.fitness_center;
      case 'endurance':
        return Icons.timer;
      default:
        return Icons.sports;
    }
  }

  // Check if this has comparison data
  bool get hasComparison => comparisonId != null;

  // Check if this is a team session
  bool get isTeamSession => teamAssessment && teamId != null;

  // Check if this is linked to an assessment template
  bool get hasAssessmentReference => assessmentId != null && assessmentId!.isNotEmpty;

  // Get session priority for sorting (assessments first)
  int get sortPriority => isAssessment ? 0 : 1;

  // Check if this belongs to the same session as another skating
  bool isSameSession(Skating other) {
    return assessmentId != null && 
           other.assessmentId != null && 
           assessmentId == other.assessmentId;
  }

  // Static helper methods for filtering lists
  static List<Skating> filterAssessments(List<Skating> skating) {
    return skating.where((s) => s.isAssessment).toList();
  }

  static List<Skating> filterPracticeSessions(List<Skating> skating) {
    return skating.where((s) => !s.isAssessment).toList();
  }

  static List<Skating> filterByPlayer(List<Skating> skating, int playerId) {
    return skating.where((s) => s.playerId == playerId).toList();
  }

  static List<Skating> filterByTeam(List<Skating> skating, int teamId) {
    return skating.where((s) => s.teamId == teamId && s.teamAssessment).toList();
  }

  // Filter by assessment session ID
  static List<Skating> filterByAssessment(List<Skating> skating, String assessmentId) {
    return skating.where((s) => s.assessmentId == assessmentId).toList();
  }

  // ✅ PHASE 2 NEW: Group skating assessments by session ID
  static Map<String, List<Skating>> groupByAssessmentSession(List<Skating> skating) {
    final Map<String, List<Skating>> grouped = {};
    
    for (final s in skating) {
      if (s.assessmentId != null && s.assessmentId!.isNotEmpty) {
        grouped.putIfAbsent(s.assessmentId!, () => []);
        grouped[s.assessmentId!]!.add(s);
      }
    }
    
    return grouped;
  }

  // Get all unique assessment session IDs from a list
  static List<String> getUniqueAssessmentIds(List<Skating> skating) {
    final Set<String> ids = {};
    
    for (final s in skating) {
      if (s.assessmentId != null && s.assessmentId!.isNotEmpty) {
        ids.add(s.assessmentId!);
      }
    }
    
    return ids.toList()..sort((a, b) => b.compareTo(a)); // Most recent first
  }

  // ✅ PHASE 2 NEW: Get session progress percentage
  double getSessionProgress() {
    if (totalTestsPlanned <= 0) return 100.0;
    // This would need to be calculated based on actual session data
    // For now, return 100% if completed, 50% if in progress
    return isSessionCompleted ? 100.0 : 50.0;
  }

  // ✅ PHASE 2 NEW: Check if this test belongs to a specific session
  bool belongsToSession(String sessionId) {
    return assessmentId == sessionId;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Skating && 
      runtimeType == other.runtimeType && 
      id == other.id &&
      assessmentId == other.assessmentId;

  @override
  int get hashCode => id.hashCode ^ (assessmentId?.hashCode ?? 0);

  @override
  String toString() {
    return 'Skating{id: $id, playerId: $playerId, assessmentId: $assessmentId, sessionStatus: $sessionStatus, isAssessment: $isAssessment}';
  }
}

// ✅ PHASE 2 NEW: Session summary model for API responses
class SkatingSession {
  final String assessmentId;
  final int playerId;
  final String? playerName;
  final String? sessionTitle;
  final String? sessionDescription;
  final int totalTestsPlanned;
  final int completedTests;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final List<Skating> tests;
  final Map<String, dynamic>? analytics;

  SkatingSession({
    required this.assessmentId,
    required this.playerId,
    this.playerName,
    this.sessionTitle,
    this.sessionDescription,
    required this.totalTestsPlanned,
    required this.completedTests,
    required this.status,
    this.startedAt,
    this.completedAt,
    required this.tests,
    this.analytics,
  });

  factory SkatingSession.fromJson(Map<String, dynamic> json) {
    return SkatingSession(
      assessmentId: json['assessment_id'] ?? '',
      playerId: json['player_id'] ?? 0,
      playerName: json['player_name'],
      sessionTitle: json['session_title'],
      sessionDescription: json['session_description'],
      totalTestsPlanned: json['total_tests_planned'] ?? 0,
      completedTests: json['completed_tests'] ?? 0,
      status: json['status'] ?? 'completed',
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      tests: json['tests'] != null 
          ? (json['tests'] as List).map((test) => Skating.fromJson(test)).toList()
          : [],
      analytics: json['analytics'],
    );
  }

  bool get isComplete => completedTests >= totalTestsPlanned;
  bool get isInProgress => status == 'in_progress';
  
  double get progressPercentage {
    if (totalTestsPlanned <= 0) return 100.0;
    return (completedTests / totalTestsPlanned * 100).clamp(0.0, 100.0);
  }
}

// Enum for session types (optional, for type safety)
enum SkatingSessionType {
  assessment,
  practiceSession;

  String get displayName {
    switch (this) {
      case SkatingSessionType.assessment:
        return 'Assessment';
      case SkatingSessionType.practiceSession:
        return 'Practice Session';
    }
  }

  IconData get icon {
    switch (this) {
      case SkatingSessionType.assessment:
        return Icons.assessment;
      case SkatingSessionType.practiceSession:
        return Icons.sports_hockey;
    }
  }

  Color get color {
    switch (this) {
      case SkatingSessionType.assessment:
        return Colors.blue;
      case SkatingSessionType.practiceSession:
        return Colors.green;
    }
  }
}